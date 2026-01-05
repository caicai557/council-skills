---
name: ledger-update
description: Update episodic memory ledger with task outcomes, decisions, and lessons learned
tags: [memory, documentation, dora-lt]
owner: claude
dora_impact:
  lead_time: decrease
  recovery_time: decrease
  rationale: Knowledge reuse prevents repeating mistakes; faster debugging via historical context
confidence: high
---

# LEDGER_UPDATE

## Purpose
Maintain a structured, queryable ledger of all Council decisions, task outcomes, and lessons learned. Enables:
- **Knowledge reuse**: Don't repeat solved problems
- **Faster debugging**: "Have we seen this error before?"
- **Audit trail**: "Why did we make this decision?"
- **Trend analysis**: "Are we getting better over time?"

## When to Invoke
- After completing any task (success or failure)
- After RELEASE_DECISION (deployment record)
- After incident/bug resolution
- After CONSENSUS_STOP (capture debate outcome)

## Input
- Task outcome (success/failure)
- All skill reports generated during task
- Key decisions made
- Lessons learned

## Output
Appends to `progress/ledger.jsonl` (JSON Lines format for streaming):

```jsonl
{"timestamp": "2026-01-05T12:30:00Z", "task_id": "fix-auth-timeout", "type": "task_completion", "status": "success", "skills_used": ["plan-task-packet", "route-work", "codex-diagnose-ro", "codex-patch-rw", "qa-gate", "security-gate", "release-decision"], "files_modified": ["auth/redis_pool.py"], "lines_changed": 1, "tests_passed": 57, "deployment_time": "2026-01-05T12:15:00Z", "root_cause": "Redis pool size too small", "fix": "Increased pool from 10 to 50", "lesson_learned": "Always load test connection pools before production", "dora_impact": {"deployment_frequency": "+1 deploy", "lead_time": "45 minutes (plan to deploy)", "change_failure_rate": "0%", "recovery_time": "N/A (no incident)"}}
```

Also creates human-readable `progress/NOTES.md` (append mode):

```markdown
---

## 2026-01-05: Fixed Auth Timeout Bug

### Summary
Redis connection pool exhausted under load, causing auth timeouts. Increased pool size from 10 to 50.

### Root Cause
- **File**: `auth/redis_pool.py:12`
- **Issue**: Hardcoded `pool_size=10` insufficient for 50 concurrent users
- **Evidence**: Logs showed `ConnectionPoolTimeout` at peak traffic

### Fix Applied
```diff
- pool_size=10
+ pool_size=50
```

### Verification
- ✅ All tests passed (57/57)
- ✅ Load test: 1000 requests, 0 failures
- ✅ Security scan: No vulnerabilities

### Deployment
- **Strategy**: Immediate release (low risk)
- **Time**: 2026-01-05 12:15 UTC
- **Rollback plan**: Git revert (1-line change)

### Lessons Learned
1. **Load test connection pools** before production (we didn't catch this in testing)
2. **Monitor Redis metrics** proactively (alert on pool usage >80%)
3. **Configuration should be environment variables** (not hardcoded)

### Follow-Up Tasks
- [ ] Add Redis pool monitoring alert
- [ ] Move pool size to environment variable
- [ ] Document Redis capacity planning

### DORA Metrics
- **Lead Time**: 45 minutes (bug reported → deployed)
- **Deployment**: Successful (no rollback)
- **Impact**: Fixed auth for all users; no downtime

### References
- Task Packet: `progress/TASK_PACKET.md`
- Diagnosis: `out/codex-diagnosis-20260105-105500.md`
- Patch: `out/codex-patch-20260105-111000.md`
- QA Report: `out/qa-report-20260105-112000.md`
- Security Report: `out/security-report-20260105-115000.md`
- Release Decision: `out/release-decision-20260105-120000.md`
```

## Ledger Schema (JSONL)

### Event Types
1. **task_completion**: Task finished (success or failure)
2. **consensus_decision**: Multi-agent debate outcome
3. **deployment**: Release to production
4. **incident**: Production issue
5. **rollback**: Reverted a change
6. **lesson_learned**: Insight worth remembering

### Required Fields
- `timestamp`: ISO 8601 datetime
- `type`: Event type (see above)
- `task_id`: Unique identifier (kebab-case)

### Optional Fields (task_completion)
- `status`: "success" | "failure" | "blocked"
- `skills_used`: Array of skill names
- `files_modified`: Array of file paths
- `lines_changed`: Integer
- `root_cause`: String (for bugs)
- `fix`: String (what was done)
- `lesson_learned`: String
- `dora_impact`: Object with DF/LT/CFR/RTS

## Query Examples

### Query 1: Find Similar Past Bugs
```bash
# Find all tasks related to "Redis" or "timeout"
cat progress/ledger.jsonl | jq 'select(.root_cause | contains("Redis") or contains("timeout"))'
```

