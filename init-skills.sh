#!/bin/bash

# Council Skills Initialization Script
# This script sets up the skill-based workflow system for Claude Code

set -e  # Exit on error

echo "🏛️  Initializing Council Skills System..."
echo ""

# 1. Create directory structure
echo "📁 Creating directory structure..."
mkdir -p .claude/skills
mkdir -p progress
mkdir -p out
mkdir -p docs/skills

# 2. Initialize ledger files
echo "📝 Initializing ledger files..."
if [ ! -f progress/ledger.jsonl ]; then
    touch progress/ledger.jsonl
    echo "✅ Created progress/ledger.jsonl"
fi

if [ ! -f progress/NOTES.md ]; then
    cat > progress/NOTES.md <<'EOF'
# Task Notes

This file contains human-readable summaries of completed tasks.

---

EOF
    echo "✅ Created progress/NOTES.md"
fi

if [ ! -f progress/mcp-usage-log.jsonl ]; then
    touch progress/mcp-usage-log.jsonl
    echo "✅ Created progress/mcp-usage-log.jsonl"
fi

# 3. Create .gitignore if it doesn't exist
echo "🔒 Configuring .gitignore..."
if [ ! -f .gitignore ]; then
    cat > .gitignore <<'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Virtual environments
venv/
ENV/
env/

# IDEs
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Council Skills - Task artifacts (gitignored by default)
progress/TASK_PACKET.md
progress/ROUTE_DECISION.md
progress/CONSENSUS_DECISION.md
progress/CODEMAP.md
progress/ledger.jsonl
progress/NOTES.md
progress/mcp-usage-log.jsonl

# Council Skills - Outputs (gitignored)
out/

# Environment variables
.env
.env.local

# Logs
logs/
*.log

# Redis dump
dump.rdb
EOF
    echo "✅ Created .gitignore"
else
    echo "⚠️  .gitignore already exists; skipping"
fi

# 4. Verify skills exist
echo ""
echo "🔍 Verifying skills..."
SKILLS=(
    "plan-task-packet.md"
    "route-work.md"
    "consensus-stop.md"
    "codex-diagnose-ro.md"
    "codex-patch-rw.md"
    "gemini-file-io.md"
    "gemini-ui-docs-json.md"
    "qa-gate.md"
    "security-gate.md"
    "release-decision.md"
    "ledger-update.md"
    "codemap-refresh.md"
)

MISSING=0
for skill in "${SKILLS[@]}"; do
    if [ -f ".claude/skills/$skill" ]; then
        echo "  ✅ $skill"
    else
        echo "  ❌ $skill (MISSING)"
        MISSING=$((MISSING + 1))
    fi
done

echo ""
if [ $MISSING -gt 0 ]; then
    echo "⚠️  Warning: $MISSING skills are missing from .claude/skills/"
    echo "   Please ensure all skill files are present."
else
    echo "✅ All skills verified!"
fi

# 5. Check documentation
echo ""
echo "📚 Verifying documentation..."
DOCS=(
    "CONSTITUTION.md"
    "README.md"
    "docs/MCP_MANAGEMENT.md"
    "docs/WORKFLOW_EXAMPLES.md"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        echo "  ✅ $doc"
    else
        echo "  ⚠️  $doc (missing, but optional)"
    fi
done

# 6. Initialize sample CODEMAP (optional)
echo ""
read -p "📊 Generate initial CODEMAP? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "⏳ Generating CODEMAP (this may take a minute)..."
    echo "   Note: This requires Gemini Flash to be available"
    echo "   You can also run '/codemap-refresh' later in Claude Code"
    # Placeholder - actual generation would be done via Claude Code
    cat > progress/CODEMAP.md <<'EOF'
# Codebase Map

**Status**: Placeholder - run `/codemap-refresh` in Claude Code to generate

This file will contain a compressed representation of your codebase structure.

EOF
    echo "✅ Created placeholder CODEMAP.md"
    echo "   Run '/codemap-refresh' in Claude Code to generate actual map"
fi

# 7. Success message
echo ""
echo "✨ Initialization complete!"
echo ""
echo "📖 Next steps:"
echo "   1. Review CONSTITUTION.md to understand system principles"
echo "   2. Read docs/WORKFLOW_EXAMPLES.md for usage examples"
echo "   3. Start your first task with '/plan-task-packet'"
echo ""
echo "🚀 Happy coding with Council Skills!"
echo ""

# 8. Optional: Print quick reference
cat <<'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
QUICK REFERENCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Orchestration (Claude):
  /plan-task-packet      Create task specification
  /route-work            Select executor (codex/gemini/human)
  /consensus-stop        Limit agent debates to 3 rounds

Execution (Codex/Gemini):
  /codex-diagnose-ro     Read-only diagnosis
  /codex-patch-rw        Apply code changes
  /gemini-file-io        Efficient file operations
  /gemini-ui-docs-json   UI/design exploration

Guardians (QA/Security):
  /qa-gate               Run tests, linting, build
  /security-gate         Security audit
  /release-decision      Approve deployment

Memory (Secretary):
  /ledger-update         Record decisions & lessons
  /codemap-refresh       Update codebase map

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
