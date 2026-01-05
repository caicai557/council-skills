---
name: plan-task-packet
description: Generate strict TASK_PACKET with goal, constraints, acceptance criteria, verification commands, and risks
tags: [orchestration, planning, dora-lt]
owner: claude
dora_impact:
  lead_time: decrease
  rationale: Clear scope prevents rework and context thrashing
confidence: high
---

# PLAN_TASK_PACKET

## Purpose
Compress user requirements into a minimal, executable task packet for downstream executors (Codex/Gemini). This prevents sending full repository context and reduces lead time through clear acceptance criteria.

## Input
- User request/bug report
- Current constraints (time/scope/risk tolerance)
- Repository context (minimal - only relevant modules)

## Output
Creates `progress/TASK_PACKET.md` with strict schema:

```markdown
# Task Packet: [Short Title]

## GOAL
[One sentence: what observable outcome defines success?]

## CONSTRAINTS
- Time: [e.g., "must complete in single session"]
- Scope: [e.g., "modify only auth/ module"]
- Risk: [e.g., "no breaking changes to public API"]

## IN-SCOPE
- Files: [list specific paths]
- Modules: [list affected components]
- Dependencies: [list required tools/MCPs]

## OUT-OF-SCOPE (Non-Goals)
- [Explicitly state what this task will NOT do]

## ACCEPTANCE CRITERIA (Observable)
1. [Concrete, testable outcome]
2. [Concrete, testable outcome]
3. [Maximum 5 criteria]

## VERIFICATION (Exact Commands)
```bash
# Run these commands to verify success
pytest tests/test_auth.py -v
flake8 auth/
mypy auth/
```

## RISKS (Top 3) + Mitigation
1. **[Risk]**: [Likelihood: H/M/L] → Mitigation: [action]
2. **[Risk]**: [Likelihood: H/M/L] → Mitigation: [action]
3. **[Risk]**: [Likelihood: H/M/L] → Mitigation: [action]

## ROLLBACK STRATEGY
[Exact steps to undo changes if verification fails]
```

## Gates (Must Pass)
- [ ] GOAL is one sentence
- [ ] ACCEPTANCE criteria are observable (not subjective)
- [ ] VERIFICATION commands are copy-pasteable
- [ ] RISKS include likelihood + mitigation
- [ ] ROLLBACK strategy is concrete

## Usage
```bash
# User invokes
/plan-task-packet

# Claude generates progress/TASK_PACKET.md
# Then blocks any execution until packet passes gates
```

## DORA Justification
- **Lead Time ↓**: Clear acceptance → less rework → faster merge
- **Change Failure Rate ↓**: Upfront risk analysis catches issues before coding
- **Confidence**: HIGH (proven by DevOps Research & Assessment studies)

## Anti-Patterns to Reject
❌ Vague goals like "improve performance"
❌ Missing verification commands
❌ No rollback strategy
❌ Subjective acceptance criteria ("code should be clean")

## Example (Good)
```markdown
# Task Packet: Add Rate Limiting to Auth Endpoint

## GOAL
Reject >100 requests/min/IP on /api/auth/login to prevent brute force attacks.

## CONSTRAINTS
- Scope: auth/middleware.py only
- Risk: Must not break existing tests

## IN-SCOPE
- Files: auth/middleware.py, tests/test_auth_rate_limit.py
- Dependencies: MCP redis (add before task, remove after)

## ACCEPTANCE CRITERIA
1. 101st request within 60s returns HTTP 429
2. Valid requests under limit return HTTP 200
3. All existing auth tests still pass

## VERIFICATION
```bash
pytest tests/test_auth.py tests/test_auth_rate_limit.py -v
curl -X POST http://localhost:8000/api/auth/login # (repeat 101 times)
```

## RISKS
1. **Redis unavailable in CI**: [H] → Mitigation: Mock Redis in tests
2. **Timezone bugs in rate window**: [M] → Mitigation: Use UTC timestamps
3. **False positives for shared IPs**: [L] → Mitigation: Document as known limitation

## ROLLBACK STRATEGY
```bash
git revert <commit-hash>
# OR
git checkout HEAD~1 -- auth/middleware.py
pytest tests/test_auth.py -v  # Verify rollback
```
```

## Integration with Other Skills
1. **After PLAN_TASK_PACKET** → always call **ROUTE_WORK** (never skip routing)
2. **Before CODEX_PATCH_RW** → verify TASK_PACKET exists (abort if missing)
3. **Before RELEASE_DECISION** → check VERIFICATION commands passed

## Model-Specific Notes
- **Claude (Opus/Sonnet)**: Use this skill; you own planning
- **Codex**: Never call this; receive task packets as read-only input
- **Gemini**: Never call this; receive sub-tasks from Claude

## Tool Requirements
- **MCP**: None (this is pure planning)
- **Write access**: `progress/TASK_PACKET.md`

## Failure Modes & Recovery
| Failure | Symptom | Recovery |
|---------|---------|----------|
| Missing VERIFICATION | Task packet saved but incomplete | Re-run skill with strict validation |
| Vague GOAL | Executors ask clarifying questions | Human-in-loop refinement |
| No ROLLBACK | Changes can't be safely undone | Abort task; escalate to human |

## Update Ledger After Execution
```json
{
  "skill": "plan-task-packet",
  "timestamp": "2026-01-05T10:30:00Z",
  "input": "User: Add rate limiting to auth",
  "output": "progress/TASK_PACKET.md",
  "gates_passed": true,
  "next_skill": "route-work"
}
```
