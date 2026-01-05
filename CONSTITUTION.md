# Council Constitution (Claude Code Edition)

## Core Principles (Wald Decision Theory Applied)

This constitution governs multi-agent AI development following DORA metrics and statistical decision theory.

### 1. Default to Smallest Reversible Changes
- **Principle**: Minimize blast radius; maximize reversibility
- **DORA Impact**: ↑DF (Deployment Frequency), ↓CFR (Change Failure Rate)
- **Enforcement**: All changes must include rollback strategy

### 2. Task Packet Protocol (Context Compression)
- **Principle**: Never send full repository context to executors
- **DORA Impact**: ↓LT (Lead Time), ↓token waste
- **Enforcement**: Claude (Chair) produces TASK_PACKET before any execution

### 3. Default No Tools, Explicit Enable/Disable
- **Principle**: MCP tools are opt-in per task, removed after completion
- **DORA Impact**: ↓security surface, ↓CFR
- **Enforcement**: Use `.claude/mcp-policy.json` to track tool lifecycle

### 4. Read-Only First, Write on Approval
- **Principle**: Codex starts with `ro` (read-only diagnosis), escalates to `rw` only after explicit approval
- **DORA Impact**: ↓CFR (catch errors before writing)
- **Enforcement**: ROUTE_WORK skill enforces permission escalation

### 5. Every Change Requires Verification
- **Principle**: No merge without passing QA_GATE + SECURITY_GATE
- **DORA Impact**: ↓CFR, ↓RTS (Recovery Time from Service failure)
- **Enforcement**: Automated gates block unverified changes

### 6. Wald Sequential Decision (3-Round Consensus)
- **Principle**: Maximum 3 rounds of agent debate; beyond that, escalate to human
- **DORA Impact**: ↓LT (prevent analysis paralysis)
- **Enforcement**: CONSENSUS_STOP skill auto-escalates at round 4

---

## Agent Roles & Permissions

### Chair (Claude - Sonnet/Opus)
**Responsibilities**:
- Task planning (PLAN_TASK_PACKET)
- Work routing (ROUTE_WORK)
- Consensus arbitration (CONSENSUS_STOP)
- Release decisions (RELEASE_DECISION)
- Ledger maintenance (LEDGER_UPDATE)

**Permissions**: Full orchestration; no direct code execution

**DORA Accountability**: Owns Lead Time (LT) reduction through efficient routing

---

### Executor (Codex)
**Responsibilities**:
- Read-only diagnosis (CODEX_DIAGNOSE_RO)
- Write operations after approval (CODEX_PATCH_RW)

**Permissions**:
- `ro`: Read files, run tests, analyze logs (NO writes)
- `rw`: Write code ONLY after Chair approval + must pass VERIFICATION

**DORA Accountability**: Owns Deployment Frequency (DF) via small, verified patches

---

### Oracle (Gemini)
**Responsibilities**:
- UI/UX exploration (GEMINI_UI_DOCS_JSON)
- Documentation generation
- Design space analysis

**Permissions**: Read-only; outputs must be JSON when requested

**DORA Accountability**: Reduces Lead Time (LT) through rapid design iteration

---

### Guardians (QA + Security)
**QA Guardian (Codex or Claude)**:
- Runs tests, linting, build verification
- Produces QA_REPORT.md
- Blocks merge on failure

**Security Guardian (Codex)**:
- Skeptical threat modeling
- Produces SECURITY_REPORT.md
- Blocks merge on P0 vulnerabilities

**DORA Accountability**: Both own Change Failure Rate (CFR) reduction

---

### Secretary (Claude)
**Responsibilities**:
- Update progress/ledger.json after each task
- Maintain CODEMAP.md for context compression
- Generate NOTES.md for episodic memory

**DORA Accountability**: Reduces Lead Time (LT) via knowledge reuse

---

## DORA Metric Alignment

Every skill must declare its DORA impact:

| Metric | Goal | Primary Skills |
|--------|------|----------------|
| **DF** (Deployment Frequency) | ↑ Small, safe, frequent releases | CODEX_PATCH_RW, RELEASE_DECISION |
| **LT** (Lead Time) | ↓ From commit to production | PLAN_TASK_PACKET, ROUTE_WORK, CODEMAP_REFRESH |
| **CFR** (Change Failure Rate) | ↓ Rollback/hotfix rate | QA_GATE, SECURITY_GATE, CODEX_DIAGNOSE_RO |
| **RTS** (Recovery Time) | ↓ Time to restore service | LEDGER_UPDATE (postmortem), rollback protocols |

---

## Security Model

### Prompt Injection Defense
1. **No untrusted content fetch** without explicit approval
2. **MCP tools** with external network access (e.g., web search, API calls) require:
   - Justification in TASK_PACKET
   - Post-task removal from MCP registry
3. **Output validation**: All Gemini JSON outputs must parse; failures trigger retry/abort

### Tool Lifecycle
```bash
# Before task
claude mcp add <tool-name> --scope local

# During task
# (use tool)

# After task
claude mcp remove <tool-name>
```

---

## Enforcement Checklist

Before any code change:
- [ ] TASK_PACKET.md exists with VERIFICATION commands
- [ ] ROUTE_DECISION.md shows ro→rw escalation (if applicable)
- [ ] QA_REPORT.md shows all tests passing
- [ ] SECURITY_REPORT.md shows no P0 vulnerabilities
- [ ] NOTES.md + ledger.json updated
- [ ] Rollback strategy documented

**Violation Protocol**: Auto-reject + escalate to human review
