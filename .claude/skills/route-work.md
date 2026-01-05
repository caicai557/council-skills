---
name: route-work
description: Route task packet to Codex(ro/rw), Gemini(json), or Human based on complexity, risk, and required permissions
tags: [orchestration, routing, dora-lt]
owner: claude
dora_impact:
  lead_time: decrease
  change_failure_rate: decrease
  rationale: Smart routing prevents wasted cycles on wrong executor; ro-first reduces accidental breakage
confidence: high
---

# ROUTE_WORK

## Purpose
Analyze TASK_PACKET.md and route to optimal executor with minimal permissions. Implements "read-only first" and auto-escalates high-risk changes to human review.

## Input
- `progress/TASK_PACKET.md` (required; abort if missing)
- Current repository state
- Executor capabilities matrix

## Output
Creates `progress/ROUTE_DECISION.md`:

```markdown
# Route Decision: [Task Title]

## SELECTED EXECUTOR
**[codex-ro | codex-rw | gemini-json | human]**

## REASONING
[2-3 sentences explaining why this executor is optimal]

## PERMISSION LEVEL
- Read: [files/modules]
- Write: [files/modules OR "NONE" for ro]
- External Tools (MCP): [list OR "NONE"]

## ESCALATION TRIGGERS
If any occur during execution, auto-escalate to human:
- [ ] Verification commands fail 2+ times
- [ ] Executor requests permission outside scope
- [ ] Security scan detects P0 vulnerability

## ESTIMATED CONTEXT SIZE
- Input tokens: ~[estimate]
- Rationale: [why this size is minimal]

## GUARDRAILS
- **Time limit**: [e.g., "30min; abort if exceeded"]
- **Retry budget**: [e.g., "max 2 retries on verification failure"]
- **Blast radius**: [e.g., "changes limited to auth/ directory"]

## NEXT STEPS
1. [Specific action for executor]
2. [Verification to run]
3. [How to signal completion]
```

## Routing Decision Matrix

| Condition | Route To | Permission | Rationale |
|-----------|----------|------------|-----------|
| "Diagnose bug/error" | codex-ro | Read-only | No writes needed for diagnosis |
| "Implement feature" (low risk) | codex-ro → codex-rw | ro first, then rw after human approval | Catch design issues before writing |
| "Implement feature" (touches auth/security/billing) | human | N/A | High-risk areas require human oversight |
| "UI design options" | gemini-json | Read-only + JSON output | Gemini excels at design exploration |
| "Refactor >5 files" | human | N/A | Large blast radius needs human planning |
| "Database migration" | human | N/A | Irreversible operations need human approval |
| "Dependency upgrade (major version)" | codex-ro → human | Read-only analysis | Breaking changes likely; human decides |

## Gates (Must Pass)
- [ ] TASK_PACKET.md exists
- [ ] Selected executor has required capabilities
- [ ] Permission level is minimal (principle of least privilege)
- [ ] Escalation triggers are defined
- [ ] Estimated context < 50k tokens (if larger, split task)

## Usage
```bash
# After /plan-task-packet
/route-work

# Claude generates progress/ROUTE_DECISION.md
# Then invokes appropriate executor with scoped permissions
```

## DORA Justification
- **Lead Time ↓**: Right executor on first try → no rework
- **Change Failure Rate ↓**: ro-first catches issues before writes; auto-escalation prevents risky merges
- **Confidence**: HIGH (DevOps best practice: least privilege + staged rollout)

## Example 1: Read-Only Diagnosis
```markdown
# Route Decision: Debug Auth Timeout

## SELECTED EXECUTOR
**codex-ro**

## REASONING
Task requires analyzing logs and existing auth flow. No code changes needed yet. Read-only minimizes risk.

## PERMISSION LEVEL
- Read: auth/*.py, tests/test_auth.py, logs/auth.log
- Write: NONE
- External Tools: NONE

## ESCALATION TRIGGERS
- [x] If root cause requires changing auth/security boundary → escalate to human

## ESTIMATED CONTEXT SIZE
- Input tokens: ~8,000 (3 files + TASK_PACKET)
- Rationale: Only auth module needed; rest of repo excluded

## GUARDRAILS
- Time limit: 15min
- Retry budget: N/A (read-only)
- Blast radius: ZERO (no writes)

## NEXT STEPS
1. Read auth/*.py and logs/auth.log
2. Produce out/codex-diagnosis.md with root cause analysis
3. If fix is <10 lines in single file → request rw upgrade; else → escalate to human
```

