#!/bin/bash

# Agent Deployment Script for ClaudeProjects2
# Deploys agents with proper category structure

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
AGENTS_DIR="$PROJECT_ROOT/agents"
CLAUDE_AGENTS_DIR="$HOME/.claude/agents"

echo "🚀 Deploying ClaudeProjects2 agents with structure..."

# Clean previous flat deployment (optional)
echo "🧹 Cleaning previous flat deployment..."
rm -f "$CLAUDE_AGENTS_DIR"/*.md

# Deploy with category structure
deployed_count=0
for category_dir in "$AGENTS_DIR"/*/; do
    if [ -d "$category_dir" ]; then
        category=$(basename "$category_dir")
        echo "📁 Processing category: $category"
        
        # Create category directory
        mkdir -p "$CLAUDE_AGENTS_DIR/$category"
        
        # Deploy agents in this category
        for agent_file in "$category_dir"*.md; do
            if [ -f "$agent_file" ]; then
                agent_name=$(basename "$agent_file" .md)
                echo "  📦 Deploying $category/$agent_name..."
                cp "$agent_file" "$CLAUDE_AGENTS_DIR/$category/"
                deployed_count=$((deployed_count + 1))
            fi
        done
    fi
done

echo "✅ Successfully deployed $deployed_count agents with structure!"
echo ""
echo "Deployed structure:"
tree -L 2 "$CLAUDE_AGENTS_DIR" 2>/dev/null || ls -la "$CLAUDE_AGENTS_DIR"

echo ""
echo "You can now use these agents with proper categorization!"
echo "Example: core/orchestrator-agent, domain/project-agent, etc."