---
name: security-gate
description: Skeptical security review - threat modeling, vulnerability scan, P0 blocks merge
tags: [guardian, security, dora-cfr]
owner: codex
dora_impact:
  change_failure_rate: decrease
  recovery_time: decrease
  rationale: Prevent security incidents before production; reduce emergency response time
confidence: high
---

# SECURITY_GATE

## Purpose
Paranoid security review with **no benefit of doubt**. Treats every change as potentially hostile. Blocks merge on P0 vulnerabilities.

## Philosophy
> "Assume breach. Verify everything. Trust nothing."

This gate is intentionally conservative. False positives are acceptable; false negatives are catastrophic.

## Trigger Conditions
Invoke SECURITY_GATE after QA_GATE passes, especially for changes in:
- Authentication/authorization
- Database queries
- External API calls
- User input handling
- File uploads
- Cryptography
- Payment processing

## Input
- Current branch with changes
- QA_REPORT.md (must exist and pass)
- Threat model (simplified)

## Output
Creates `out/security-report-YYYYMMDD-HHMMSS.md`:

```markdown
# Security Gate Report

**Timestamp**: 2026-01-05T11:50:00Z
**Branch**: fix/auth-timeout-20260105
**Reviewer**: Codex (Security Guardian)
**Gate Result**: ✅ PASS | ❌ FAIL | ⚠️ CONDITIONAL

---

## THREAT MODEL (Simplified)

### Assets
- User credentials (username, password hash)
- Session tokens (JWT)
- User data (PII)

### Trust Boundaries
- Client → API (untrusted input)
- API → Database (trusted, but SQL injection risk)
- API → Redis (trusted)

### Adversary Goals
1. Steal user credentials
2. Hijack sessions
3. Escalate privileges

---

## FINDINGS

### P0 - Critical (MUST FIX BEFORE MERGE)
**None**

### P1 - High (SHOULD FIX BEFORE MERGE)
**None**

### P2 - Medium (FIX IN FOLLOW-UP)
**None**

### P3 - Low (INFORMATIONAL)

#### L1: Redis Connection Pool Size Increase
**File**: `auth/redis_pool.py:12`
**Change**: `pool_size=10` → `pool_size=50`
**Risk**: NEGLIGIBLE
**Rationale**: Larger pool = more connections to Redis. Redis has default max connections of 10,000, so 50 is safe. No authentication/authorization change.

---

## SECURITY CHECKLIST

### Authentication & Authorization
- [ ] N/A (no auth changes)

### Input Validation
- [ ] N/A (no user input changes)

### SQL Injection
- [ ] N/A (no database queries changed)

### XSS (Cross-Site Scripting)
- [ ] N/A (no HTML rendering changes)

### CSRF (Cross-Site Request Forgery)
- [ ] N/A (no state-changing endpoints added)

### Secrets Management
- [x] ✅ No hardcoded secrets detected
- [x] ✅ No credentials in logs

### Dependency Vulnerabilities
- [x] ✅ No new dependencies added
- [x] ✅ Existing dependencies scanned (0 vulnerabilities)

### Rate Limiting
- [ ] N/A (no new endpoints)

### Encryption
- [ ] N/A (no crypto changes)

---

## GATE DECISION

### ✅ PASS - No Security Blockers

**Rationale**:
- Change is minimal (1 line, configuration only)
- No code logic changes
- No new attack surface introduced
- No sensitive data exposure

**Approval**: Safe to merge from security perspective

---

## RECOMMENDED SECURITY IMPROVEMENTS (Optional)

1. **Add Redis connection timeout**: Prevents indefinite hangs
   - Priority: LOW
   - Effort: 5 minutes
   - File: `auth/redis_pool.py`

2. **Monitor Redis memory usage**: Alert if pool exhausts memory
   - Priority: LOW
   - Effort: 30 minutes (add monitoring)

---

## ROLLBACK SECURITY IMPACT
If this change is reverted:
- ✅ No security regression (rollback is safe)
- ✅ No credentials invalidated
- ✅ No user data loss

---

## NEXT STEPS
1. ✅ Proceed to RELEASE_DECISION
2. 📋 Schedule follow-up for optional improvements
```

## Severity Definitions

### P0 - Critical (BLOCKS MERGE)
- Remote code execution
- Authentication bypass
- SQL injection
- Privilege escalation
- Exposed secrets (API keys, passwords)
- PII data leak

### P1 - High (STRONG RECOMMENDATION TO FIX)
- Missing rate limiting on critical endpoints
- Weak password requirements
- Missing CSRF protection
- Insecure cookie settings
- Path traversal vulnerabilities

### P2 - Medium (FIX IN FOLLOW-UP)
- Missing input validation (low-risk fields)
- Weak error messages (info disclosure)
- Missing security headers
- Outdated dependencies (no known exploits)

### P3 - Low (INFORMATIONAL)
- Code smells (e.g., commented-out auth checks)
- Missing logging for security events
- Non-critical dependency updates

