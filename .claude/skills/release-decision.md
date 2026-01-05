---
name: release-decision
description: Final gate - decide on rollout strategy (immediate/canary/feature-flag) with rollback plan
tags: [guardian, release, dora-df]
owner: claude
dora_impact:
  deployment_frequency: increase
  recovery_time: decrease
  rationale: Safe frequent releases via canary/feature flags; fast rollback reduces downtime
confidence: high
---

# RELEASE_DECISION

## Purpose
Final orchestration decision: approve release with appropriate rollout strategy and rollback plan. Balances speed (deploy frequently) with safety (minimize impact of failures).

## Prerequisites (Hard Requirements)
- [ ] QA_GATE passed
- [ ] SECURITY_GATE passed
- [ ] All tests passing
- [ ] Branch is ahead of main (has actual changes)

**If any prerequisite fails → ABORT release**

## Input
- `out/qa-report-*.md` (must show PASS)
- `out/security-report-*.md` (must show PASS or CONDITIONAL)
- Change risk assessment (manual or automated)

## Output
Creates `out/release-decision-YYYYMMDD-HHMMSS.md`:

```markdown
# Release Decision

**Timestamp**: 2026-01-05T12:00:00Z
**Branch**: fix/auth-timeout-20260105
**Commit**: abc123def456
**Decision**: ✅ APPROVED FOR RELEASE

---

## CHANGE SUMMARY

### Files Modified
- `auth/redis_pool.py` (1 line)

### Risk Level: **LOW**
**Rationale**:
- Configuration change only (no logic changes)
- All tests passing (57/57)
- No security vulnerabilities
- Easy rollback (1-line revert)

### Blast Radius: **SMALL**
**Affected systems**:
- Auth service (Redis connection pool)

**NOT affected**:
- Database
- Frontend
- API contracts
- User data

---

## ROLLOUT STRATEGY

### Selected Strategy: **IMMEDIATE RELEASE**
**Rationale**: Low risk + small blast radius + all gates passed → safe for immediate deployment

### Alternative Strategies Considered

#### Canary Release
- **When to use**: Medium-risk changes; affects >1000 users
- **Not needed here**: Risk too low to justify complexity

#### Feature Flag
- **When to use**: High-risk changes; experimental features
- **Not needed here**: Configuration change, not a feature

#### Blue-Green Deployment
- **When to use**: Database migrations; zero-downtime requirements
- **Not needed here**: No schema changes

---

## DEPLOYMENT PLAN

### Step 1: Merge to Main
```bash
git checkout main
git merge fix/auth-timeout-20260105
git push origin main
```

### Step 2: Deploy to Staging
```bash
# Deploy to staging environment
./deploy.sh staging

# Run smoke tests
curl -f https://staging.example.com/health || exit 1
```

### Step 3: Monitor Staging (15 min)
- [ ] Check Redis connection metrics
- [ ] Check auth endpoint latency
- [ ] Check error rate

### Step 4: Deploy to Production
```bash
# If staging stable → deploy to prod
./deploy.sh production
```

### Step 5: Monitor Production (1 hour)
- [ ] Check Redis blocked_clients metric (should be 0)
- [ ] Check auth success rate (should be >99.5%)
- [ ] Check error logs (should be no new errors)

---

## ROLLBACK PLAN

### Trigger Conditions (Auto-Rollback)
- Auth success rate drops below 99%
- Redis connection errors increase >10%
- Error rate spikes >5%

### Rollback Method: **GIT REVERT**
```bash
# Option 1: Revert commit
git revert abc123def456
git push origin main
./deploy.sh production

# Option 2: Redeploy previous version
git checkout main~1
./deploy.sh production
```

**Estimated rollback time**: <5 minutes

### Rollback Verification
```bash
# After rollback
pytest tests/test_auth_redis.py -v
curl -f https://production.example.com/health
# Check metrics dashboard for 10 minutes
```

---

## MONITORING & ALERTS

### Key Metrics to Watch
1. **Redis Pool Usage**
   - Metric: `redis.pool.active_connections`
   - Alert if: >45 (90% of pool size)

2. **Auth Endpoint Latency**
   - Metric: `http.server.duration{endpoint="/api/auth/login"}`
   - Alert if: p99 >500ms

3. **Auth Success Rate**
   - Metric: `auth.login.success_rate`
   - Alert if: <99%

### Alert Configuration
```yaml
# Example alert (Prometheus)
- alert: RedisPoolExhaustion
  expr: redis_pool_active_connections > 45
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Redis pool nearing exhaustion"
    action: "Consider increasing pool size further"
```

---

## COMMUNICATION PLAN

### Internal Notification
- [ ] Post to #engineering Slack: "Deploying auth pool size fix to prod at 12:15 PM"
- [ ] Notify on-call engineer

### User-Facing Communication
- [ ] N/A (internal change, no user impact expected)

### Post-Deployment
- [ ] Post to #engineering: "Auth pool fix deployed successfully. Monitoring for 1 hour."
- [ ] Update NOTES.md with deployment notes

---

## CONTINGENCY PLANS

### If Rollback Fails
1. Kill auth service pods (Kubernetes will restart with previous image)
2. Disable auth service in load balancer (emergency mode)
3. Page SRE on-call

### If Issue Discovered After 24 Hours
1. Create new hotfix branch
2. Fast-track through gates (QA + Security)
3. Deploy via same rollout strategy

---

## SIGN-OFF

**Approved by**: Claude (Release Manager)
**Deployment window**: 2026-01-05 12:00-12:30 UTC
**On-call engineer**: [Auto-assigned from PagerDuty]

**Confidence**: HIGH
**Recommendation**: ✅ PROCEED WITH DEPLOYMENT
```