## Example 2: Escalate to Human (High Risk)
```markdown
# Route Decision: Migrate User Table to Postgres 15

## SELECTED EXECUTOR
**human**

## REASONING
Database migrations are irreversible. Data loss risk = P0. This requires:
1. Backup strategy
2. Rollback plan with data consistency guarantees
3. Staged rollout (test DB → prod)

No AI executor should perform this without human oversight.

## PERMISSION LEVEL
N/A (blocked until human reviews)

## ESCALATION TRIGGERS
N/A (already escalated)

## ESTIMATED CONTEXT SIZE
N/A

## GUARDRAILS
Human must provide:
- [ ] Backup verification command
- [ ] Rollback SQL script
- [ ] Staging environment test results

## NEXT STEPS
1. Human reviews migration plan
2. Human approves OR requests AI-assisted planning
3. If approved → human executes OR delegates to codex-rw with explicit supervision
```

## Example 3: Gemini for UI Design
```markdown
# Route Decision: Design Dashboard Layout Options

## SELECTED EXECUTOR
**gemini-json**

## REASONING
Task requires visual design exploration with multiple options. Gemini's long context + multimodal understanding is optimal. Output must be JSON for structured comparison.

## PERMISSION LEVEL
- Read: frontend/components/*.tsx, design-system/
- Write: out/gemini-dashboard-options.json (only)
- External Tools: NONE

## ESCALATION TRIGGERS
- [x] If JSON fails to parse after 2 attempts → abort and escalate

## ESTIMATED CONTEXT SIZE
- Input tokens: ~15,000 (component examples + design system)
- Rationale: Gemini's 1M context allows full component library

## GUARDRAILS
- Time limit: 20min
- Output validation: Must parse as JSON; must include 2-4 options
- Blast radius: ZERO (output is documentation, not code)

## NEXT STEPS
1. Analyze existing components and design tokens
2. Generate 3 layout options as JSON
3. Human reviews JSON and selects option
4. Selected option becomes input to codex-rw for implementation
```

## Integration with Other Skills
1. **After PLAN_TASK_PACKET** → always call ROUTE_WORK (mandatory)
2. **Before CODEX_DIAGNOSE_RO / CODEX_PATCH_RW / GEMINI_UI_DOCS_JSON** → verify ROUTE_DECISION exists
3. **If executor requests permission escalation** → re-run ROUTE_WORK with updated risk assessment

## Model-Specific Notes
- **Claude (Opus/Sonnet)**: You own this skill; never delegate routing
- **Codex**: Receive ROUTE_DECISION as read-only input; request escalation if you need more permissions
- **Gemini**: Receive ROUTE_DECISION; abort if asked to write code (you're design/docs only)

## Tool Requirements
- **MCP**: None (pure decision-making)
- **Write access**: `progress/ROUTE_DECISION.md`

## Failure Modes & Recovery
| Failure | Symptom | Recovery |
|---------|---------|----------|
| Executor unavailable | API error/timeout | Re-route to human OR retry with backoff |
| Context size exceeds limit | Token overflow | Split TASK_PACKET into sub-tasks; route each separately |
| Executor refuses task | "I cannot do X" response | Re-route to human with executor's refusal as context |
| Permission denied during execution | Executor tries to write in ro mode | Auto-escalate to human; review ROUTE_DECISION |

## Security Considerations
- **Never route untrusted user input directly to executors** → always sanitize via TASK_PACKET first
- **MCP tools with network access** → only allow if explicitly justified in TASK_PACKET
- **Write permissions** → always start ro; escalate to rw only after human/Claude approval

## Update Ledger After Execution
```json
{
  "skill": "route-work",
  "timestamp": "2026-01-05T10:35:00Z",
  "input": "progress/TASK_PACKET.md",
  "output": "progress/ROUTE_DECISION.md",
  "selected_executor": "codex-ro",
  "permission_level": "read-only",
  "escalation_triggers": ["verification_failure_2x", "permission_request_outside_scope"],
  "next_skill": "codex-diagnose-ro"
}
```

## Advanced: Context Budget Optimization
When routing, estimate token usage:

```python
# Pseudo-code for context estimation
def estimate_context(task_packet, executor):
    base_cost = len(task_packet.in_scope_files) * 500  # avg file size
    instruction_cost = 2000  # skill instructions
    safety_margin = 5000
    total = base_cost + instruction_cost + safety_margin

    if total > executor.context_limit:
        return "SPLIT_TASK"  # Too large; break into sub-tasks
    return "OK"
```

## Human Escalation Protocol
When routing to human:
1. Produce `progress/HUMAN_REVIEW_REQUIRED.md` with:
   - Why AI can't safely handle this
   - What human needs to decide
   - What information AI can provide to assist decision
2. Pause all execution
3. Wait for human input
4. If human approves → update ROUTE_DECISION with human's constraints
5. If human rejects → close task with explanation in NOTES.md
