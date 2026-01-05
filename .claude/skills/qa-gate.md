---
name: qa-gate
description: Mandatory quality gate - tests, linting, build verification before merge
tags: [guardian, quality, dora-cfr]
owner: codex-or-claude
dora_impact:
  change_failure_rate: decrease
  recovery_time: decrease
  rationale: Catch failures before production; reduce incident response time
confidence: high
---

# QA_GATE

## Purpose
Hard quality gate that blocks merges until all verification passes. No exceptions. Implements shift-left testing to catch issues before production.

## Trigger Conditions
Invoke QA_GATE after:
- Any CODEX_PATCH_RW completion
- Manual user request (/qa-gate)
- Before RELEASE_DECISION
- As part of CI/CD pipeline

## Input
- Current branch with changes
- TASK_PACKET.md (for verification commands)
- Repository test suite

## Output
Creates `out/qa-report-YYYYMMDD-HHMMSS.md`:

```markdown
# QA Gate Report

**Timestamp**: 2026-01-05T11:20:00Z
**Branch**: fix/auth-timeout-20260105
**Commit**: abc123def456
**Gate Result**: ✅ PASS | ❌ FAIL

---

## VERIFICATION SUMMARY

| Check | Status | Duration | Details |
|-------|--------|----------|---------|
| Unit Tests | ✅ PASS | 2.3s | 45/45 passed |
| Integration Tests | ✅ PASS | 8.1s | 12/12 passed |
| Linting (flake8) | ✅ PASS | 0.5s | 0 issues |
| Type Checking (mypy) | ✅ PASS | 1.2s | 0 errors |
| Build | ✅ PASS | 3.4s | Clean build |
| Coverage | ⚠️ WARN | - | 88.5% (target: 90%) |

**Overall**: ✅ PASS (1 warning acceptable)

---

## DETAILED RESULTS

### 1. Unit Tests
```bash
$ pytest tests/ -v --tb=short
```
**Output**:
```
tests/test_auth.py::test_login ... PASSED
tests/test_auth.py::test_logout ... PASSED
tests/test_auth_redis.py::test_connection_pool ... PASSED
...
==================== 45 passed in 2.3s ====================
```

### 2. Integration Tests
```bash
$ pytest tests/integration/ -v
```
**Output**:
```
tests/integration/test_auth_flow.py::test_full_login_flow ... PASSED
...
==================== 12 passed in 8.1s ====================
```

### 3. Linting
```bash
$ flake8 auth/ tests/
```
**Output**: (no output = success)

### 4. Type Checking
```bash
$ mypy auth/ --strict
```
**Output**: Success: no issues found in 8 source files

### 5. Build
```bash
$ python -m build
```
**Output**: Successfully built auth-1.0.0.tar.gz

### 6. Coverage
```bash
$ pytest --cov=auth --cov-report=term-missing
```
**Output**:
```
auth/middleware.py    95%   (missing: 78-80)
auth/redis_pool.py    100%
auth/jwt.py           82%   (missing: 45-50, 67)
------------------------------------------
TOTAL                 88.5%
```
⚠️ **Warning**: Below 90% target but acceptable for non-critical code

---

## GATE DECISION

### ✅ PASS - All Critical Checks Passed

**Rationale**:
- All tests pass (57/57)
- No linting or type errors
- Build succeeds
- Coverage warning is for error handling edge cases (non-critical)

**Approval**: Changes are safe to merge

---

## BLOCKERS (None)

---

## WARNINGS (1)

### W1: Coverage Below Target
**Severity**: LOW
**File**: `auth/jwt.py:45-50, 67`
**Issue**: Token expiry edge cases not tested
**Recommendation**: Add tests for expired token handling (non-blocking for this patch)
**Tracking**: Create follow-up task

---

## NEXT STEPS
1. ✅ Merge to main branch
2. ✅ Proceed to RELEASE_DECISION
3. 📋 Create follow-up task for coverage improvement
```

## Gate Rules (Hard Blocks)

### FAIL conditions (MUST fix before merge):
- ❌ Any test failure
- ❌ Linting errors (not warnings)
- ❌ Type checking errors
- ❌ Build failure
- ❌ New security vulnerabilities (P0 or P1)
- ❌ Coverage decreased >5% from baseline

### WARN conditions (review but may proceed):
- ⚠️ Coverage below target but not decreased
- ⚠️ Linting warnings (not errors)
- ⚠️ Slow tests (>10s for unit tests)
- ⚠️ Large files (>500 lines)

