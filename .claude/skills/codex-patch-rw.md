---
name: codex-patch-rw
description: Execute minimal code changes after diagnosis - must pass verification or auto-rollback
tags: [execution, patching, dora-df]
owner: codex
dora_impact:
  deployment_frequency: increase
  change_failure_rate: decrease
  rationale: Small verified patches enable frequent safe deployments
confidence: high
---

# CODEX_PATCH_RW

## Purpose
Apply minimal code changes identified in CODEX_DIAGNOSE_RO. Enforces "smallest reversible change" principle with mandatory verification and auto-rollback on failure.

## Prerequisites (Hard Requirements)
- [ ] `progress/TASK_PACKET.md` exists
- [ ] `progress/ROUTE_DECISION.md` shows `codex-rw` permission
- [ ] `out/codex-diagnosis-*.md` exists with clear fix recommendation
- [ ] Claude (Chair) has approved RW escalation

**If any prerequisite fails → ABORT and escalate to human**

## Input
- Diagnosis report from CODEX_DIAGNOSE_RO
- Approved file list (from ROUTE_DECISION.md)
- Verification commands (from TASK_PACKET.md)

## Output
Creates `out/codex-patch-YYYYMMDD-HHMMSS.md`:

```markdown
# Patch Report: [Task Title]

**Timestamp**: 2026-01-05T11:10:00Z
**Executor**: Codex (Read-Write Mode)
**Diagnosis**: out/codex-diagnosis-20260105-105500.md

---

## CHANGES APPLIED

### File: `auth/redis_pool.py`
**Lines changed**: 1
**Diff**:
```diff
- pool_size=10
+ pool_size=50
```

**Rationale**: Increase connection pool to handle 50 concurrent users (per diagnosis)

---

## GIT COMMIT
**Branch**: `fix/auth-timeout-20260105`
**Commit**: `abc123def456...`
**Message**:
```
fix(auth): increase Redis pool size to prevent timeout

Root cause: Pool of 10 connections insufficient for peak load.
Fix: Increase to 50 (follows Redis best practices).

Verification:
- pytest tests/test_auth_redis.py -v (PASS)
- Load test 1000 requests (PASS)

🤖 Generated with Claude Code
Co-Authored-By: Codex <noreply@openai.com>
```

---

## VERIFICATION RESULTS

### Command 1: Unit Tests
```bash
$ pytest tests/test_auth_redis.py -v
```
**Status**: ✅ PASS
**Output**:
```
test_auth_redis.py::test_connection_pool ... PASSED
test_auth_redis.py::test_pool_exhaustion ... PASSED
test_auth_redis.py::test_timeout_handling ... PASSED
==================== 3 passed in 1.2s ====================
```

### Command 2: Load Test
```bash
$ python scripts/load_test_auth.py --requests 1000 --concurrent 50
```
**Status**: ✅ PASS
**Output**:
```
Completed 1000 requests in 4.2s
Success rate: 100.0%
No timeouts
```

---

## ROLLBACK INSTRUCTIONS
If issues arise in production:
```bash
git revert abc123def456
# OR
git checkout fix/auth-timeout-20260105~1 -- auth/redis_pool.py
pytest tests/test_auth_redis.py -v  # Verify rollback
```

---

## NEXT STEPS
- [ ] Merge to main (after QA_GATE approval)
- [ ] Deploy to staging
- [ ] Monitor Redis metrics for 24h
- [ ] If stable → deploy to production
```

## Change Size Limits (Hard Gates)
| Metric | Limit | Rationale |
|--------|-------|-----------|
| Files modified | ≤5 | Minimize blast radius |
| Lines changed per file | ≤50 | Keep changes reviewable |
| Total lines changed | ≤100 | Enforce "minimal change" principle |
| New dependencies | 0 | No dependency changes without human approval |

**If any limit exceeded → ABORT and escalate to human**

## Verification Protocol
1. **Run verification commands from TASK_PACKET** (mandatory)
2. **If any command fails**:
   - Try auto-fix (max 1 attempt)
   - If still fails → ROLLBACK and escalate
3. **If all pass**:
   - Create git commit
   - Update ledger
   - Proceed to QA_GATE

## Auto-Rollback Conditions
Trigger immediate rollback if:
- Verification commands fail
- New test failures (not present before patch)
- Build breaks
- Linter errors increase

**Rollback method**:
```bash
git stash  # Save changes
git reset --hard HEAD  # Restore clean state
# Report failure in out/codex-patch-FAILED-*.md
```

## Gates (Must Pass)
- [ ] All verification commands from TASK_PACKET passed
- [ ] Git commit created with proper message format
- [ ] No files modified outside approved list
- [ ] Change size within limits
- [ ] Rollback instructions tested and documented

## Usage
```bash
# After CODEX_DIAGNOSE_RO requests RW and Claude approves
/codex-patch-rw

# Codex applies minimal fix, runs verification, commits
```

