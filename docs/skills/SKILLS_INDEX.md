# Council Skills Index

> Quick reference for all available skills in the Council system

---

## 📋 Skill Catalog

### Orchestration & Planning (Owner: Claude)

#### plan-task-packet
- **File**: `.claude/skills/plan-task-packet.md`
- **Purpose**: Generate strict TASK_PACKET with goal, scope, acceptance criteria, verification, and risks
- **Input**: User request, constraints
- **Output**: `progress/TASK_PACKET.md`
- **DORA**: ↓ Lead Time (clear scope prevents rework)
- **Usage**: `/plan-task-packet`

#### route-work
- **File**: `.claude/skills/route-work.md`
- **Purpose**: Route task to optimal executor (codex-ro/rw, gemini-json, human) with minimal permissions
- **Input**: TASK_PACKET.md
- **Output**: `progress/ROUTE_DECISION.md`
- **DORA**: ↓ Lead Time, ↓ Change Failure Rate (right executor first time; ro-first safety)
- **Usage**: `/route-work`

#### consensus-stop
- **File**: `.claude/skills/consensus-stop.md`
- **Purpose**: Wald sequential decision - max 3 rounds of agent debate, then escalate
- **Input**: Multiple agent proposals
- **Output**: `progress/CONSENSUS_DECISION.md`
- **DORA**: ↓ Lead Time (prevent analysis paralysis)
- **Usage**: Automatic when agents disagree

---

### Execution & Implementation (Owner: Codex / Gemini)

#### codex-diagnose-ro
- **File**: `.claude/skills/codex-diagnose-ro.md`
- **Purpose**: Read-only diagnosis - analyze bugs/errors without writes
- **Input**: TASK_PACKET, logs, relevant files
- **Output**: `out/codex-diagnosis-*.md`
- **DORA**: ↓ Change Failure Rate, ↓ Lead Time (catch issues before coding)
- **Usage**: `/codex-diagnose-ro`

#### codex-patch-rw
- **File**: `.claude/skills/codex-patch-rw.md`
- **Purpose**: Execute minimal code changes with mandatory verification and auto-rollback
- **Input**: Diagnosis report, approved file list
- **Output**: `out/codex-patch-*.md`
- **DORA**: ↑ Deployment Frequency, ↓ Change Failure Rate (small verified patches)
- **Usage**: `/codex-patch-rw`

#### gemini-file-io
- **File**: `.claude/skills/gemini-file-io.md`
- **Purpose**: Efficient file reading/writing via Gemini Flash (10x cheaper than Codex)
- **Input**: File patterns or operation spec
- **Output**: `out/gemini-files-*.json` or `out/gemini-summary-*.md`
- **DORA**: ↓ Lead Time (faster file ops), Cost savings (70%+)
- **Usage**: `/gemini-file-io --operation READ|WRITE|SUMMARIZE`

#### gemini-ui-docs-json
- **File**: `.claude/skills/gemini-ui-docs-json.md`
- **Purpose**: UI/UX exploration with strict JSON output (design before coding)
- **Input**: Design constraints, existing components
- **Output**: `out/gemini-design-*.json`
- **DORA**: ↓ Lead Time (explore options before building)
- **Usage**: `/gemini-ui-docs-json`
- **Note**: Disabled from auto-model-invocation (manual only)

---

### Quality & Security Guardians (Owner: Codex / Claude)

#### qa-gate
- **File**: `.claude/skills/qa-gate.md`
- **Purpose**: Mandatory quality gate - tests, linting, build verification before merge
- **Input**: Current branch with changes
- **Output**: `out/qa-report-*.md`
- **DORA**: ↓ Change Failure Rate, ↓ Recovery Time (catch failures pre-prod)
- **Usage**: `/qa-gate`

#### security-gate
- **File**: `.claude/skills/security-gate.md`
- **Purpose**: Skeptical security review - threat modeling, vulnerability scan, P0 blocks merge
- **Input**: Current branch, QA report
- **Output**: `out/security-report-*.md`
- **DORA**: ↓ Change Failure Rate, ↓ Recovery Time (prevent security incidents)
- **Usage**: `/security-gate`

#### release-decision
- **File**: `.claude/skills/release-decision.md`
- **Purpose**: Final gate - decide rollout strategy (immediate/canary/feature-flag) with rollback plan
- **Input**: QA + Security reports
- **Output**: `out/release-decision-*.md`
- **DORA**: ↑ Deployment Frequency, ↓ Recovery Time (safe frequent releases)
- **Usage**: `/release-decision`

---

### Memory & Context Management (Owner: Claude / Gemini Flash)

#### ledger-update
- **File**: `.claude/skills/ledger-update.md`
- **Purpose**: Update episodic memory ledger with task outcomes, decisions, lessons learned
- **Input**: Task outcome, all skill reports
- **Output**: `progress/ledger.jsonl`, `progress/NOTES.md`
- **DORA**: ↓ Lead Time, ↓ Recovery Time (knowledge reuse prevents repeating mistakes)
- **Usage**: `/ledger-update`

