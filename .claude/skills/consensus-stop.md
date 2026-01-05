---
name: consensus-stop
description: Wald sequential decision - max 3 rounds of agent debate, then auto-escalate to human
tags: [orchestration, consensus, dora-lt]
owner: claude
dora_impact:
  lead_time: decrease
  rationale: Prevents analysis paralysis; forces decision or escalation
confidence: medium
---

# CONSENSUS_STOP (Wald Sequential Decision)

## Purpose
Prevent infinite agent debate by enforcing Wald's sequential probability ratio test (SPRT) adapted for multi-agent consensus. After 3 rounds of disagreement, auto-escalate to human rather than waste tokens.

## Theoretical Foundation
**Wald SPRT**: Choose between hypotheses H0 and H1 by accumulating evidence until crossing an acceptance/rejection threshold OR hitting a sample limit.

**Adaptation for AI Council**:
- H0 = "Agents can reach consensus on this task"
- H1 = "Task requires human judgment"
- Evidence = agent agreement/disagreement scores
- Sample limit = 3 rounds
- Thresholds: A (accept consensus), B (reject → human)

## Input
- Multiple agent proposals (2-4 agents)
- Disagreement areas (explicit)
- Round counter (1-3)

## Output
Creates `progress/CONSENSUS_DECISION.md`:

```markdown
# Consensus Decision: [Task Title]

## ROUND: [1/2/3]

## PROPOSALS
### Agent 1 (Codex-RO)
[Summary of position]
**Confidence**: [H/M/L]

### Agent 2 (Claude-Chair)
[Summary of position]
**Confidence**: [H/M/L]

### Agent 3 (Optional)
[Summary of position]
**Confidence**: [H/M/L]

## AGREEMENT MATRIX
|          | Agent 1 | Agent 2 | Agent 3 |
|----------|---------|---------|---------|
| Agent 1  | -       | 60%     | 80%     |
| Agent 2  | 60%     | -       | 40%     |
| Agent 3  | 80%     | 40%     | -       |

**Average Agreement**: [score]%

## DECISION
**[CONSENSUS_REACHED | CONTINUE_DEBATE | ESCALATE_TO_HUMAN]**

## REASONING
[Why this decision was made]

## NEXT STEPS
- If CONSENSUS_REACHED → [execute agreed solution]
- If CONTINUE_DEBATE → [specific question for next round]
- If ESCALATE_TO_HUMAN → [summary of disagreement for human review]

## STATISTICAL SUMMARY
- Rounds completed: [N]
- Convergence rate: [improving/stagnant/diverging]
- Recommendation: [continue/stop]
```

## Decision Rules