## Automated Scans (If Available)
```bash
# Run security scanners if available
bandit -r auth/  # Python security linter
safety check  # Check dependencies for known vulnerabilities
trivy fs .  # Container/filesystem vulnerability scanner
```

**If scanners unavailable → manual code review only**

## Gates (Must Pass)
- [ ] Threat model updated (if attack surface changed)
- [ ] All P0 findings resolved
- [ ] Security checklist completed (N/A is acceptable)
- [ ] Rollback security impact assessed

## Usage
```bash
# Automatic after QA_GATE passes
# OR manual:
/security-gate

# Generates security report and blocks merge if P0 found
```

## DORA Justification
- **Change Failure Rate ↓**: Prevent security incidents (which are high-severity failures)
- **Recovery Time ↓**: Fewer security incidents = less emergency patching
- **Confidence**: HIGH (security reviews reduce incident rate by 60-80%, per SANS research)

## Integration with Other Skills
1. **After QA_GATE passes** → invoke SECURITY_GATE (mandatory for sensitive code)
2. **If SECURITY_GATE fails (P0)** → invoke CODEX_DIAGNOSE_RO to fix vulnerability
3. **If SECURITY_GATE passes** → invoke RELEASE_DECISION
4. **After release** → update LEDGER with security notes

## Common Vulnerability Patterns

### Pattern 1: SQL Injection
```python
# ❌ VULNERABLE
query = f"SELECT * FROM users WHERE id = {user_id}"

# ✅ SAFE
query = "SELECT * FROM users WHERE id = %s"
cursor.execute(query, (user_id,))
```

### Pattern 2: Hardcoded Secrets
```python
# ❌ VULNERABLE
API_KEY = "sk-1234567890abcdef"

# ✅ SAFE
API_KEY = os.environ.get("API_KEY")
if not API_KEY:
    raise ValueError("API_KEY environment variable not set")
```

### Pattern 3: Missing Rate Limiting
```python
# ❌ VULNERABLE (brute force attack)
@app.route("/api/auth/login", methods=["POST"])
def login():
    # No rate limiting

# ✅ SAFE
from flask_limiter import Limiter
limiter = Limiter(app, default_limits=["100 per hour"])

@app.route("/api/auth/login", methods=["POST"])
@limiter.limit("5 per minute")
def login():
    # Rate limited
```

## Model-Specific Notes
- **Codex**: You execute this skill; be ruthlessly skeptical
- **Claude**: Review security report; approve/reject RELEASE_DECISION based on risk
- **Gemini**: Not involved (no security expertise)

## Tool Requirements
- **MCP**: `bash` (run security scanners if available)
- **Read access**: Repository files
- **Write access**: `out/security-report-*.md`

## Failure Modes & Recovery
| Failure | Symptom | Recovery |
|---------|---------|----------|
| P0 found | Critical vulnerability detected | Block merge; fix immediately; re-run gate |
| Scanner crashes | Bandit/Safety exit with error | Fall back to manual review |
| False positive | Scanner flags safe code | Manual override (document in report) |
| Threat model incomplete | Missing assets/boundaries | Escalate to human for threat modeling |

## Example: Failed Gate (P0)
```markdown
# Security Gate Report

**Gate Result**: ❌ FAIL

## FINDINGS

### P0 - Critical

#### C1: SQL Injection Vulnerability
**File**: `auth/queries.py:45`
**Code**:
```python
query = f"SELECT * FROM users WHERE username = '{username}'"
```
**Vulnerability**: User-controlled `username` is concatenated directly into SQL query
**Exploit**: `username = "admin' OR '1'='1"` bypasses authentication
**CVSS Score**: 9.8 (Critical)
**Action**: MUST FIX BEFORE MERGE

**Recommended Fix**:
```python
query = "SELECT * FROM users WHERE username = %s"
cursor.execute(query, (username,))
```

---

## GATE DECISION
❌ FAIL - Critical vulnerability must be resolved

## NEXT STEPS
1. ❌ DO NOT MERGE (P0 blocker)
2. Fix SQL injection (C1)
3. Re-run /security-gate
4. Only proceed after PASS
```

## Advanced: Threat Modeling Template
```markdown
### STRIDE Analysis
- **Spoofing**: Can attacker impersonate legitimate user?
- **Tampering**: Can attacker modify data in transit/rest?
- **Repudiation**: Can attacker deny actions?
- **Information Disclosure**: Can attacker access sensitive data?
- **Denial of Service**: Can attacker make service unavailable?
- **Elevation of Privilege**: Can attacker gain admin access?
```

## Update Ledger After Execution
```json
{
  "skill": "security-gate",
  "timestamp": "2026-01-05T11:50:00Z",
  "input": "Branch: fix/auth-timeout-20260105",
  "output": "out/security-report-20260105-115000.md",
  "gate_result": "PASS",
  "p0_findings": 0,
  "p1_findings": 0,
  "p2_findings": 0,
  "p3_findings": 1,
  "blockers": 0,
  "next_skill": "release-decision"
}
```

## References
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- STRIDE Threat Modeling: Microsoft Security Development Lifecycle
- CVSS Scoring: https://www.first.org/cvss/
