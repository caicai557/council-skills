# Council Skills for Claude Code

> **Multi-Agent AI Development System** aligned with DORA metrics, built on Claude Code's skill framework.

---

## 🎯 What Is This?

A production-ready **skill-based workflow system** that transforms Claude Code into a multi-agent development council with:

- **Claude (Opus/Sonnet)**: Orchestrator & final decision-maker
- **Codex**: Code diagnosis & implementation
- **Gemini Flash**: Cost-efficient file I/O & design exploration

All orchestrated through **atomic, auditable skills** that enforce DORA best practices.

---

## 🏗️ Architecture Principles

### 1. Default to Smallest Reversible Changes
Every code change must be:
- ≤5 files modified
- ≤100 lines changed
- Fully reversible (documented rollback)

### 2. Task Packet Protocol (Context Compression)
Never send full repository to executors. Use compressed task packets (5k tokens vs 50k).

### 3. Default No Tools, Explicit Enable/Disable
MCP tools are opt-in per task and removed immediately after use.

### 4. Read-Only First, Write on Approval
Codex starts with diagnosis (`ro`), escalates to patching (`rw`) only after approval.

### 5. Mandatory Quality Gates
No merge without passing:
- QA_GATE (tests, linting, build)
- SECURITY_GATE (threat model, vulnerability scan)

### 6. Wald Sequential Decision (3-Round Limit)
Multi-agent debates auto-escalate to human after 3 rounds (prevent analysis paralysis).

---

## 📊 DORA Alignment

Every skill declares its DORA impact:

| Metric | Goal | Primary Skills |
|--------|------|----------------|
| **Deployment Frequency** ↑ | Deploy multiple times per day | CODEX_PATCH_RW, RELEASE_DECISION |
| **Lead Time** ↓ | <1 hour from commit to production | PLAN_TASK_PACKET, CODEMAP_REFRESH |
| **Change Failure Rate** ↓ | <5% rollback rate | QA_GATE, SECURITY_GATE |
| **Recovery Time** ↓ | <15 min to restore service | LEDGER_UPDATE, rollback protocols |

---

## 🚀 Quick Start

### Prerequisites
- Claude Code CLI installed
- Python 3.8+ (for Council codebase)
- Git repository initialized

### Installation

```bash
# 1. Clone or use existing Council repo
cd /path/to/council

# 2. Initialize skill system
mkdir -p .claude/skills progress out docs

# 3. Copy skills to .claude/skills/ (already done if you're reading this)

# 4. Initialize ledger
echo '{"entries": []}' > progress/ledger.json
touch progress/ledger.jsonl
touch progress/NOTES.md

# 5. Optional: Generate initial CODEMAP
# (First time only; speeds up subsequent tasks)
# /codemap-refresh
```

### First Task: Fix a Bug

```bash
# 1. Start with planning
/plan-task-packet

# Claude generates progress/TASK_PACKET.md with:
# - Goal, scope, acceptance criteria
# - Verification commands
# - Rollback plan

# 2. Route work
/route-work

# Claude decides: codex-ro | codex-rw | gemini-json | human

# 3. Execute (automatic)
# Codex diagnoses → patches → verifies

# 4. Gates (automatic)
/qa-gate        # Tests, linting, build
/security-gate  # Vulnerability scan

# 5. Release (automatic or manual)
/release-decision

# 6. Deploy & record
# (deploy via your CI/CD)
/ledger-update
```

---

## 📁 Project Structure

