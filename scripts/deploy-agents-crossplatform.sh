#!/bin/bash

# Cross-platform agent deployment script
# Works on macOS, Linux, and Windows (Git Bash/WSL)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
AGENTS_SOURCE_DIR="$PROJECT_ROOT/agents"
PROJECT_AGENTS_DIR="$PROJECT_ROOT/.claude/agents"

echo "🚀 Deploying agents (cross-platform)..."

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    OS="windows"
fi

echo "🖥️  Detected OS: $OS"

# Clean existing deployment
rm -rf "$PROJECT_AGENTS_DIR"

# Option 1: Try symlink first (best performance)
if ln -s "$AGENTS_SOURCE_DIR" "$PROJECT_AGENTS_DIR" 2>/dev/null; then
    echo "✅ Created symbolic link to agents folder"
    echo "🔗 .claude/agents -> agents/"
    
# Option 2: Fall back to copying (Windows without symlink support)
else
    echo "⚠️  Symbolic links not available, copying files instead..."
    mkdir -p "$PROJECT_AGENTS_DIR"
    
    # Copy all agents preserving structure
    cp -r "$AGENTS_SOURCE_DIR"/* "$PROJECT_AGENTS_DIR/"
    
    echo "✅ Copied agents to .claude/agents/"
    echo "⚠️  Note: Changes to source won't auto-sync. Re-run this script after changes."
fi

# Verify deployment
agent_count=$(find "$PROJECT_AGENTS_DIR" -name "*.md" -type f 2>/dev/null | wc -l)
echo ""
echo "📊 Deployed $agent_count agents"
echo ""

# Platform-specific instructions
if [[ "$OS" == "windows" ]]; then
    echo "📝 Windows users:"
    echo "  • If symlinks don't work, enable Developer Mode in Windows Settings"
    echo "  • Or run Git Bash as Administrator"
    echo "  • Or use WSL (Windows Subsystem for Linux)"
    echo "  • Files were copied as fallback - re-run after agent changes"
fi

echo ""
echo "✨ Deployment complete!"