## DORA Justification
- **Deployment Frequency ↑**: Small patches can be deployed hourly/daily (vs weekly for large changes)
- **Change Failure Rate ↓**: Mandatory verification catches issues before merge
- **Recovery Time ↓**: Documented rollback enables fast recovery
- **Confidence**: HIGH (DevOps Research: small batches reduce risk)

## Integration with Other Skills
1. **After CODEX_DIAGNOSE_RO** → if RW approved, invoke this skill
2. **After successful patch** → invoke QA_GATE (mandatory)
3. **After QA_GATE pass** → invoke LEDGER_UPDATE
4. **If verification fails** → invoke CONSENSUS_STOP (debate alternate fix)

## Model-Specific Notes
- **Codex**: You execute this skill; be paranoid about verification
- **Claude**: Review patch report before approving QA_GATE
- **Gemini**: Not involved (you don't write code)

## Tool Requirements
- **MCP**: `filesystem` (write files), `git` (commit)
- **Write access**: Files from approved list ONLY
- **Git**: Must be in repository with clean working tree

## Failure Modes & Recovery
| Failure | Symptom | Recovery |
|---------|---------|----------|
| Verification fails | Tests fail after patch | Auto-rollback; re-diagnose |
| Git conflict | Another commit modified same file | Abort; escalate to human for merge resolution |
| Change too large | Exceeds line limits | Abort; split into multiple tasks |
| Unauthorized file write | Codex tries to modify unapproved file | Block write; escalate to human |

## Example Output (Success)
```markdown
# Patch Report: Fix Auth Timeout

## CHANGES APPLIED
### File: `auth/redis_pool.py`
**Lines changed**: 1
```diff
- pool_size=10
+ pool_size=50
```

## VERIFICATION RESULTS
✅ All tests passed (3/3)
✅ Load test: 1000 requests, 0 failures
✅ Linter: no new issues

## GIT COMMIT
Branch: `fix/auth-timeout-20260105`
Commit: `abc123`

## NEXT STEPS
Ready for QA_GATE
```

## Example Output (Failure → Rollback)
```markdown
# Patch Report: Fix Auth Timeout [FAILED]

## CHANGES ATTEMPTED
### File: `auth/redis_pool.py`
**Lines changed**: 1
```diff
- pool_size=10
+ pool_size=50
```

## VERIFICATION RESULTS
❌ Test failed: `test_auth_redis.py::test_timeout_handling`
**Error**:
```
AssertionError: Expected timeout after 5s, got timeout after 1s
```

## ROLLBACK PERFORMED
```bash
git reset --hard HEAD
```
Repository restored to clean state.

## DIAGNOSIS UPDATE NEEDED
Original diagnosis may be incomplete. Possible alternate causes:
1. Timeout value is hardcoded elsewhere
2. Redis server configuration issue

## NEXT STEPS
1. Re-run CODEX_DIAGNOSE_RO with focus on timeout configuration
2. OR escalate to human for manual investigation
```

## Advanced: Atomic Multi-File Changes
For rare cases where fix requires >1 file (still ≤5 files):

```python
def atomic_patch(files, changes):
    """
    Apply changes to multiple files atomically.
    If verification fails, rollback ALL files.
    """
    # 1. Create backup
    backup_id = create_backup(files)

    try:
        # 2. Apply all changes
        for file, change in zip(files, changes):
            apply_change(file, change)

        # 3. Run verification
        if not verify_all():
            raise VerificationError("Tests failed")

        # 4. Commit
        git_commit(files, message="...")

    except Exception as e:
        # 5. Rollback on any failure
        restore_backup(backup_id)
        raise
```

## Commit Message Format (Enforced)
```
<type>(<scope>): <subject>

<body>

Verification:
- <command 1> (PASS/FAIL)
- <command 2> (PASS/FAIL)

🤖 Generated with Claude Code
Co-Authored-By: Codex <noreply@openai.com>
```

**Types**: `fix`, `feat`, `refactor`, `test`, `docs`
**Scope**: Module name (e.g., `auth`, `api`, `frontend`)
**Subject**: ≤50 chars, imperative mood

## Update Ledger After Execution
```json
{
  "skill": "codex-patch-rw",
  "timestamp": "2026-01-05T11:10:00Z",
  "input": "out/codex-diagnosis-20260105-105500.md",
  "output": "out/codex-patch-20260105-111000.md",
  "files_modified": ["auth/redis_pool.py"],
  "lines_changed": 1,
  "verification_passed": true,
  "commit": "abc123def456",
  "next_skill": "qa-gate"
}
```

## Cost Optimization with Gemini Flash
Use GEMINI_FILE_IO to read large files before patching:

```python
# Instead of:
codex.read_file("auth/middleware.py")  # Expensive

# Do:
summary = gemini_flash.read_file("auth/middleware.py")  # Cheap
codex.apply_patch(summary, diagnosis)  # Codex only sees summary
```

**Savings**: ~50% token reduction for Codex

## References
- DORA Metrics: Deployment Frequency & Change Failure Rate
- Google SRE: "Small Batch Size" principle
- Git Best Practices: Atomic commits
