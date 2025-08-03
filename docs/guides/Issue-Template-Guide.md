# Issue Template Guide

## Overview

ClaudeProjects uses structured issue templates aligned with our architecture-centric methodology. Each template serves a specific purpose in our development workflow.

## Template Types

### 1. Epic Template
**When to use**: Large features spanning multiple sprints
**Key sections**:
- Vision statement
- Architectural impact assessment
- Success criteria
- Risk analysis

**Example**:
```
[EPIC] AI-Powered Knowledge Graph
- Spans 3 sprints
- Requires new architecture patterns
- Multiple user stories
```

### 2. User Story Template
**When to use**: User-facing functionality
**Key sections**:
- User story format (As a... I want... So that...)
- Acceptance criteria
- Story points (Fibonacci)
- Agent assignment

**Example**:
```
[STORY] As a developer, I want to search my codebase semantically
- 5 story points
- Agent: architecture-designer
```

### 3. Technical Task Template
**When to use**: Technical work, refactoring, infrastructure
**Key sections**:
- Technical approach
- Definition of done
- Architectural considerations
- Agent instructions

**Example**:
```
[TASK] Implement vector database for semantic search
- 8 hours estimated
- Architecture pattern: Repository
```

### 4. Bug Report Template
**When to use**: System defects
**Key sections**:
- Reproduction steps
- Severity assessment
- Environmental details
- Architectural impact

**Example**:
```
[BUG] Agent response timeout on large codebases
- Severity: High
- Component: Agent Runtime
```

### 5. Research Spike Template
**When to use**: Time-boxed investigations
**Key sections**:
- Research question
- Time box
- Evaluation criteria
- Expected deliverables

**Example**:
```
[RESEARCH] Evaluate vector databases for knowledge graph
- Time box: 2 days
- Deliverable: ADR with recommendation
```

### 6. ADR Template
**When to use**: Documenting architectural decisions
**Key sections**:
- Context and forces
- Decision and rationale
- Consequences (positive/negative/neutral)
- Alternatives considered

**Example**:
```
[ADR] ADR-002: Use SQLite for Local Storage
- Status: Accepted
- Driver: Local-first architecture
```

## Best Practices

### 1. Choose the Right Template
- Epics → Multi-sprint features
- Stories → User value in one sprint
- Tasks → Technical enablers
- Bugs → Defects (not feature requests)
- Research → Reduce uncertainty
- ADRs → Document decisions

### 2. Link Issues Properly
```
Epic #1
  └── Story #2
       └── Task #3
            └── ADR #4
```

### 3. Use Labels Consistently
- `epic` - Large features
- `story` - User stories
- `task` - Technical tasks
- `bug` - Defects
- `research` - Spikes
- `adr` - Architecture decisions
- `needs-architecture` - Requires design
- `agent-ready` - Can be handled by agents

### 4. Agent Assignment
Always specify which agent should handle the work:
- Complex design → `architecture-designer`
- Documentation → `user-guide-writer`
- Implementation → `code-generator-enhanced`
- Validation → `conformance-checker`

### 5. Update CLAUDE.md
Each issue should consider:
- New patterns to document
- Commands to add
- Workflows to capture
- Learnings to record

## Workflow Integration

### Sprint Planning
1. Review epics for sprint goals
2. Break down into stories
3. Estimate using templates
4. Assign to agents/developers

### During Sprint
1. Create tasks as needed
2. Document decisions in ADRs
3. Research before implementing
4. Update CLAUDE.md continuously

### Sprint Review
1. Close completed issues
2. Update epic progress
3. Capture learnings
4. Plan next sprint

## Tips for Claude Code Users

When creating issues with Claude Code:
```
Create a GitHub issue for implementing semantic search
- Use the user story template
- Assign 5 story points
- Primary agent: architecture-designer
- Link to epic #1
```

Claude will use the appropriate template and fill in the details based on context.

## Quality Checklist

Before submitting an issue:
- [ ] Correct template selected
- [ ] All required fields completed
- [ ] Linked to parent issue (if applicable)
- [ ] Agent specified (if applicable)
- [ ] Labels applied
- [ ] CLAUDE.md impact considered

## Evolution

These templates will evolve as we learn. To suggest improvements:
1. Create an issue using the Task template
2. Label it `template-improvement`
3. Describe the proposed change
4. Include rationale