## Gates (Must Pass)
- [ ] All critical checks executed
- [ ] Gate decision is clear (PASS or FAIL, no ambiguity)
- [ ] If FAIL, blockers are specific and actionable
- [ ] If PASS, approval is explicit

## Usage
```bash
# Automatic after CODEX_PATCH_RW
# OR manual:
/qa-gate

# Generates QA report and blocks merge if FAIL
```

## DORA Justification
- **Change Failure Rate ↓**: Catch 80%+ of bugs before production (industry benchmark)
- **Recovery Time ↓**: Fewer production incidents = less time spent on hotfixes
- **Lead Time ↔**: May slightly increase (run tests) but prevents much longer rework time
- **Confidence**: HIGH (backed by Accelerate/DORA research)

## Integration with Other Skills
1. **After CODEX_PATCH_RW** → always invoke QA_GATE (mandatory)
2. **If QA_GATE fails** → invoke CODEX_DIAGNOSE_RO to debug test failures
3. **If QA_GATE passes** → invoke SECURITY_GATE (mandatory for security-sensitive code)
4. **After both gates pass** → invoke RELEASE_DECISION

## Verification Command Discovery
If TASK_PACKET doesn't specify verification commands, use repository conventions:

```python
def discover_verification_commands(repo):
    """Auto-detect test commands from repository."""
    if exists("pytest.ini") or exists("pyproject.toml"):
        return ["pytest tests/ -v", "pytest --cov"]
    elif exists("package.json"):
        return ["npm test", "npm run lint"]
    elif exists("Makefile"):
        return ["make test", "make lint"]
    else:
        return ["# No tests found - ESCALATE TO HUMAN"]
```

## Model-Specific Notes
- **Codex**: Can execute this skill (run tests programmatically)
- **Claude**: Can execute this skill (orchestrate test runs)
- **Gemini**: Not involved (no testing capability)

## Tool Requirements
- **MCP**: `bash` (run test commands)
- **Read access**: Repository files
- **Write access**: `out/qa-report-*.md`

## Failure Modes & Recovery
| Failure | Symptom | Recovery |
|---------|---------|----------|
| Tests fail | Exit code != 0 | Block merge; report failures to CODEX_DIAGNOSE_RO |
| Test command not found | "pytest: command not found" | Check virtual environment; escalate to human |
| Flaky tests | Intermittent failures | Re-run 3x; if still fails, mark as blocker |
| Timeout | Tests run >5 min | Kill tests; report as blocker (tests too slow) |

## Example: Failed Gate
```markdown
# QA Gate Report

**Gate Result**: ❌ FAIL

## BLOCKERS (2)

### B1: Test Failure
**File**: `tests/test_auth_redis.py::test_timeout_handling`
**Error**:
```
AssertionError: Expected timeout=5s, got timeout=1s
```
**Action**: Fix timeout configuration; re-run QA_GATE

### B2: Type Error
**File**: `auth/middleware.py:45`
**Error**:
```
error: Argument 1 to "authenticate" has incompatible type "str"; expected "int"
```
**Action**: Fix type annotation; re-run QA_GATE

## NEXT STEPS
1. ❌ DO NOT MERGE (gate failed)
2. Fix blockers B1 and B2
3. Re-run /qa-gate
4. Only proceed to RELEASE_DECISION after PASS
```

## Advanced: Parallel Test Execution
For large test suites (>1000 tests):

```bash
# Split tests across workers
pytest tests/ -n 4 --dist loadscope  # 4 parallel workers
```

**Benefit**: Reduce gate time from 10min → 3min

## Coverage Baseline
Store baseline coverage in `progress/coverage-baseline.json`:
```json
{
  "baseline_date": "2026-01-01",
  "total_coverage": 91.2,
  "by_module": {
    "auth": 95.0,
    "api": 88.0,
    "frontend": 90.5
  }
}
```

**Gate rule**: New changes must not decrease coverage >5% from baseline

## Update Ledger After Execution
```json
{
  "skill": "qa-gate",
  "timestamp": "2026-01-05T11:20:00Z",
  "input": "Branch: fix/auth-timeout-20260105",
  "output": "out/qa-report-20260105-112000.md",
  "gate_result": "PASS",
  "tests_run": 57,
  "tests_passed": 57,
  "coverage": 88.5,
  "blockers": 0,
  "warnings": 1,
  "next_skill": "security-gate"
}
```

## References
- DORA Metrics: Change Failure Rate
- Google Testing Blog: "Test Sizes" (unit/integration/e2e)
- Pytest documentation: https://docs.pytest.org
