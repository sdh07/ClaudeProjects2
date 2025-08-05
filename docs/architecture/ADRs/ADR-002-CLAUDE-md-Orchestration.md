# ADR-002: CLAUDE.md as Central Orchestration

**Status**: Accepted  
**Date**: 2025-08-05  
**Decision Makers**: Architecture Team  
**Related Issues**: #23, #24

## Context

In an agent-based architecture, we need a mechanism to coordinate multiple intelligent agents. Traditional orchestration approaches (service mesh, message brokers, workflow engines) don't fit the agent paradigm.

Claude Code uses CLAUDE.md files to provide context and instructions. This pattern can be extended to create a living orchestration system.

### Requirements
- Dynamic routing based on context
- Self-documenting system behavior  
- Ability to evolve orchestration rules
- Human-readable and AI-parseable
- Version controlled

## Decision

We will use **CLAUDE.md as the central nervous system** of ClaudeProjects2:

1. Project-specific CLAUDE.md files define orchestration rules
2. Contains current state, active agents, and routing logic
3. Agents read CLAUDE.md to understand their context
4. CLAUDE.md is continuously updated by agents
5. Serves as both documentation and executable orchestration

## Consequences

### Positive
- **Living Documentation**: Always up-to-date system state
- **Flexible Orchestration**: Rules can evolve with the project
- **Transparent Logic**: Orchestration is human-readable
- **Version Controlled**: Full history of orchestration changes
- **Context Aware**: Routing based on project state
- **Self-Improving**: Agents can optimize orchestration

### Negative
- **Single Point of Failure**: CLAUDE.md corruption affects all
- **Merge Conflicts**: Multiple agents updating simultaneously
- **Performance**: File I/O for every decision
- **Size Limits**: CLAUDE.md could grow too large

### Neutral
- Requires careful CLAUDE.md structure design
- Need conventions for agent updates
- Lock mechanisms for concurrent access

## Implementation

### CLAUDE.md Structure
```markdown
# ClaudeProjects2 - [Project Name]

You are the master orchestrator for this project.

## Current State
- Project Type: [Type]
- Methodology: [Active Methodology]
- Phase: [Current Phase]
- Active Agents: [List]
- Context Hash: [Hash]

## Orchestration Rules
1. For research tasks → research-agent
2. For methodology execution → methodology-agent
3. For knowledge capture → knowledge-agent
4. [Dynamic rules added by agents]

## Active Contexts
- Working: [Current task context]
- Project: [Project-wide context]
- Learning: [Patterns detected]

## Performance Metrics
- Avg Response Time: [Time]
- Success Rate: [Rate]
- [Agent-added metrics]
```

### Update Protocol
```typescript
// Agents update CLAUDE.md atomically
const updateProtocol = {
  read: "Always read current state first",
  lock: "Acquire write lock before updates",
  update: "Make minimal focused changes",
  validate: "Ensure valid markdown structure",
  commit: "Include update reason in git commit"
};
```

### Dynamic Rules Example
```markdown
## Orchestration Rules
<!-- Added by analytics-agent on 2024-01-15 -->
5. If performance metric "context_switch_time" > 400ms → optimization-agent

<!-- Added by learning-agent on 2024-01-16 -->
6. For tasks similar to "user research" → research-agent with template "user-interview"
```

## Alternatives Considered

### 1. Database-Based Orchestration
- Store rules in SQLite with agent updates
- Rejected: Less transparent, requires schema migrations

### 2. Configuration Files
- Separate YAML/JSON config files
- Rejected: Not as flexible for natural language rules

### 3. Hard-Coded Orchestration
- Fixed routing logic in orchestrator-agent
- Rejected: Can't adapt to project needs

### 4. External Orchestration Service
- Dedicated orchestration engine
- Rejected: Violates agent-based architecture

## Risks and Mitigations

### Risk: CLAUDE.md Corruption
- **Mitigation**: Git version control, validation before writes
- **Mitigation**: Backup copies maintained by context-agent

### Risk: Growing Too Large
- **Mitigation**: Archive old rules, maintain size limit
- **Mitigation**: Reference external files for details

### Risk: Merge Conflicts
- **Mitigation**: Atomic updates with file locking
- **Mitigation**: Conflict resolution strategies

## References

- CLAUDE.md documentation
- Git-based orchestration patterns
- Self-modifying systems research

## Review

Review after 100 orchestration decisions to analyze patterns and optimization opportunities.