```
council/
├── .claude/
│   └── skills/                      # ← Skill definitions (YOU ARE HERE)
│       ├── plan-task-packet.md
│       ├── route-work.md
│       ├── consensus-stop.md
│       ├── codex-diagnose-ro.md
│       ├── codex-patch-rw.md
│       ├── gemini-file-io.md
│       ├── gemini-ui-docs-json.md
│       ├── qa-gate.md
│       ├── security-gate.md
│       ├── release-decision.md
│       ├── ledger-update.md
│       └── codemap-refresh.md
│
├── progress/                        # ← Task artifacts (gitignored)
│   ├── TASK_PACKET.md              # Current task specification
│   ├── ROUTE_DECISION.md           # Executor selection
│   ├── CONSENSUS_DECISION.md       # Multi-agent debate outcomes
│   ├── CODEMAP.md                  # Compressed codebase map
│   ├── NOTES.md                    # Human-readable task history
│   ├── ledger.jsonl                # Machine-readable decision log
│   └── mcp-usage-log.jsonl         # MCP tool usage tracking
│
├── out/                             # ← Skill outputs (gitignored)
│   ├── codex-diagnosis-*.md
│   ├── codex-patch-*.md
│   ├── gemini-design-*.json
│   ├── qa-report-*.md
│   ├── security-report-*.md
│   └── release-decision-*.md
│
├── docs/                            # ← Documentation
│   ├── MCP_MANAGEMENT.md           # MCP tool lifecycle guide
│   └── WORKFLOW_EXAMPLES.md        # End-to-end examples
│
├── CONSTITUTION.md                  # ← System principles & rules
├── README.md                        # ← This file
│
└── [existing Council codebase]
    ├── agents/
    ├── orchestration/
    ├── governance/
    └── ...
```

---

## 🛠️ Available Skills

### Orchestration Layer (Claude)
| Skill | Purpose | Output |
|-------|---------|--------|
| **plan-task-packet** | Compress requirements into executable task packet | `TASK_PACKET.md` |
| **route-work** | Select optimal executor (codex/gemini/human) | `ROUTE_DECISION.md` |
| **consensus-stop** | Enforce 3-round limit on agent debates | `CONSENSUS_DECISION.md` |

### Execution Layer (Codex / Gemini)
| Skill | Purpose | Output |
|-------|---------|--------|
| **codex-diagnose-ro** | Read-only diagnosis (root cause analysis) | `codex-diagnosis-*.md` |
| **codex-patch-rw** | Apply minimal code changes with verification | `codex-patch-*.md` |
| **gemini-file-io** | Efficient file I/O via Gemini Flash (10x cheaper) | `gemini-files-*.json` |
| **gemini-ui-docs-json** | UI/UX exploration with JSON output | `gemini-design-*.json` |

### Guardian Layer (QA / Security)
| Skill | Purpose | Output |
|-------|---------|--------|
| **qa-gate** | Run tests, linting, build; block on failure | `qa-report-*.md` |
| **security-gate** | Threat modeling, vulnerability scan; block on P0 | `security-report-*.md` |
| **release-decision** | Approve release with rollout strategy | `release-decision-*.md` |

### Memory Layer (Secretary)
| Skill | Purpose | Output |
|-------|---------|--------|
| **ledger-update** | Record decisions & lessons learned | `ledger.jsonl`, `NOTES.md` |
| **codemap-refresh** | Generate compressed codebase map | `CODEMAP.md` |

---

## 💰 Cost Optimization

### Token Savings
- **Use Gemini Flash for file I/O**: 99.5% cheaper than Codex for reading files
- **Use CODEMAP instead of full repo**: 97.5% context reduction
- **Consensus stop**: 70% savings by capping debates at 3 rounds

### Example Cost Breakdown (Bug Fix)
| Operation | Model | Tokens | Cost |
|-----------|-------|--------|------|
| Read 50 files | Gemini Flash | 50k | $0.004 |
| Generate CODEMAP | Gemini Flash | 5k | $0.0004 |
| Diagnosis | Codex | 15k | $0.225 |
| Patch | Codex | 10k | $0.15 |
| QA Gate | Codex | 5k | $0.075 |
| **Total** | | **85k** | **~$0.45** |

**Without optimization**: ~$1.50 (3× more expensive)

---

## 🔒 Security Model

### Prompt Injection Defense
1. **No untrusted content fetch** without explicit approval
2. **MCP tools with network access** require justification in TASK_PACKET
3. **Output validation**: All Gemini JSON outputs must parse

