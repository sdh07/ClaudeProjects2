# ADR-022: Agent Directory Structure for Claude Code Deployment

## Status
Proposed

## Context
During Sprint 6 Day 1, we deployed all agents flat to `~/.claude/agents/`. This loses our category organization (core, domain, architecture, etc.) and could cause naming conflicts or discovery issues.

## Decision
Deploy agents with their category structure preserved:
```
~/.claude/agents/
├── core/
│   ├── orchestrator-agent.md
│   └── context-agent.md
├── domain/
│   └── project-agent.md
├── architecture/
│   ├── logical-architect-agent.md
│   └── physical-architect-agent.md
└── ...
```

## Alternatives Considered

### 1. Flat Structure (Current)
- ✅ Simple
- ❌ No organization
- ❌ Potential naming conflicts

### 2. Prefixed Names
- Example: `core-orchestrator-agent.md`
- ✅ No subdirectories needed
- ❌ Long names
- ❌ Still no visual organization

### 3. Category Subdirectories (Chosen)
- ✅ Clear organization
- ✅ Matches our repo structure
- ✅ Easier to find agents by type
- ❓ Need to verify Claude Code supports this

## Consequences

### Positive
- Maintains our logical organization
- Easier agent discovery
- Category-based access control possible
- Aligns with our architecture

### Negative
- More complex deployment script
- Need to test if Claude Code's Task tool handles paths
- May need to update agent references

## Implementation
1. Test if Claude Code supports subdirectories
2. Update deployment script
3. Re-deploy all agents with structure
4. Update documentation

## Open Questions
- Does Claude Code's Task tool support `core/orchestrator-agent` style references?
- Should we also use the `~/.claude/sub-agents/` directory?
- Do we need to update agent metadata for paths?

---
*Date: 2025-08-06*
*Author: System Architect*
*Sprint: 6*