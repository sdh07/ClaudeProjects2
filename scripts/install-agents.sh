#!/bin/bash
# ClaudeProjects Agent Installation Script

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
AGENT_SOURCE_DIR="$(dirname "$0")/../agents"
CLAUDE_AGENT_DIR="$HOME/.claude/agents"
BACKUP_DIR="$HOME/.claude/agents.backup.$(date +%Y%m%d_%H%M%S)"

echo -e "${BLUE}ClaudeProjects Agent Installer${NC}"
echo "================================"

# Check if source directory exists
if [ ! -d "$AGENT_SOURCE_DIR" ]; then
    echo -e "${RED}Error: Agent source directory not found at $AGENT_SOURCE_DIR${NC}"
    exit 1
fi

# Create Claude agents directory if it doesn't exist
if [ ! -d "$CLAUDE_AGENT_DIR" ]; then
    echo -e "${YELLOW}Creating Claude agents directory...${NC}"
    mkdir -p "$CLAUDE_AGENT_DIR"
fi

# Backup existing agents
if [ "$(ls -A $CLAUDE_AGENT_DIR 2>/dev/null)" ]; then
    echo -e "${YELLOW}Backing up existing agents to $BACKUP_DIR${NC}"
    mkdir -p "$BACKUP_DIR"
    cp -r "$CLAUDE_AGENT_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
fi

# Count agents to install
AGENT_COUNT=$(find "$AGENT_SOURCE_DIR" -name "*.md" -type f | wc -l)
echo -e "${BLUE}Found $AGENT_COUNT agents to install${NC}"

# Install agents
echo -e "${GREEN}Installing agents...${NC}"
cp -r "$AGENT_SOURCE_DIR"/* "$CLAUDE_AGENT_DIR/"

# Verify installation
INSTALLED_COUNT=$(find "$CLAUDE_AGENT_DIR" -name "*.md" -type f | wc -l)

if [ $INSTALLED_COUNT -ge $AGENT_COUNT ]; then
    echo -e "${GREEN}✓ Successfully installed $AGENT_COUNT agents${NC}"
else
    echo -e "${RED}✗ Installation may be incomplete. Expected $AGENT_COUNT agents, found $INSTALLED_COUNT${NC}"
fi

# List installed agents by category
echo ""
echo -e "${BLUE}Installed Agents by Category:${NC}"
echo "=============================="

for category in "$CLAUDE_AGENT_DIR"/*; do
    if [ -d "$category" ]; then
        category_name=$(basename "$category")
        echo -e "\n${YELLOW}$category_name:${NC}"
        for agent in "$category"/*.md; do
            if [ -f "$agent" ]; then
                agent_name=$(basename "$agent" .md)
                echo "  - $agent_name"
            fi
        done
    fi
done

# Show root level agents if any
root_agents=$(find "$CLAUDE_AGENT_DIR" -maxdepth 1 -name "*.md" -type f)
if [ -n "$root_agents" ]; then
    echo -e "\n${YELLOW}Root level agents:${NC}"
    for agent in $root_agents; do
        agent_name=$(basename "$agent" .md)
        echo "  - $agent_name"
    done
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "To use an agent, simply mention it in your Claude Code prompt:"
echo "  Example: 'Use the architecture-designer agent to create a system design'"
echo ""
echo "For more information, see: docs/specs/Agent-Markdown-Specification.md"