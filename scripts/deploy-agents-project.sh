#!/bin/bash

# Agent Deployment Script for ClaudeProjects2
# Deploys agents to PROJECT-LEVEL .claude/agents/ directory
# This ensures agents are part of the project and can be committed to git

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
AGENTS_SOURCE_DIR="$PROJECT_ROOT/agents"
PROJECT_AGENTS_DIR="$PROJECT_ROOT/.claude/agents"

echo "🚀 Deploying ClaudeProjects2 agents to PROJECT level..."
echo "   Source: $AGENTS_SOURCE_DIR"
echo "   Target: $PROJECT_AGENTS_DIR"

# Create project agents directory
mkdir -p "$PROJECT_AGENTS_DIR"

# Deploy with category structure preserved
deployed_count=0
for category_dir in "$AGENTS_SOURCE_DIR"/*/; do
    if [ -d "$category_dir" ]; then
        category=$(basename "$category_dir")
        echo "📁 Processing category: $category"
        
        # Create category directory in project
        mkdir -p "$PROJECT_AGENTS_DIR/$category"
        
        # Deploy agents in this category
        for agent_file in "$category_dir"*.md; do
            if [ -f "$agent_file" ]; then
                agent_name=$(basename "$agent_file" .md)
                echo "  📦 Deploying $category/$agent_name..."
                cp "$agent_file" "$PROJECT_AGENTS_DIR/$category/"
                deployed_count=$((deployed_count + 1))
            fi
        done
    fi
done

echo ""
echo "✅ Successfully deployed $deployed_count agents to PROJECT level!"
echo ""
echo "📍 Location: .claude/agents/"
echo "🔑 Priority: Project agents override user-level agents"
echo "🌟 Git-friendly: Can be committed and shared with team"
echo ""
echo "Deployed structure:"
tree -L 2 "$PROJECT_AGENTS_DIR" 2>/dev/null || find "$PROJECT_AGENTS_DIR" -type f -name "*.md" | sed 's|.*/||' | sort

echo ""
echo "✨ Benefits of project-level deployment:"
echo "  • Agents are part of the project (git-tracked)"
echo "  • Team members get agents automatically"
echo "  • Project-specific customizations"
echo "  • Override global agents when needed"