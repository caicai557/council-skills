# Council Skills: Complete Workflow Examples

## Overview

This document shows **end-to-end workflows** using Council skills, from task planning to deployment and knowledge capture.

---

## Workflow 1: Bug Fix (Complete Cycle)

### Scenario
User reports: "Auth endpoint timing out under load"

### Step-by-Step Execution

#### 1. Plan Task (Chair: Claude)
```bash
/plan-task-packet
```

**Output**: `progress/TASK_PACKET.md`
```markdown
# Task Packet: Fix Auth Timeout Under Load

## GOAL
Eliminate timeout errors on `/api/auth/login` under >50 concurrent requests

## IN-SCOPE
- Files: `auth/redis_pool.py`, `auth/middleware.py`, `tests/test_auth_redis.py`
- Modules: auth

## ACCEPTANCE CRITERIA
1. Load test (1000 requests, 50 concurrent) completes with 0 timeouts
2. All existing auth tests pass
3. No new security vulnerabilities

## VERIFICATION
```bash
pytest tests/test_auth_redis.py -v
python scripts/load_test_auth.py --requests 1000 --concurrent 50
```

## RISKS
1. **Increasing pool size uses more memory**: [M] → Monitor Redis memory
2. **Config change might break other services**: [L] → Only affects auth
```

---

#### 2. Route Work (Chair: Claude)
```bash
/route-work
```

