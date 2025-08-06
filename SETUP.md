# ClaudeProjects2 Setup Guide

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/sdh07/ClaudeProjects2.git
   cd ClaudeProjects2
   ```

2. **Install Git Hooks (Recommended)**
   ```bash
   ./scripts/install-git-hooks.sh
   ```
   
   This sets up automatic agent deployment when you commit changes.

3. **Deploy agents for Claude Code**
   ```bash
   ./scripts/deploy-agents.sh
   ```
   
   This will:
   - Create `.claude/agents` as a symlink to `/agents/` (on Mac/Linux)
   - Or copy agents if symlinks aren't available (Windows without admin)
   - Make all 19 project agents available in Claude Code
   - With git hooks installed, this happens automatically on commits!

4. **Restart Claude Code**
   - Exit Claude Code if running
   - Start Claude Code in the project directory
   - Verify agents with `/agents` command

## Platform-Specific Notes

### macOS/Linux
- Symlinks work automatically
- Changes to agents are instantly available
- No re-deployment needed after edits

### Windows
For best experience, enable symlinks:

**Option 1: Developer Mode**
- Settings → Update & Security → For Developers
- Enable "Developer Mode"
- Run deployment script normally

**Option 2: Run as Admin**
- Right-click Git Bash
- "Run as Administrator"
- Run deployment script

**Option 3: Use WSL**
- Install Windows Subsystem for Linux
- Run deployment from WSL terminal

**Fallback: Copy Mode**
- If symlinks don't work, agents are copied
- Re-run `./scripts/deploy-agents.sh` after agent changes

### Git Configuration (Windows)
```bash
git config core.symlinks true
```

## Verify Installation

After deployment, check that agents are available:
```bash
# In Claude Code
/agents
```

You should see 17 project agents:
- Core: orchestrator, context, methodology, self-improvement
- Architecture: logical-architect, physical-architect
- Domain: project, vision
- Quality: quality, trace
- Delivery: build, code-review, issue, test
- And more...

## Troubleshooting

**Agents not showing?**
- Ensure you ran the deployment script
- Restart Claude Code
- Check `.claude/agents` exists

**Permission errors on Windows?**
- Enable Developer Mode or run as Admin
- Or use the copy fallback (works without special permissions)

**Changes not reflected?**
- If using copy mode (Windows), re-run deployment script
- If using symlinks, changes should be instant

## For Developers

When modifying agents:
1. Edit agents in `/agents/` directory
2. If using symlinks: changes are immediate
3. If using copies: run `./scripts/deploy-agents.sh` again
4. Test with Claude Code

The deployment script is cross-platform and handles all edge cases automatically.