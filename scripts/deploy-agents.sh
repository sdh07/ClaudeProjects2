#!/bin/bash

# Universal agent deployment script for ClaudeProjects2
# Hybrid approach: Symlink on Unix-like systems, copy on Windows without symlink support

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
AGENTS_SOURCE_DIR="$PROJECT_ROOT/agents"
PROJECT_AGENTS_DIR="$PROJECT_ROOT/.claude/agents"

echo "🚀 ClaudeProjects2 Agent Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
echo "🖥️  Operating System: $OS"

# Clean existing deployment
if [ -e "$PROJECT_AGENTS_DIR" ]; then
    echo "🧹 Cleaning existing deployment..."
    rm -rf "$PROJECT_AGENTS_DIR"
fi

# Create .claude directory if it doesn't exist
mkdir -p "$(dirname "$PROJECT_AGENTS_DIR")"

# Try to create symbolic link (preferred method)
echo ""
echo "📂 Attempting symbolic link deployment..."

if ln -s ../agents "$PROJECT_AGENTS_DIR" 2>/dev/null; then
    echo "✅ SUCCESS: Created symbolic link"
    echo "   .claude/agents → agents/"
    DEPLOYMENT_TYPE="symlink"
    
elif [[ "$OS" == "windows" ]]; then
    # Windows: Try with mklink if available
    echo "🪟 Windows detected, trying mklink..."
    
    # Convert paths for Windows
    WIN_SOURCE=$(cygpath -w "$AGENTS_SOURCE_DIR" 2>/dev/null || echo "$AGENTS_SOURCE_DIR")
    WIN_TARGET=$(cygpath -w "$PROJECT_AGENTS_DIR" 2>/dev/null || echo "$PROJECT_AGENTS_DIR")
    
    if cmd.exe /c "mklink /D \"$WIN_TARGET\" \"$WIN_SOURCE\"" 2>/dev/null; then
        echo "✅ SUCCESS: Created symbolic link using mklink"
        DEPLOYMENT_TYPE="symlink"
    else
        echo "⚠️  Symbolic link failed (need admin rights or Developer Mode)"
        DEPLOYMENT_TYPE="copy"
    fi
else
    echo "⚠️  Symbolic link not supported"
    DEPLOYMENT_TYPE="copy"
fi

# Fallback to copying
if [[ "$DEPLOYMENT_TYPE" == "copy" ]]; then
    echo ""
    echo "📋 Using copy deployment (fallback)..."
    cp -r "$AGENTS_SOURCE_DIR" "$PROJECT_AGENTS_DIR"
    echo "✅ Copied all agents to .claude/agents/"
    echo ""
    echo "⚠️  IMPORTANT: Files are copied, not linked!"
    echo "   Re-run this script after making changes to agents/"
fi

# Verify deployment
echo ""
echo "📊 Verification"
echo "━━━━━━━━━━━━━━"

if [ -d "$PROJECT_AGENTS_DIR" ]; then
    # Use -L to follow symlinks
    agent_count=$(find -L "$PROJECT_AGENTS_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "✅ Agents deployed: $agent_count"
    echo "📍 Location: .claude/agents/"
    echo "🔗 Type: $DEPLOYMENT_TYPE"
else
    echo "❌ Deployment failed!"
    exit 1
fi

# Platform-specific instructions
echo ""
echo "📝 Platform Notes"
echo "━━━━━━━━━━━━━━━━"

if [[ "$OS" == "windows" && "$DEPLOYMENT_TYPE" == "copy" ]]; then
    echo "🪟 Windows - Using Copy Mode"
    echo ""
    echo "To enable symbolic links on Windows:"
    echo "  1. Enable Developer Mode in Settings, OR"
    echo "  2. Run Git Bash as Administrator, OR"
    echo "  3. Use WSL (Windows Subsystem for Linux)"
    echo ""
    echo "Then re-run this script for better performance."
elif [[ "$DEPLOYMENT_TYPE" == "symlink" ]]; then
    echo "🔗 Using Symbolic Links"
    echo ""
    echo "Benefits:"
    echo "  • Changes to agents are instantly available"
    echo "  • No need to re-deploy after edits"
    echo "  • Single source of truth"
fi

# Git configuration reminder
if [[ "$OS" == "windows" ]]; then
    echo ""
    echo "🔧 Git Configuration for Windows:"
    echo "   git config core.symlinks true"
fi

echo ""
echo "✨ Deployment complete! Restart Claude Code to use agents."