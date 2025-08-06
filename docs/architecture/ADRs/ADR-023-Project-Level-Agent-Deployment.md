# ADR-023: Project-Level Agent Deployment Strategy

## Status
Accepted

## Context
Research revealed that Claude Code supports two agent locations:
1. **User-level**: `~/.claude/agents/` - Available across all projects
2. **Project-level**: `.claude/agents/` - Project-specific agents

Project-level agents take **precedence** over user-level agents when names conflict.

## Decision
Deploy all ClaudeProjects2 agents to **project-level** `.claude/agents/` directory with category structure preserved.

## Rationale
1. **Git Integration**: Agents become part of the project repository
2. **Team Sharing**: All team members get agents automatically via git
3. **Project Specificity**: Our agents are tailored for ClaudeProjects2 methodology
4. **Version Control**: Agent changes tracked with project evolution
5. **Override Capability**: Can override any global agents if needed

## Implementation
```
ClaudeProjects2/
├── .claude/
│   ├── agents/          # Project-level agents
│   │   ├── core/
│   │   │   ├── orchestrator-agent.md
│   │   │   └── context-agent.md
│   │   ├── domain/
│   │   │   └── project-agent.md
│   │   └── ...
│   └── settings.local.json
├── agents/              # Source agents (development)
│   ├── core/
│   └── ...
```

## Deployment Flow
```mermaid
graph LR
    A[/agents/ source] -->|deploy script| B[/.claude/agents/]
    B -->|git commit| C[Repository]
    C -->|git clone| D[Team Members]
    D -->|automatic| E[Claude Code Access]
```

## Consequences

### Positive
- ✅ Agents are version-controlled with project
- ✅ Team gets consistent agent experience
- ✅ No manual installation for team members
- ✅ Category structure preserved
- ✅ Project-specific customizations possible

### Negative
- ⚠️ Larger repository size (minimal impact)
- ⚠️ Need to sync changes from `/agents/` to `/.claude/agents/`

## Migration
1. ✅ Created `.claude/agents/` directory structure
2. ✅ Deployed all 17 agents with categories
3. ✅ Created `deploy-agents-project.sh` script
4. ⬜ Add to git and commit
5. ⬜ Remove user-level deployment (cleanup)

## Verification
```bash
# Check deployment
ls -la .claude/agents/

# Test agent invocation
# Claude Code should now find agents like:
# - core/orchestrator-agent
# - domain/project-agent
```

---
*Date: 2025-08-06*
*Sprint: 6*
*Decision: Use project-level deployment for all agents*