#### codemap-refresh
- **File**: `.claude/skills/codemap-refresh.md`
- **Purpose**: Generate compressed codebase map - reduces context by 80%+
- **Input**: Repository structure
- **Output**: `progress/CODEMAP.md`
- **DORA**: ↓ Lead Time (faster file discovery), Cost savings (70%)
- **Usage**: `/codemap-refresh`

---

## 🔄 Standard Workflows

### Workflow 1: Bug Fix (30-60 min)
```
/plan-task-packet
  ↓
/route-work → codex-ro
  ↓
/codex-diagnose-ro
  ↓
[Approve RW]
  ↓
/codex-patch-rw
  ↓
/qa-gate
  ↓
/security-gate
  ↓
/release-decision
  ↓
[Deploy]
  ↓
/ledger-update
```

### Workflow 2: New Feature (2-4 hours)
```
/plan-task-packet
  ↓
/route-work → gemini-json
  ↓
/gemini-ui-docs-json
  ↓
[Human selects option]
  ↓
/route-work → codex-rw
  ↓
/codex-patch-rw
  ↓
/qa-gate → /security-gate → /release-decision → /ledger-update
```

### Workflow 3: Incident Response (<30 min)
```
/codex-diagnose-ro --fast-track
  ↓
[Rollback OR emergency fix]
  ↓
/ledger-update --type incident
```

---

## 📊 Skill Metrics

| Skill | Avg Duration | Token Usage | Cost (est.) |
|-------|--------------|-------------|-------------|
| plan-task-packet | 2-5 min | 3k | $0.05 |
| route-work | 1-2 min | 2k | $0.03 |
| codex-diagnose-ro | 5-15 min | 15k | $0.225 |
| codex-patch-rw | 5-10 min | 10k | $0.15 |
| gemini-file-io | 1-3 min | 50k | $0.004 |
| gemini-ui-docs-json | 3-8 min | 15k | $0.02 |
| qa-gate | 2-10 min | 5k | $0.075 |
| security-gate | 2-5 min | 5k | $0.075 |
| release-decision | 1-3 min | 3k | $0.05 |
| ledger-update | 1-2 min | 2k | $0.03 |
| codemap-refresh | 5-10 min | 70k | $0.005 |

**Total typical bug fix**: ~45 min, ~100k tokens, **~$0.45**

---

## 🏷️ Skill Tags

### By Function
- **orchestration**: plan-task-packet, route-work, consensus-stop, release-decision
- **execution**: codex-diagnose-ro, codex-patch-rw, gemini-file-io, gemini-ui-docs-json
- **guardian**: qa-gate, security-gate, release-decision
- **memory**: ledger-update, codemap-refresh

### By DORA Impact
- **dora-df** (↑ Deployment Frequency): codex-patch-rw, release-decision
- **dora-lt** (↓ Lead Time): plan-task-packet, route-work, consensus-stop, codemap-refresh, ledger-update
- **dora-cfr** (↓ Change Failure Rate): codex-diagnose-ro, codex-patch-rw, qa-gate, security-gate, route-work
- **dora-rts** (↓ Recovery Time): security-gate, release-decision, ledger-update

### By Owner
- **claude**: plan-task-packet, route-work, consensus-stop, release-decision, ledger-update
- **codex**: codex-diagnose-ro, codex-patch-rw, qa-gate, security-gate
- **gemini**: gemini-file-io, gemini-ui-docs-json
- **gemini-flash**: gemini-file-io, codemap-refresh

---

## 🔍 Skill Discovery

### By Use Case
- **I have a bug to fix**: Start with `/plan-task-packet`, then `/codex-diagnose-ro`
- **I need to implement a feature**: Start with `/plan-task-packet`, then `/route-work`
- **I want to explore UI options**: Use `/gemini-ui-docs-json`
- **I need to read many files**: Use `/gemini-file-io --operation SUMMARIZE`
- **I need to verify quality**: Use `/qa-gate`
- **I need to audit security**: Use `/security-gate`
- **I need to review past decisions**: Query `progress/ledger.jsonl`

### By Risk Level
- **Low risk** (config changes): Direct to `/codex-patch-rw` after diagnosis
- **Medium risk** (logic changes): Use `/qa-gate` + `/security-gate`
- **High risk** (auth/payment/data): Require human approval in `/release-decision`
- **Critical** (incidents): Use fast-track diagnosis + rollback

---

## 📚 Additional Resources

- **CONSTITUTION.md**: System principles and agent roles
- **docs/MCP_MANAGEMENT.md**: MCP tool lifecycle guide
- **docs/WORKFLOW_EXAMPLES.md**: Detailed end-to-end examples
- **README.md**: Project overview and quick start

---

## 🆘 Common Issues

### "Skill not found"
- Check that file exists in `.claude/skills/`
- Verify filename matches skill name

### "Gate failed"
- Review gate report in `out/`
- Fix blockers and re-run gate

### "MCP tool not available"
- Run `claude mcp add <tool> --scope local`
- See docs/MCP_MANAGEMENT.md

### "Task packet validation failed"
- Ensure all required fields present
- Check VERIFICATION commands are executable

---

**Last Updated**: 2026-01-05
**Version**: 1.0.0
**Skills**: 12
