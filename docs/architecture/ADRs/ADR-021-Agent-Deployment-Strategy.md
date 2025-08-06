# ADR-021: Agent Deployment Strategy

## Status
Proposed

## Context
During Sprint 6 Day 1, we discovered that our agents in `/agents/` are not actually accessible to Claude Code because they're not deployed to the proper location (`~/.claude/agents/`). Claude Code uses the Task tool to invoke sub-agents, but can only see agents in specific directories.

This is a **critical architectural gap** - we've been developing agents that aren't actually being used!

## Decision
We will implement automatic agent deployment using git hooks to copy agents from our repository to Claude Code's agent directories whenever changes are committed.

## Consequences

### Positive
- Agents immediately available to Claude Code after commit
- Version control through git history
- Simple implementation (file copy operations)
- No external dependencies
- Rollback capability through git

### Negative
- Requires manual initial setup of git hooks
- Each developer needs local deployment
- No centralized agent registry (yet)

## Implementation
1. **Immediate Fix** (TODAY):
   ```bash
   # Deploy all current agents NOW
   cp -r agents/* ~/.claude/agents/
   ```

2. **Automated Deployment**:
   - Git post-commit hook
   - Deployment script
   - Version tracking

3. **Documentation Update**:
   - Update physical architecture docs
   - Add to developer setup guide
   - Update CLAUDE.md

## Lessons Learned
- **Architecture knowledge gap**: Our physical-architect-agent should have known about Claude Code's Task tool and agent deployment requirements
- **Testing gap**: We haven't been testing with actual Claude Code Task tool invocations
- **Documentation gap**: This critical detail wasn't in our architecture docs

## Related
- ADR-001: Agent-Based Architecture
- Claude Code Sub-Agents Integration spec
- Sprint 6 CPDM Test Drive

---
*Date: 2025-08-06*
*Author: System Architect*
*Sprint: 6*