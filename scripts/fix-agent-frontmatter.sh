#!/bin/bash

# Fix agent YAML frontmatter to match Claude Code requirements
# Converts array tools to comma-separated and removes extra fields

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔧 Fixing agent frontmatter for Claude Code compatibility..."

# Process all agent files in .claude/agents/
for agent_file in "$PROJECT_ROOT"/.claude/agents/*.md; do
    if [ -f "$agent_file" ]; then
        agent_name=$(basename "$agent_file")
        echo "  Processing $agent_name..."
        
        # Create temp file
        temp_file="${agent_file}.tmp"
        
        # Extract and fix frontmatter
        awk '
        BEGIN { in_fm = 0; fm_count = 0 }
        /^---$/ { 
            fm_count++
            if (fm_count == 1) {
                in_fm = 1
                print "---"
                next
            } else if (fm_count == 2) {
                in_fm = 0
                print "---"
                next
            }
        }
        in_fm && /^name:/ { print; next }
        in_fm && /^description:/ { print; next }
        in_fm && /^tools:/ { 
            # Skip for now - will be replaced with default tools
            next
        }
        in_fm && /^(category|version|status):/ { 
            # Skip these fields
            next
        }
        !in_fm { print }
        ' "$agent_file" > "$temp_file"
        
        # Insert default tools line after description
        awk '
        /^description:/ { 
            print
            print "tools: Read, Edit, Grep, Bash, Task, TodoWrite"
            next
        }
        { print }
        ' "$temp_file" > "${temp_file}.2"
        
        # Move back to original
        mv "${temp_file}.2" "$agent_file"
        rm -f "$temp_file"
    fi
done

echo "✅ Fixed frontmatter for all agents"
echo ""
echo "Changes made:"
echo "  • Removed category, version, status fields"
echo "  • Set standard tools: Read, Edit, Grep, Bash, Task, TodoWrite"
echo "  • Kept only name and description as required"
echo ""
echo "Please restart Claude Code to reload agents"