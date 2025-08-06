#!/bin/bash

# Install git hooks for ClaudeProjects2
# This script sets up automatic agent deployment on commit/merge

echo "🔧 Installing ClaudeProjects2 Git Hooks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Create post-commit hook
cat > "$HOOKS_DIR/post-commit" << 'EOF'
#!/bin/bash
# Post-commit hook for ClaudeProjects2
# Automatically deploys agents when changes are detected

# Get the list of changed files in the last commit
CHANGED_FILES=$(git diff-tree --no-commit-id --name-only -r HEAD)

# Check if any agent files were modified
AGENT_CHANGED=false
CLAUDE_MD_CHANGED=false

for file in $CHANGED_FILES; do
    if [[ $file == agents/*.md ]]; then
        AGENT_CHANGED=true
    fi
    if [[ $file == "CLAUDE.md" ]]; then
        CLAUDE_MD_CHANGED=true
    fi
done

# If agents were changed, run deployment
if [ "$AGENT_CHANGED" = true ]; then
    echo "🔄 Agent changes detected in commit"
    
    # Check if deployment script exists
    if [ -f "./scripts/deploy-agents.sh" ]; then
        echo "🚀 Running agent deployment..."
        ./scripts/deploy-agents.sh
        
        if [ $? -eq 0 ]; then
            echo "✅ Agents deployed successfully"
            echo "⚠️  Remember to restart Claude Code to load new agents"
        else
            echo "❌ Agent deployment failed"
        fi
    else
        echo "⚠️  Deployment script not found at ./scripts/deploy-agents.sh"
    fi
fi

# If CLAUDE.md was changed, notify about restart
if [ "$CLAUDE_MD_CHANGED" = true ]; then
    echo "📝 CLAUDE.md updated - restart Claude Code to apply orchestration changes"
fi

# Log the hook execution
echo "[$(date)] Post-commit hook executed for commit $(git rev-parse HEAD)" >> .git/hooks/hook.log
EOF

# Create post-merge hook
cat > "$HOOKS_DIR/post-merge" << 'EOF'
#!/bin/bash
# Post-merge hook for ClaudeProjects2
# Automatically deploys agents after pulling changes

# Get the list of changed files in the merge
CHANGED_FILES=$(git diff-tree --no-commit-id --name-only -r ORIG_HEAD HEAD)

# Check if any agent files were modified
AGENT_CHANGED=false
CLAUDE_MD_CHANGED=false

for file in $CHANGED_FILES; do
    if [[ $file == agents/*.md ]]; then
        AGENT_CHANGED=true
    fi
    if [[ $file == "CLAUDE.md" ]]; then
        CLAUDE_MD_CHANGED=true
    fi
done

# If agents were changed, run deployment
if [ "$AGENT_CHANGED" = true ]; then
    echo "🔄 Agent changes detected after merge"
    
    # Check if deployment script exists
    if [ -f "./scripts/deploy-agents.sh" ]; then
        echo "🚀 Running agent deployment..."
        ./scripts/deploy-agents.sh
        
        if [ $? -eq 0 ]; then
            echo "✅ Agents deployed successfully"
            echo "⚠️  Remember to restart Claude Code to load updated agents"
        else
            echo "❌ Agent deployment failed"
        fi
    else
        echo "⚠️  Deployment script not found at ./scripts/deploy-agents.sh"
    fi
fi

# If CLAUDE.md was changed, notify about restart
if [ "$CLAUDE_MD_CHANGED" = true ]; then
    echo "📝 CLAUDE.md updated - restart Claude Code to apply orchestration changes"
fi

# Log the hook execution
echo "[$(date)] Post-merge hook executed" >> .git/hooks/hook.log
EOF

# Make hooks executable
chmod +x "$HOOKS_DIR/post-commit"
chmod +x "$HOOKS_DIR/post-merge"

echo "✅ Git hooks installed successfully!"
echo ""
echo "📋 Hooks installed:"
echo "   • post-commit: Auto-deploys agents after commits"
echo "   • post-merge: Auto-deploys agents after pulls"
echo ""
echo "🔄 How it works:"
echo "   1. When you commit changes to agents/*.md files"
echo "   2. The hook automatically runs deploy-agents.sh"
echo "   3. Agents are deployed to .claude/agents/"
echo "   4. You get a reminder to restart Claude Code"
echo ""
echo "📝 Note: Hooks are local to your repository."
echo "   Other developers should run this script too."