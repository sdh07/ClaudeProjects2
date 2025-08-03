#!/bin/bash
# CLAUDE.md Maintenance Script
# Run this script to validate and update CLAUDE.md

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}CLAUDE.md Maintenance Tool${NC}"
echo "=========================="

# Check if CLAUDE.md exists
if [ ! -f "CLAUDE.md" ]; then
    echo -e "${RED}Error: CLAUDE.md not found in current directory${NC}"
    exit 1
fi

# Check file size
line_count=$(wc -l < CLAUDE.md)
echo -e "\n📏 Size Check:"
if [ $line_count -gt 500 ]; then
    echo -e "${YELLOW}Warning: CLAUDE.md has $line_count lines (recommended: < 500)${NC}"
    echo "Consider extracting sections to imported files"
else
    echo -e "${GREEN}✓ File size OK: $line_count lines${NC}"
fi

# Check for outdated sprint info
echo -e "\n📅 Sprint Context Check:"
if grep -q "Sprint 1:" CLAUDE.md; then
    echo -e "${YELLOW}Note: Sprint 1 context found - update if sprint has changed${NC}"
fi

# Validate imports
echo -e "\n🔗 Import Validation:"
imports=$(grep "^@" CLAUDE.md || true)
if [ -n "$imports" ]; then
    while IFS= read -r import; do
        file_path=${import:1} # Remove @ prefix
        if [ -f "$file_path" ]; then
            echo -e "${GREEN}✓ $import${NC}"
        else
            echo -e "${RED}✗ $import (file not found)${NC}"
        fi
    done <<< "$imports"
else
    echo "No imports found"
fi

# Check for common patterns
echo -e "\n🔍 Pattern Check:"

# Check for actionable directives
directive_count=$(grep -E "^- " CLAUDE.md | wc -l)
echo "Actionable directives found: $directive_count"

# Check for outdated commands
if grep -q "npm run dev" CLAUDE.md && [ ! -f "package.json" ]; then
    echo -e "${YELLOW}Warning: npm commands found but no package.json${NC}"
fi

# Generate update suggestions
echo -e "\n💡 Update Suggestions:"

# Check last git commit
last_commit=$(git log -1 --pretty=format:"%h - %s" 2>/dev/null || echo "No git history")
echo "Last commit: $last_commit"

# Suggest adding recent ADRs
recent_adrs=$(find docs/architecture/decisions -name "ADR-*.md" -mtime -7 2>/dev/null | head -3)
if [ -n "$recent_adrs" ]; then
    echo -e "\nRecent ADRs to consider importing:"
    echo "$recent_adrs" | while read adr; do
        echo "  @$adr"
    done
fi

# Token estimation
char_count=$(wc -c < CLAUDE.md)
estimated_tokens=$((char_count / 4))
echo -e "\n📊 Token Usage Estimate: ~$estimated_tokens tokens"

# Maintenance actions
echo -e "\n🛠️  Maintenance Actions:"
echo "1. Run 'markdownlint CLAUDE.md' to check syntax"
echo "2. Review and update sprint context"
echo "3. Remove completed task references"
echo "4. Update agent registry with new agents"
echo "5. Refresh command list if changed"

# Archive suggestion
days_old=$(find CLAUDE.md -mtime +30 | wc -l)
if [ $days_old -gt 0 ]; then
    echo -e "\n${YELLOW}Consider archiving old content - CLAUDE.md is over 30 days old${NC}"
fi

echo -e "\n${GREEN}Maintenance check complete!${NC}"