## Risk Assessment Matrix

| Risk Level | Criteria | Rollout Strategy |
|------------|----------|------------------|
| **LOW** | <5 files, config only, all tests pass | Immediate release |
| **MEDIUM** | 5-20 files, logic changes, affects <10k users | Canary release (5% → 50% → 100%) |
| **HIGH** | >20 files, new features, affects >10k users | Feature flag + gradual rollout |
| **CRITICAL** | Auth/payment/data migration | Blue-green + human supervision |

## Rollout Strategies Explained

### Immediate Release
- **When**: Low risk, small changes
- **How**: Deploy to all servers at once
- **Pros**: Fast, simple
- **Cons**: All users affected if issue

### Canary Release
- **When**: Medium risk, gradual validation needed
- **How**: Deploy to 5% of servers → monitor → 50% → 100%
- **Pros**: Limits blast radius
- **Cons**: Slower rollout

### Feature Flag
- **When**: Experimental features, A/B testing
- **How**: Deploy code but disable feature; enable for subset of users
- **Pros**: Instant rollback (flip flag), no redeploy
- **Cons**: Code complexity, flag cleanup needed

### Blue-Green
- **When**: Zero-downtime required, database migrations
- **How**: Deploy to "green" environment → test → switch traffic → keep "blue" for rollback
- **Pros**: Zero downtime, instant rollback
- **Cons**: 2x infrastructure cost

## Gates (Must Pass)
- [ ] QA_GATE and SECURITY_GATE both passed
- [ ] Risk level assessed (LOW/MEDIUM/HIGH/CRITICAL)
- [ ] Rollout strategy selected and justified
- [ ] Rollback plan is concrete (not vague)
- [ ] Monitoring metrics defined

## Usage
```bash
# After both QA_GATE and SECURITY_GATE pass
/release-decision

# Claude generates release plan
# Human reviews and approves deployment
```

## DORA Justification
- **Deployment Frequency ↑**: Low-risk changes can deploy multiple times per day
- **Change Failure Rate ↓**: Canary/feature flags limit blast radius
- **Recovery Time ↓**: Clear rollback plan enables <5min recovery
- **Lead Time ↓**: Automated gates reduce manual approval time
- **Confidence**: HIGH (backed by Accelerate research on elite performers)

## Integration with Other Skills
1. **After QA_GATE + SECURITY_GATE pass** → invoke RELEASE_DECISION
2. **After RELEASE_DECISION approves** → execute deployment (manual or CI/CD)
3. **After deployment** → invoke LEDGER_UPDATE with deployment notes
4. **If deployment fails** → follow rollback plan; update NOTES.md

## Model-Specific Notes
- **Claude**: You own this skill; balance speed vs safety
- **Codex**: Not involved (deployment orchestration is Claude's domain)
- **Gemini**: Not involved

## Tool Requirements
- **MCP**: None (decision-making only; deployment is external)
- **Read access**: QA/Security reports
- **Write access**: `out/release-decision-*.md`

## Failure Modes & Recovery
| Failure | Symptom | Recovery |
|---------|---------|----------|
| Prerequisites not met | QA/Security gate failed | Abort; fix blockers first |
| Risk level unclear | Can't classify as LOW/MEDIUM/HIGH | Escalate to human for risk assessment |
| No rollback plan possible | E.g., irreversible data migration | Abort; require human supervision |
| Deployment fails | Smoke tests fail after deploy | Execute rollback plan immediately |

## Example: Canary Release (Medium Risk)
```markdown
# Release Decision

**Risk Level**: MEDIUM
**Rationale**: Logic change in auth flow; affects all users

## ROLLOUT STRATEGY: CANARY RELEASE

### Phase 1: 5% Traffic (30 min)
- Deploy to 5% of servers
- Monitor: auth success rate, latency, error rate
- **Proceed to Phase 2 if**: All metrics stable

### Phase 2: 50% Traffic (1 hour)
- Deploy to 50% of servers
- Monitor same metrics
- **Proceed to Phase 3 if**: No issues detected

### Phase 3: 100% Traffic
- Deploy to all servers
- Continue monitoring for 24 hours

### Auto-Rollback Triggers
- Auth success rate <99%
- Error rate >1%
- Latency p99 >500ms
```

## Update Ledger After Execution
```json
{
  "skill": "release-decision",
  "timestamp": "2026-01-05T12:00:00Z",
  "input": "QA + Security reports",
  "output": "out/release-decision-20260105-120000.md",
  "decision": "APPROVED",
  "risk_level": "LOW",
  "rollout_strategy": "immediate",
  "deployment_time": "2026-01-05T12:15:00Z",
  "next_skill": "ledger-update"
}
```

## References
- DORA Metrics: Deployment Frequency, Recovery Time
- Google SRE Book: Gradual Rollouts and Monitoring
- Feature Flags: https://launchdarkly.com/blog/what-are-feature-flags/