**Output**:
```json
{"timestamp": "2026-01-05T12:30:00Z", "task_id": "fix-auth-timeout", "root_cause": "Redis pool size too small", "fix": "Increased pool from 10 to 50"}
{"timestamp": "2025-12-10T09:15:00Z", "task_id": "fix-session-timeout", "root_cause": "Redis server timeout too low", "fix": "Increased timeout from 1s to 5s"}
```

**Insight**: We've had Redis issues before; should prioritize monitoring

### Query 2: Calculate Average Lead Time
```bash
# Extract lead_time from all successful tasks
cat progress/ledger.jsonl | jq -r 'select(.status == "success") | .dora_impact.lead_time' | awk '{sum+=$1; count+=1} END {print "Avg Lead Time:", sum/count, "minutes"}'
```

**Output**: `Avg Lead Time: 52 minutes`

### Query 3: Most Frequently Modified Files
```bash
# Count file modification frequency
cat progress/ledger.jsonl | jq -r '.files_modified[]?' | sort | uniq -c | sort -rn | head -5
```

**Output**:
```
8 auth/middleware.py
5 auth/redis_pool.py
4 api/routes.py
...
```

**Insight**: `auth/middleware.py` is a hotspot; needs refactoring?

## Gates (Must Pass)
- [ ] Timestamp is valid ISO 8601
- [ ] Task ID is unique (no duplicates)
- [ ] Lesson learned is specific (not vague like "be more careful")
- [ ] DORA impact is quantified (not just "improved")

## Usage
```bash
# Automatic after task completion
# OR manual:
/ledger-update

# Claude appends to ledger.jsonl and NOTES.md
```

## DORA Justification
- **Lead Time ↓**: Query past solutions → don't reinvent the wheel
- **Recovery Time ↓**: Query past incidents → faster root cause analysis
- **Confidence**: HIGH (knowledge management proven to reduce toil)

## Integration with Other Skills
1. **After RELEASE_DECISION** → invoke LEDGER_UPDATE (mandatory)
2. **Before CODEX_DIAGNOSE_RO** → query ledger for similar bugs
3. **Weekly/Monthly** → generate report from ledger (trend analysis)

## Example: Incident Record
```jsonl
{"timestamp": "2026-01-10T03:45:00Z", "type": "incident", "task_id": "incident-auth-down", "severity": "P1", "duration_minutes": 23, "root_cause": "Redis server OOM (pool size too large)", "fix": "Reduced pool from 50 to 30; added memory alerts", "lesson_learned": "Pool size must be balanced with Redis memory limits", "dora_impact": {"recovery_time": "23 minutes"}}
```

## Model-Specific Notes
- **Claude**: You own this skill; update ledger after every task
- **Codex**: Contribute "lesson learned" when you discover non-obvious insights
- **Gemini**: Not involved

## Tool Requirements
- **MCP**: None
- **Write access**: `progress/ledger.jsonl`, `progress/NOTES.md`

## Failure Modes & Recovery
| Failure | Symptom | Recovery |
|---------|---------|----------|
| JSONL parse error | Invalid JSON in ledger | Fix manually; validate with `jq` |
| Duplicate task IDs | Same ID appears twice | Append timestamp to make unique |
| Ledger file missing | FileNotFoundError | Create new ledger (start fresh) |
| NOTES.md too large | >1MB file | Archive old notes to `progress/archive/NOTES-2025.md` |

## Advanced: Structured Lessons Learned
```json
{
  "lesson_learned": {
    "context": "Redis connection pool configuration",
    "what_went_wrong": "Hardcoded pool size caused prod outage",
    "what_we_learned": "Always parameterize infrastructure config",
    "action_items": [
      "Move pool_size to env var",
      "Add pool usage monitoring",
      "Document capacity planning"
    ],
    "confidence": "high"
  }
}
```

## Ledger Rotation Policy
When `ledger.jsonl` exceeds 10MB:
1. Archive to `progress/archive/ledger-2026-Q1.jsonl`
2. Start new `ledger.jsonl`
3. Update index: `progress/ledger-index.json` with archive pointers

## Update Ledger After Execution (Meta!)
```jsonl
{"timestamp": "2026-01-05T12:30:00Z", "skill": "ledger-update", "task_id": "fix-auth-timeout", "ledger_entries_added": 1, "notes_lines_added": 45, "next_skill": "complete"}
```

## Trend Analysis (Monthly Report)
```python
import json
import pandas as pd

# Load ledger
with open("progress/ledger.jsonl") as f:
    data = [json.loads(line) for line in f]

df = pd.DataFrame(data)

# Calculate DORA trends
print("Deployment Frequency:", len(df[df["type"] == "deployment"]) / 30, "per day")
print("Avg Lead Time:", df["dora_impact.lead_time"].mean(), "minutes")
print("Change Failure Rate:", len(df[df["status"] == "rollback"]) / len(df) * 100, "%")
```

## References
- JSON Lines: https://jsonlines.org/
- DORA Metrics: Accelerate book
- Knowledge Management: NASA Lessons Learned system