### Round 1
- **If avg agreement ≥ 80%** → CONSENSUS_REACHED
- **If avg agreement < 50% AND all agents low confidence** → ESCALATE (don't waste rounds)
- **Else** → CONTINUE_DEBATE

### Round 2
- **If avg agreement ≥ 70%** → CONSENSUS_REACHED
- **If agreement improved < 10% from Round 1** → ESCALATE (stagnant)
- **Else** → CONTINUE_DEBATE

### Round 3 (Final Round)
- **If avg agreement ≥ 60%** → CONSENSUS_REACHED (good enough)
- **Else** → ESCALATE_TO_HUMAN (hard stop)

## Gates (Must Pass)
- [ ] At least 2 agents have submitted proposals
- [ ] Agreement matrix is calculated (not guessed)
- [ ] Round counter ≤ 3
- [ ] If escalating, human summary is ≤ 500 words

## Usage
```bash
# Triggered automatically when multiple agents disagree
# OR manually invoked:
/consensus-stop

# Claude analyzes proposals and produces CONSENSUS_DECISION.md
```

## DORA Justification
- **Lead Time ↓**: Hard stop at 3 rounds prevents week-long debates
- **Change Failure Rate ↔**: Neutral (ensures decision quality but doesn't directly prevent failures)
- **Confidence**: MEDIUM (Wald SPRT proven for binary decisions; multi-agent adaptation is heuristic)

## Example 1: Consensus Reached (Round 1)
```markdown
# Consensus Decision: Fix Auth Timeout Bug

## ROUND: 1/3

## PROPOSALS
### Agent 1 (Codex-RO)
Root cause: Redis connection pool exhaustion. Fix: Increase pool size from 10 to 50.
**Confidence**: HIGH

### Agent 2 (Claude-Chair)
Agree with diagnosis. Suggest also adding connection timeout (5s) to prevent hangs.
**Confidence**: HIGH

## AGREEMENT MATRIX
|          | Codex | Claude |
|----------|-------|--------|
| Codex    | -     | 90%    |
| Claude   | 90%   | -      |

**Average Agreement**: 90%

## DECISION
**CONSENSUS_REACHED**

## REASONING
Both agents agree on root cause (Redis pool) and fix direction. Claude's timeout suggestion is additive, not conflicting. High confidence + high agreement → safe to proceed.

## NEXT STEPS
Execute combined fix:
1. Increase Redis pool to 50 (Codex proposal)
2. Add 5s connection timeout (Claude proposal)
3. Run verification: `pytest tests/test_auth_redis.py -v`

## STATISTICAL SUMMARY
- Rounds completed: 1
- Convergence rate: N/A (consensus on first round)
- Recommendation: PROCEED
```

## Example 2: Escalate to Human (Round 3)
```markdown
# Consensus Decision: Choose Auth Library (OAuth2 vs Passport)

## ROUND: 3/3

## PROPOSALS
### Agent 1 (Codex)
Use Passport.js: More established, better docs, fits our Node.js stack.
**Confidence**: MEDIUM

### Agent 2 (Gemini)
Use OAuth2 library: More modern, better TypeScript support, smaller bundle.
**Confidence**: MEDIUM

### Agent 3 (Claude-Chair)
Both are viable. Decision depends on team familiarity (not in context).
**Confidence**: LOW

## AGREEMENT MATRIX
|          | Codex | Gemini | Claude |
|----------|-------|--------|--------|
| Codex    | -     | 40%    | 50%    |
| Gemini   | 40%   | -      | 50%    |
| Claude   | 50%   | 50%    | -      |

**Average Agreement**: 46%

## DECISION
**ESCALATE_TO_HUMAN**

## REASONING
After 3 rounds, agreement is still <50%. Both options are technically sound but require human judgment on team expertise and long-term maintenance preferences. Continuing debate will not resolve this without external context.

## NEXT STEPS
Human decides based on:
1. Team familiarity with Passport.js vs OAuth2 patterns
2. Long-term maintenance burden (community support)
3. Bundle size importance (mobile vs desktop app)

Once human decides, return to Council for implementation.

## STATISTICAL SUMMARY
- Rounds completed: 3
- Convergence rate: STAGNANT (Round 1: 45%, Round 2: 47%, Round 3: 46%)
- Recommendation: STOP (hard limit reached)
```

## Agreement Score Calculation
```python
def calculate_agreement(proposal_a, proposal_b):
    """
    Compare two proposals and return agreement score (0-100%).
    Uses semantic similarity + explicit conflict detection.
    """
    # Simplified heuristic (real implementation would use embeddings)
    shared_concepts = set(proposal_a.key_points) & set(proposal_b.key_points)
    total_concepts = set(proposal_a.key_points) | set(proposal_b.key_points)

    base_agreement = len(shared_concepts) / len(total_concepts) * 100

    # Penalty for explicit conflicts
    conflicts = detect_conflicts(proposal_a, proposal_b)
    penalty = len(conflicts) * 10  # -10% per conflict

    return max(0, base_agreement - penalty)

def detect_conflicts(a, b):
    """Returns list of conflicting statements."""
    # E.g., "use library X" vs "use library Y"
    # E.g., "increase timeout to 30s" vs "decrease timeout to 5s"
    pass  # Implementation details
```

## Integration with Other Skills
1. **Triggered during ROUTE_WORK** → if multiple executors propose different solutions
2. **Triggered during QA_GATE** → if QA and Security guardians disagree on risk
3. **Triggered during RELEASE_DECISION** → if agents disagree on rollout strategy
4. **Output feeds into LEDGER_UPDATE** → record why decision was made

## Model-Specific Notes
- **Claude (Opus/Sonnet)**: You own this skill; calculate agreement scores honestly (no bias toward your own proposal)
- **Codex**: Submit proposal with explicit confidence; accept Chair's consensus ruling
- **Gemini**: Submit proposal; if escalated to human, provide visual comparison if helpful

## Tool Requirements
- **MCP**: None
- **Write access**: `progress/CONSENSUS_DECISION.md`

## Failure Modes & Recovery
| Failure | Symptom | Recovery |
|---------|---------|----------|
| Agents refuse to compromise | 3 rounds, 0% convergence | Auto-escalate (working as intended) |
| Agreement score calculation fails | Error in matrix | Use simple heuristic: count explicit conflicts |
| Round counter lost | Unclear which round | Default to Round 3 (conservative; escalate) |

## Advanced: Confidence-Weighted Agreement
```python
def weighted_agreement(proposals):
    """
    Weight agreement scores by agent confidence.
    High-confidence disagreements are worse than low-confidence ones.
    """
    total_weighted_agreement = 0
    total_weight = 0

    for (agent_a, agent_b) in combinations(proposals, 2):
        raw_agreement = calculate_agreement(agent_a.proposal, agent_b.proposal)
        weight = agent_a.confidence * agent_b.confidence  # 0.0-1.0
        total_weighted_agreement += raw_agreement * weight
        total_weight += weight

    return total_weighted_agreement / total_weight if total_weight > 0 else 0
```

**Example**: Two agents at 90% agreement but both LOW confidence (0.3) → weighted agreement = 90% × 0.09 = 8.1 (very weak consensus)

## When to Skip This Skill
- **Single executor tasks** → No debate possible
- **Human already involved** → Human is ultimate arbiter
- **Trivial decisions** (e.g., variable naming) → Don't waste rounds; flip a coin

## Update Ledger After Execution
```json
{
  "skill": "consensus-stop",
  "timestamp": "2026-01-05T10:45:00Z",
  "input": "2 agent proposals (Codex, Claude)",
  "output": "progress/CONSENSUS_DECISION.md",
  "decision": "CONSENSUS_REACHED",
  "rounds_used": 1,
  "avg_agreement": 90,
  "escalated": false
}
```

## References
- Wald, A. (1945). "Sequential Tests of Statistical Hypotheses"
- DevOps Research & Assessment: "Lead Time" metric definition
- Google SRE Book: "Error Budgets" (similar threshold-based decision-making)