**Output**: `progress/ROUTE_DECISION.md`
```markdown
# Route Decision

## SELECTED EXECUTOR: codex-ro

##REASONING
Bug diagnosis requires analyzing logs and code, but no writes needed yet. Start read-only to minimize risk.

## PERMISSION LEVEL
- Read: `auth/*.py`, `logs/auth.log`
- Write: NONE

## ESCALATION TRIGGERS
- If root cause requires >5 file changes → escalate to human
```

---

#### 3. Diagnose (Executor: Codex, Read-Only)
```bash
/codex-diagnose-ro
```

**Codex**:
1. Uses GEMINI_FILE_IO to read `auth/` module (5k tokens instead of 50k)
2. Analyzes logs
3. Identifies root cause

**Output**: `out/codex-diagnosis-20260105-105500.md`
```markdown
# Diagnosis Report

## ROOT CAUSE
Redis connection pool size hardcoded to 10; insufficient for 50 concurrent users.

**File**: `auth/redis_pool.py:12`
**Evidence**: Logs show `ConnectionPoolTimeout` at peak load

## MINIMAL FIX
Increase `pool_size=10` → `pool_size=50`

## PERMISSION REQUEST: REQUEST_RW
**Justification**: One-line config change; low risk
```

---

#### 4. Approve RW (Chair: Claude)
**Claude reviews diagnosis**:
- Root cause is clear ✅
- Fix is minimal (1 line) ✅
- Verification plan exists ✅

**Decision**: Approve RW for `auth/redis_pool.py` only

---

#### 5. Apply Patch (Executor: Codex, Read-Write)
```bash
/codex-patch-rw
```

**Codex**:
1. Applies one-line change
2. Runs verification commands
3. Creates git commit

**Output**: `out/codex-patch-20260105-111000.md`
```markdown
# Patch Report

## CHANGES APPLIED
**File**: `auth/redis_pool.py`
```diff
- pool_size=10
+ pool_size=50
```

## VERIFICATION RESULTS
✅ pytest tests/test_auth_redis.py -v (3/3 passed)
✅ Load test: 1000 requests, 0 timeouts

## GIT COMMIT
Branch: `fix/auth-timeout-20260105`
Commit: `abc123def456`
```

---

#### 6. QA Gate (Guardian: Codex or Claude)
```bash
/qa-gate
```

**Output**: `out/qa-report-20260105-112000.md`
```markdown
# QA Gate Report

## GATE RESULT: ✅ PASS

## VERIFICATION SUMMARY
- Unit Tests: ✅ 57/57 passed
- Integration Tests: ✅ 12/12 passed
- Linting: ✅ No issues
- Coverage: ⚠️ 88.5% (acceptable)

## BLOCKERS: None
```

---

#### 7. Security Gate (Guardian: Codex)
```bash
/security-gate
```

**Output**: `out/security-report-20260105-115000.md`
```markdown
# Security Gate Report

## GATE RESULT: ✅ PASS

## FINDINGS
### P0 (Critical): None
### P1 (High): None
### P2 (Medium): None
### P3 (Low): 1 finding

**L1**: Consider adding connection timeout
**Risk**: NEGLIGIBLE

## APPROVAL: Safe to merge
```

---

#### 8. Release Decision (Chair: Claude)
```bash
/release-decision
```

**Output**: `out/release-decision-20260105-120000.md`
```markdown
# Release Decision

## DECISION: ✅ APPROVED FOR IMMEDIATE RELEASE

## RISK LEVEL: LOW
- 1 line changed
- All tests passing
- Easy rollback

## ROLLOUT STRATEGY: Immediate
No canary needed (config change only)

## MONITORING
- Redis pool usage: alert if >45
- Auth success rate: alert if <99%

## ROLLBACK PLAN
```bash
git revert abc123def456
./deploy.sh production
```
```

---

#### 9. Deploy (Manual or CI/CD)
```bash
git checkout main
git merge fix/auth-timeout-20260105
./deploy.sh production
```

---

#### 10. Update Ledger (Secretary: Claude)
```bash
/ledger-update
```

**Outputs**:
- `progress/ledger.jsonl` (appended)
- `progress/NOTES.md` (appended)

```jsonl
{"timestamp": "2026-01-05T12:30:00Z", "task_id": "fix-auth-timeout", "status": "success", "root_cause": "Redis pool too small", "fix": "Increased pool 10→50", "lesson_learned": "Always load test connection pools", "dora_impact": {"lead_time": "45 minutes", "deployment_frequency": "+1", "change_failure_rate": "0%"}}
```

---

### Metrics for This Workflow

- **Lead Time**: 45 minutes (bug report → deployed)
- **Deployment Frequency**: +1 deploy
- **Change Failure Rate**: 0% (all gates passed)
- **Files Modified**: 1
- **Lines Changed**: 1
- **Cost**: ~$0.30 (using Gemini Flash for file I/O + Codex for logic)

---

## Workflow 2: New Feature (UI Design → Implementation)

### Scenario
User requests: "Add a dashboard with multiple layout options"

### Step-by-Step

#### 1. Plan Task
```bash
/plan-task-packet
```
**Output**: TASK_PACKET specifies "explore UI layouts before coding"

---

#### 2. Route to Gemini (Design Phase)
```bash
/route-work
```
**Decision**: Route to `gemini-json` (design exploration)

---

#### 3. Explore UI Options (Oracle: Gemini)
```bash
/gemini-ui-docs-json
```

**Gemini generates 3 options**:
- Option 1: Sidebar with cards (LOW complexity)
- Option 2: Top nav with tabs (MEDIUM complexity) ← Recommended
- Option 3: Draggable widgets (HIGH complexity)

**Output**: `out/gemini-design-20260105-113000.json`

---

#### 4. Human Reviews & Selects
**Human picks**: Option 2 (Top nav with tabs)

---

#### 5. Update Task Packet
**Claude updates TASK_PACKET** with selected option details

---

#### 6. Route to Codex (Implementation)
```bash
/route-work
```
**Decision**: `codex-rw` (implement selected design)

---

#### 7-10. Standard Flow
- CODEX_PATCH_RW implements design
- QA_GATE verifies
- SECURITY_GATE audits
- RELEASE_DECISION approves
- LEDGER_UPDATE records

---

### Key Difference from Workflow 1
- **Design-first**: Gemini explores options → Human decides → Codex implements
- **No rework**: Design validated before coding
- **DORA Impact**: ↓ Lead Time (no "build wrong thing" cycles)

---

## Workflow 3: High-Risk Change (Requires Canary)

### Scenario
"Migrate auth from JWT to OAuth2"

### Differences from Standard Flow

#### Route Decision
```markdown
## RISK LEVEL: HIGH
- Changes auth logic (affects all users)
- New dependency (OAuth2 library)
- Requires database migration

## ROLLOUT STRATEGY: Canary Release
- Phase 1: 5% traffic (30 min)
- Phase 2: 50% traffic (1 hour)
- Phase 3: 100% traffic

## HUMAN APPROVAL REQUIRED
This change is too risky for autonomous execution.
```

#### Release Decision
```markdown
## DECISION: ⚠️ APPROVED WITH CONDITIONS

### Conditions
1. Human must review OAuth2 library selection
2. Human must approve database migration script
3. Canary rollout with human monitoring each phase
4. Rollback plan tested in staging

### Auto-Rollback Triggers
- Auth success rate <99%
- Error rate >1%
- Any P0 security finding
```

---

## Workflow 4: Incident Response (Fast Recovery)

### Scenario
Production alert: "Auth endpoint down"

### Fast-Track Process

#### 1. Immediate Diagnosis (Skip PLAN_TASK_PACKET)
```bash
/codex-diagnose-ro --fast-track
```

**Codex**:
- Reads CODEMAP (5k tokens, not full repo)
- Queries ledger: "Have we seen auth issues before?"
- Finds: "2 weeks ago, Redis pool issue"

**Output**: "Likely same issue; Redis pool exhausted again"

---

#### 2. Quick Fix (Emergency Rollback)
```bash
# Option 1: Rollback recent change
git revert HEAD
./deploy.sh production

# Option 2: Scale Redis pool
# (if rollback doesn't help)
```

---

#### 3. Post-Incident Review
```bash
/ledger-update --type incident
```

**Output**:
```jsonl
{"type": "incident", "severity": "P1", "duration_minutes": 23, "root_cause": "Redis pool sizing still insufficient", "fix": "Increased to 100; added memory alerts", "lesson_learned": "Monitor Redis memory usage, not just connections", "dora_impact": {"recovery_time": "23 minutes"}}
```

---

### Metrics
- **Recovery Time**: 23 minutes (alert → service restored)
- **DORA Impact**: ↓ RTS (Recovery Time from Service failure)

---

## Summary: Skill Invocation Patterns

| Workflow Type | Skills Used | Duration | Risk |
|---------------|-------------|----------|------|
| **Bug Fix** | PLAN → ROUTE → DIAGNOSE_RO → PATCH_RW → QA → SEC → RELEASE → LEDGER | 30-60 min | LOW |
| **New Feature** | PLAN → ROUTE → GEMINI_UI → [human review] → PATCH_RW → QA → SEC → RELEASE → LEDGER | 2-4 hours | MEDIUM |
| **High-Risk Change** | [All skills] + CONSENSUS_STOP + Human approvals | 1-2 days | HIGH |
| **Incident Response** | DIAGNOSE_RO → [rollback] → LEDGER | 15-30 min | CRITICAL |

---

## Cost Optimization Patterns

### Pattern 1: Use Gemini Flash for File I/O
**Before**: Codex reads 50 files = 50k tokens × $0.015/1k = **$0.75**
**After**: Gemini Flash reads 50 files = 50k tokens × $0.000075/1k = **$0.004**

**Savings**: 99.5% for file reading

### Pattern 2: Use CODEMAP Instead of Full Repo
**Before**: Send entire repo to Codex = 200k tokens
**After**: Send CODEMAP = 5k tokens

**Savings**: 97.5% context reduction

### Pattern 3: Consensus Stop (Avoid Infinite Debate)
**Without limit**: 10 rounds of agent debate = 500k tokens
**With CONSENSUS_STOP**: Max 3 rounds = 150k tokens

**Savings**: 70% by forcing decisions

---

## Next Steps

1. **Try Workflow 1** (bug fix) with a real issue in your codebase
2. **Customize TASK_PACKET** templates for your domain
3. **Add project-specific verification commands** to skills
4. **Monitor DORA metrics** via ledger queries
5. **Iterate on skills** based on lessons learned

---

## References

- Skills directory: `.claude/skills/`
- Constitution: `CONSTITUTION.md`
- MCP guide: `docs/MCP_MANAGEMENT.md`
- Ledger: `progress/ledger.jsonl`
