# Sprint 8: Foundation - Context Manager & Agent Metadata

## Sprint Overview
- **Goal**: Establish foundation for intelligent sub-agent management
- **Duration**: 1 week (5 days)
- **Focus**: Port critical patterns from claude-code-sub-agents blueprint
- **Success Criteria**: Context persistence working, agents enhanced with capabilities

## Sprint Objectives
1. Port and adapt context-manager from blueprint
2. Enhance all agents with capability metadata
3. Create context persistence layer
4. Update CLAUDE.md with new orchestration patterns
5. Implement basic performance tracking

## Day-by-Day Plan

### Day 1: Context Manager Import & Analysis
**Morning:**
- [ ] Analyze claude-code-sub-agents context-manager implementation
- [ ] Create `/agents/core/context-manager.md` based on blueprint
- [ ] Design context schema for ClaudeProjects2
- [ ] Define context inheritance patterns

**Afternoon:**
- [ ] Implement context storage in `/.cpdm/context/`
- [ ] Create context API for agent communication
- [ ] Write context-manager tests
- [ ] Document context flow patterns

**Deliverables:**
- Working context-manager agent
- Context persistence layer
- API documentation

### Day 2: Agent Capability Enhancement
**Morning:**
- [ ] Audit all 30+ existing agents for capabilities
- [ ] Define capability taxonomy (domains, skills, tools)
- [ ] Create capability schema in YAML frontmatter
- [ ] Update agent template with capability fields

**Afternoon:**
- [ ] Update core agents (orchestrator, methodology, knowledge)
- [ ] Update domain agents (project, vision, quality)
- [ ] Update infrastructure agents (version, build, test)
- [ ] Create capability registry script

**Deliverables:**
- All agents enhanced with capabilities
- Capability registry (`/agents/capabilities.json`)
- Updated agent template

### Day 3: Context Persistence Implementation
**Morning:**
- [ ] Implement SQLite context store
- [ ] Create context versioning system
- [ ] Build context recovery mechanisms
- [ ] Add context compression for large contexts

**Afternoon:**
- [ ] Integrate with message-queue-v2.sh
- [ ] Add context passing to agent invocations
- [ ] Implement context garbage collection
- [ ] Create context debugging tools

**Deliverables:**
- SQLite context database
- Context lifecycle management
- Debugging utilities

### Day 4: Orchestration Pattern Updates
**Morning:**
- [ ] Analyze current CLAUDE.md routing rules
- [ ] Design capability-based routing
- [ ] Implement agent selection algorithm
- [ ] Create fallback chains for each domain

**Afternoon:**
- [ ] Update CLAUDE.md with new patterns
- [ ] Enhance orchestrator-agent with context awareness
- [ ] Add routing decision logging
- [ ] Create orchestration metrics

**Deliverables:**
- Updated CLAUDE.md
- Enhanced orchestrator-agent
- Routing analytics

### Day 5: Performance Tracking & Testing
**Morning:**
- [ ] Activate agent-performance-tracker.sh
- [ ] Add performance hooks to all agents
- [ ] Create performance dashboard
- [ ] Implement performance alerts

**Afternoon:**
- [ ] End-to-end testing of context flow
- [ ] Load testing with multiple agents
- [ ] Performance baseline establishment
- [ ] Sprint retrospective & demo prep

**Deliverables:**
- Performance tracking system
- Baseline metrics
- Sprint 8 demo

## Technical Tasks Breakdown

### Context Manager Implementation
```bash
# File: /agents/core/context-manager.md
---
name: context-manager
type: core
capabilities:
  - context-persistence
  - context-inheritance
  - context-versioning
  - context-recovery
---
```

### Capability Schema
```yaml
# Agent frontmatter enhancement
capabilities:
  domains: [architecture, code, testing]
  skills: [analysis, generation, validation]
  tools: [git, npm, sqlite]
  performance:
    avg_response_time: 2.3s
    success_rate: 98%
```

### Context Flow
```
orchestrator -> context-manager -> target-agent
                     |
                     v
              context-store (SQLite)
```

## Success Metrics
- [ ] Context persistence operational
- [ ] 100% agents have capability metadata
- [ ] Context inheritance working across agent chains
- [ ] Performance tracking collecting data
- [ ] Zero context loss in handoffs

## Risk Mitigation
- **Risk**: Breaking existing agent communication
  - **Mitigation**: Backward compatibility layer
- **Risk**: Performance overhead from context management
  - **Mitigation**: Async context operations, caching
- **Risk**: Complex context conflicts
  - **Mitigation**: Clear inheritance rules, versioning

## Dependencies
- claude-code-sub-agents blueprint access
- SQLite for context storage
- Existing message-queue-v2.sh

## Sprint Ceremony Schedule
- **Daily Standup**: 9:00 AM (async via GitHub issue)
- **Mid-Sprint Review**: Day 3, 2:00 PM
- **Sprint Demo**: Day 5, 3:00 PM
- **Retrospective**: Day 5, 4:00 PM

## GitHub Issues to Create
- [ ] Epic: Sub-Agent Architecture Alignment
- [ ] Task: Port Context Manager from Blueprint
- [ ] Task: Add Capability Metadata to All Agents
- [ ] Task: Implement Context Persistence Layer
- [ ] Task: Update Orchestration Patterns
- [ ] Task: Enable Performance Tracking

## Definition of Done
- [ ] Code complete and tested
- [ ] Documentation updated
- [ ] Performance metrics collected
- [ ] Demo prepared
- [ ] Retrospective completed