### Tool Lifecycle (MCP)
```bash
# Before task
claude mcp add <tool> --scope local

# During task
# (use tool)

# After task (MANDATORY)
claude mcp remove <tool>
```

### Audit Trail
All MCP usage logged to `progress/mcp-usage-log.jsonl`

---

## 📈 Monitoring & Metrics

### Query Lead Time Trend
```bash
cat progress/ledger.jsonl | jq -r 'select(.status == "success") | .dora_impact.lead_time'
# Output: Average lead time in minutes
```

### Query Most-Changed Files
```bash
cat progress/ledger.jsonl | jq -r '.files_modified[]?' | sort | uniq -c | sort -rn
# Output: File change frequency (hotspots)
```

### Generate Monthly DORA Report
```bash
cat progress/ledger.jsonl | jq -s '
  {
    deployment_frequency: (map(select(.type == "deployment")) | length),
    avg_lead_time: (map(.dora_impact.lead_time) | add / length),
    change_failure_rate: (map(select(.status == "rollback")) | length / length * 100)
  }
'
```

---

## 🧪 Example Workflows

See [docs/WORKFLOW_EXAMPLES.md](docs/WORKFLOW_EXAMPLES.md) for complete end-to-end examples:
1. **Bug Fix** (30-60 min, low risk)
2. **New Feature** (2-4 hours, design-first)
3. **High-Risk Change** (canary rollout, human supervision)
4. **Incident Response** (<30 min recovery)

---

## 🤝 Contributing

### Adding a New Skill
1. Copy `.claude/skills/template.md` (if exists) or use existing skill as template
2. Define:
   - `name`, `description`, `tags`
   - `owner` (claude/codex/gemini)
   - `dora_impact` (which metric it improves)
   - Input, Output, Gates, Usage
3. Test skill with `/skill-name`
4. Update this README

### Modifying Existing Skills
1. Read `CONSTITUTION.md` (ensure changes align with principles)
2. Update skill markdown file
3. Test with real task
4. Update `NOTES.md` with lesson learned

---

## 📚 Documentation

- **[CONSTITUTION.md](CONSTITUTION.md)**: Core principles & agent roles
- **[docs/MCP_MANAGEMENT.md](docs/MCP_MANAGEMENT.md)**: MCP tool lifecycle
- **[docs/WORKFLOW_EXAMPLES.md](docs/WORKFLOW_EXAMPLES.md)**: End-to-end workflows
- **[.claude/skills/](./claude/skills/)**: Individual skill definitions

---

## 🐛 Troubleshooting

### Issue: Skill not found
**Cause**: Skill file not in `.claude/skills/`
**Fix**: Verify file exists; check filename matches skill name

### Issue: Task packet validation fails
**Cause**: Missing required fields (GOAL, VERIFICATION, etc.)
**Fix**: Run `/plan-task-packet` again with complete information

### Issue: QA Gate fails
**Cause**: Tests failing, linting errors, or build issues
**Fix**: Review `out/qa-report-*.md`; fix issues; re-run `/qa-gate`

### Issue: MCP tool not available
**Cause**: Tool not added or removed prematurely
**Fix**: `claude mcp add <tool> --scope local`

---

## 📖 References

- **DORA Metrics**: [Accelerate book](https://www.goodreads.com/book/show/35747076-accelerate)
- **Wald SPRT**: [Sequential Analysis (Wald, 1947)](https://en.wikipedia.org/wiki/Sequential_probability_ratio_test)
- **Claude Code**: [Official docs](https://claude.com/claude-code)
- **MCP Protocol**: [modelcontextprotocol.io](https://modelcontextprotocol.io/)

---

## 📄 License

[Your license here - e.g., MIT, Apache 2.0]

---

## 🙏 Acknowledgments

Built on:
- **Claude Code** (Anthropic)
- **DORA Research** (DevOps Research & Assessment)
- **Council Framework** (this repository's original multi-agent system)

---

**Ready to start?** Run `/plan-task-packet` with your first task!
