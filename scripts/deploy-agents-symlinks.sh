#!/bin/bash

# Deploy agents using symbolic links instead of copies
# This keeps .claude/agents/ in sync with source automatically

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
AGENTS_SOURCE_DIR="$PROJECT_ROOT/agents"
PROJECT_AGENTS_DIR="$PROJECT_ROOT/.claude/agents"

echo "🔗 Deploying agents using symbolic links..."
echo "   Source: $AGENTS_SOURCE_DIR"
echo "   Target: $PROJECT_AGENTS_DIR"

# Clean existing deployment
rm -rf "$PROJECT_AGENTS_DIR"
mkdir -p "$PROJECT_AGENTS_DIR"

# Create symbolic links with folder structure
deployed_count=0
for category_dir in "$AGENTS_SOURCE_DIR"/*/; do
    if [ -d "$category_dir" ]; then
        category=$(basename "$category_dir")
        
        # Check if category has any .md files
        if ls "$category_dir"*.md 1> /dev/null 2>&1; then
            echo "📁 Linking category: $category"
            
            # Create category directory
            mkdir -p "$PROJECT_AGENTS_DIR/$category"
            
            # Create symbolic links for agents in this category
            for agent_file in "$category_dir"*.md; do
                if [ -f "$agent_file" ]; then
                    agent_name=$(basename "$agent_file")
                    # Create relative symlink for portability
                    ln -sf "../../../agents/$category/$agent_name" "$PROJECT_AGENTS_DIR/$category/$agent_name"
                    echo "  🔗 Linked $category/$agent_name"
                    deployed_count=$((deployed_count + 1))
                fi
            done
        fi
    fi
done

echo ""
echo "✅ Successfully linked $deployed_count agents!"
echo ""
echo "📍 Location: .claude/agents/"
echo "🔗 Using symbolic links - changes to source automatically reflected"
echo "🌟 Git-friendly: Can commit symlinks for team consistency"
echo ""

# Show structure
echo "Deployed structure:"
if command -v tree > /dev/null; then
    tree -L 2 "$PROJECT_AGENTS_DIR"
else
    find "$PROJECT_AGENTS_DIR" -type l | sed 's|^.*/\.claude/agents/||' | sort
fi

echo ""
echo "✨ Benefits of symlink deployment:"
echo "  • No duplication - single source of truth"
echo "  • Instant updates - edit source, Claude Code sees it"
echo "  • Git-friendly - symlinks can be committed"
echo "  • Clean structure - preserves categories"