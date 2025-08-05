# ADR-001: Agent-Based Architecture

**Status**: Accepted  
**Date**: 2025-08-05  
**Decision Makers**: Architecture Team  
**Related Issues**: #22, #23, #24

## Context

ClaudeProjects2 needs to deliver 10x productivity gains through AI augmentation. The initial logical architecture proposed a service-oriented approach with TypeScript servers. However, after analyzing the claude-code-sub-agents pattern and our product vision, we identified a fundamental mismatch.

### Problems with Service-Based Approach
- Creates artificial separation between intelligence and functionality
- Requires complex IPC mechanisms
- Limits the system's ability to self-improve
- Doesn't leverage Claude Code's native capabilities

### Opportunity
The claude-code-sub-agents repository demonstrates that Claude Code can orchestrate multiple specialized agents through CLAUDE.md files, creating a truly intelligent system where every component can think and adapt.

## Decision

We will implement ClaudeProjects2 as a **pure agent-based architecture** where:

1. Every component is a Claude Code agent (markdown file)
2. CLAUDE.md serves as the central nervous system
3. No traditional servers or services
4. Agents can spawn and modify other agents
5. Intelligence is distributed throughout the system

## Consequences

### Positive
- **Native Intelligence**: Every component can reason and adapt
- **Self-Improving**: Agents learn from usage patterns
- **Simplified Architecture**: No complex service layers
- **True AI-First**: Not just AI-assisted, but AI-native
- **Easier Development**: Write agents in natural language
- **Better Debugging**: Human-readable agent definitions

### Negative
- **New Paradigm**: Requires different thinking about architecture
- **Performance Uncertainty**: Agent invocation overhead
- **Limited Control**: Agents have autonomy
- **Testing Challenges**: Non-deterministic behavior

### Neutral
- Requires strong CLAUDE.md orchestration patterns
- Shifts complexity from code to agent design
- Dependencies on Claude Code CLI availability

## Implementation

### Agent Hierarchy
```
CLAUDE.md (Master Orchestrator)
├── Core Agents (always loaded)
│   ├── orchestrator-agent
│   ├── methodology-agent
│   ├── knowledge-agent
│   └── context-agent
├── Domain Agents (on-demand)
│   ├── project-agent
│   ├── research-agent
│   ├── innovation-agent
│   └── analytics-agent
└── Infrastructure Agents
    ├── obsidian-agent
    ├── sync-agent
    ├── version-agent
    └── license-agent
```

### Agent Structure
```markdown
---
name: agent-name
description: When to invoke this agent
category: core|domain|infrastructure
tools: [file_management, web_search]
version: 1.0.0
---

# Agent Name

You are the [role] agent for ClaudeProjects2...
```

## Alternatives Considered

### 1. Hybrid Approach
- Some components as services, some as agents
- Rejected: Creates complexity without clear benefits

### 2. Traditional Microservices
- TypeScript/Python services with Claude Code integration
- Rejected: Doesn't achieve the vision of true AI augmentation

### 3. Monolithic AI Application
- Single large Claude Code prompt
- Rejected: Lacks modularity and scalability

## References

- [claude-code-sub-agents repository](https://github.com/lst97/claude-code-sub-agents)
- Product Vision Document
- Sprint 2 Analysis Documents

## Review

This decision will be reviewed after Sprint 3 implementation to validate performance and development experience.