#!/bin/bash

# Fix agent YAML frontmatter in source /agents/ directory
# Updates to match Claude Code requirements

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
AGENTS_DIR="$PROJECT_ROOT/agents"

echo "🔧 Fixing source agent frontmatter for Claude Code compatibility..."

# Process all agent files in source directories
for agent_file in "$AGENTS_DIR"/*/*.md; do
    if [ -f "$agent_file" ]; then
        agent_name=$(basename "$agent_file" .md)
        echo "  Processing $agent_name..."
        
        # Extract current description
        description=$(grep "^description:" "$agent_file" 2>/dev/null | head -1 | cut -d: -f2- | xargs)
        if [ -z "$description" ]; then
            # If no description, try to get from Purpose section
            description="Specialized agent for ClaudeProjects2"
        fi
        
        # Create temp file with fixed frontmatter
        temp_file="${agent_file}.tmp"
        
        # Write new frontmatter
        cat > "$temp_file" << EOF
---
name: $agent_name
description: $description
tools: Read, Edit, Grep, Bash, Task, TodoWrite
---
EOF
        
        # Append content after original frontmatter
        awk '
        BEGIN { in_fm = 0; fm_count = 0 }
        /^---$/ { 
            fm_count++
            if (fm_count == 2) {
                in_fm = 0
                in_content = 1
                next
            }
        }
        in_content { print }
        ' "$agent_file" >> "$temp_file"
        
        # Replace original file
        mv "$temp_file" "$agent_file"
    fi
done

echo "✅ Fixed frontmatter for all source agents"
echo ""
echo "Changes made:"
echo "  • Simplified to name, description, tools only"
echo "  • Tools as comma-separated string"
echo "  • Removed category, version, status fields"