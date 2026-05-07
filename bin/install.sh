#!/bin/bash
# Marlo AI Installation Script
# Copies Marlo AI files to Claude Code configuration directory

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
CLAUDE_CONFIG_DIR="$HOME/.claude"
MARLO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${YELLOW}Marlo AI Installation${NC}"
echo "======================"
echo ""
echo "Source: $MARLO_DIR"
echo "Destination: $CLAUDE_CONFIG_DIR"
echo ""

# Check if Marlo directory exists
if [ ! -d "$MARLO_DIR" ]; then
    echo -e "${RED}Error: Marlo AI directory not found at $MARLO_DIR${NC}"
    exit 1
fi

# Create Claude Config directories if they don't exist
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p "$CLAUDE_CONFIG_DIR/skills/project-manager"
mkdir -p "$CLAUDE_CONFIG_DIR/agents"
mkdir -p "$CLAUDE_CONFIG_DIR/bin"

# Copy files
echo -e "${YELLOW}Copying files...${NC}"

# Copy PM skill
if [ -f "$MARLO_DIR/skills/project-manager/SKILL.md" ]; then
    cp "$MARLO_DIR/skills/project-manager/SKILL.md" "$CLAUDE_CONFIG_DIR/skills/project-manager/"
    echo -e "${GREEN}✓${NC} PM Skill installed"
else
    echo -e "${RED}✗${NC} PM Skill not found"
    exit 1
fi

# Copy agents (all .md files)
agent_count=0
for agent_file in "$MARLO_DIR/agents"/*.md; do
    if [ -f "$agent_file" ]; then
        agent_name=$(basename "$agent_file")
        cp "$agent_file" "$CLAUDE_CONFIG_DIR/agents/"
        echo -e "${GREEN}✓${NC} Agent: $agent_name"
        ((agent_count++))
    fi
done

if [ $agent_count -ne 8 ]; then
    echo -e "${YELLOW}Warning: Expected 8 agents, found $agent_count${NC}"
fi

# Copy helper scripts
if [ -f "$MARLO_DIR/bin/check-frontmatter.sh" ]; then
    cp "$MARLO_DIR/bin/check-frontmatter.sh" "$CLAUDE_CONFIG_DIR/bin/"
    chmod +x "$CLAUDE_CONFIG_DIR/bin/check-frontmatter.sh"
    echo -e "${GREEN}✓${NC} Helper: check-frontmatter.sh"
fi

if [ -f "$MARLO_DIR/bin/validate-phase-report.sh" ]; then
    cp "$MARLO_DIR/bin/validate-phase-report.sh" "$CLAUDE_CONFIG_DIR/bin/"
    chmod +x "$CLAUDE_CONFIG_DIR/bin/validate-phase-report.sh"
    echo -e "${GREEN}✓${NC} Helper: validate-phase-report.sh"
fi

echo ""
echo -e "${YELLOW}Verifying installation...${NC}"

# Verify PM skill
if [ -f "$CLAUDE_CONFIG_DIR/skills/project-manager/SKILL.md" ]; then
    echo -e "${GREEN}✓${NC} PM Skill: installed"
else
    echo -e "${RED}✗${NC} PM Skill: missing"
    exit 1
fi

# Verify agents
agent_count=$(ls "$CLAUDE_CONFIG_DIR/agents"/*.md 2>/dev/null | wc -l)
if [ $agent_count -eq 8 ]; then
    echo -e "${GREEN}✓${NC} Agents: all 8 installed"
elif [ $agent_count -gt 0 ]; then
    echo -e "${YELLOW}⚠${NC} Agents: only $agent_count/8 installed"
else
    echo -e "${RED}✗${NC} Agents: missing"
    exit 1
fi

# Verify helpers
if [ -f "$CLAUDE_CONFIG_DIR/bin/check-frontmatter.sh" ]; then
    echo -e "${GREEN}✓${NC} Helpers: check-frontmatter.sh installed"
fi

if [ -f "$CLAUDE_CONFIG_DIR/bin/validate-phase-report.sh" ]; then
    echo -e "${GREEN}✓${NC} Helpers: validate-phase-report.sh installed"
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Restart Claude Code completely (close and reopen)"
echo "2. Try /project-manager command in Claude Code"
echo "3. Read QUICK_START.md for your first project"
echo ""
echo "Full documentation:"
echo "- README.md — Overview and architecture"
echo "- QUICK_START.md — 5-minute walkthrough"
echo "- SECURITY_RULES.md — Non-negotiable rules"
echo "- TROUBLESHOOTING.md — Common issues"
echo ""
