# CLAUDE.md Design and Maintenance Strategy

## Overview

CLAUDE.md serves as the **living constitution** for our AI-augmented development workflow. It's the persistent memory that shapes every interaction between Claude Code and our project, ensuring consistency, quality, and alignment with our architecture-centric methodology.

## Core Philosophy

> "Write for Claude, not for humans. Be direct, be specific, be actionable."

### Key Principles

1. **Brevity is Power**: Every token counts - concise instructions outperform verbose explanations
2. **Living Document**: Evolves with every sprint, every learning, every mistake
3. **Action-Oriented**: Focus on what TO DO, not what to avoid
4. **Project-Specific**: Tailored to ClaudeProjects' unique needs and methodology

## CLAUDE.md Structure

### 1. Identity Declaration
```markdown
You are the orchestrator for ClaudeProjects2, an architecture-centric platform for AI-augmented knowledge work.
```

### 2. Core Directives
```markdown
## Primary Directives
- Architect first, implement second
- Every decision requires an ADR
- Use specialized agents for complex tasks
- Maintain knowledge graph continuously
- Local-first, cloud-optional
```

### 3. Project Context
```markdown
## Project Structure
- `/agents/` - Specialized AI agents (markdown files)
- `/docs/` - Living documentation
- `/docs/architecture/` - Architectural decisions and designs
- `/docs/specs/` - Technical specifications
- `/issues/` - GitHub issue templates
```

### 4. Methodology Enforcement
```markdown
## Architecture-Centric Workflow
1. Analyze requirements with Architecture Designer agent
2. Document decisions in ADRs
3. Design before implementing
4. Validate against architecture
5. Update knowledge base
```

### 5. Agent Orchestration Rules
```markdown
## Agent Usage
For complex tasks, invoke specialized agents:
- Architecture: Use architecture-designer
- Documentation: Use user-guide-writer
- Implementation: Use code-generator-enhanced
- Validation: Use conformance-checker

Trivial tasks: Handle directly
Non-trivial tasks: Delegate to agents
```

### 6. Quality Standards
```markdown
## Code Standards
- TypeScript with strict mode
- 2-space indentation
- Functional programming preferred
- Test coverage > 80%
- Every public API documented
```

### 7. Integration Commands
```markdown
## Common Commands
- Lint: `npm run lint`
- Test: `npm test`
- Build: `npm run build`
- Deploy: `npm run deploy`
- Typecheck: `npm run typecheck`
```

### 8. Dynamic Imports
```markdown
## Context Imports
@docs/architecture/decisions/latest.md
@docs/specs/current-sprint.md
@.github/issues/active.md
```

## Maintenance Strategy

### 1. Automated Evolution

#### Sprint Updates
```markdown
## Sprint ${SPRINT_NUMBER} Context
- Goals: ${SPRINT_GOALS}
- Active Issues: ${ISSUE_LINKS}
- Blockers: ${BLOCKERS}
```

#### Learning Integration
When Claude makes mistakes:
1. Identify root cause
2. Add specific directive to prevent recurrence
3. Test the update
4. Commit with rationale

### 2. Review Cycles

#### Daily
- Quick scan for outdated information
- Update active issue references
- Refresh sprint context

#### Weekly
- Review and consolidate learnings
- Prune redundant instructions
- Update agent references

#### Sprint End
- Archive sprint-specific content
- Extract reusable patterns
- Update methodology based on retrospective

### 3. Version Control Integration

```bash
# Pre-commit hook to validate CLAUDE.md
#!/bin/bash
# .git/hooks/pre-commit

# Check CLAUDE.md size (should be < 1000 lines)
lines=$(wc -l < CLAUDE.md)
if [ $lines -gt 1000 ]; then
  echo "Warning: CLAUDE.md exceeds 1000 lines. Consider refactoring."
fi

# Validate markdown syntax
npx markdownlint CLAUDE.md
```

### 4. Modular Organization

```
CLAUDE.md (main file)
├── @project-context.md
├── @methodology.md
├── @agent-registry.md
├── @quality-standards.md
└── @current-sprint.md
```

## Best Practices Implementation

### 1. Token Optimization
```markdown
BAD:  The components directory contains React components
GOOD: components/ - React components

BAD:  When implementing features, always ensure quality
GOOD: Test coverage > 80% required
```

### 2. Action-Oriented Language
```markdown
BAD:  Avoid using console.log
GOOD: Use slog for structured logging

BAD:  Don't forget to handle errors
GOOD: Wrap async calls in try-catch with specific error types
```

### 3. Contextual Awareness
```markdown
## Current Focus
Sprint 1: Architecture and agent infrastructure
Primary: Design logical/physical architecture
Secondary: Implement core agents
Blocked: None
```

### 4. Quick Update Protocol
During development, use `#` to add learnings:
```
# Always use semantic versioning for releases
# Run integration tests before merging to main
# Document API changes in CHANGELOG.md
```

## Template: ClaudeProjects2 CLAUDE.md

```markdown
# ClaudeProjects2 AI Assistant Protocol

You orchestrate ClaudeProjects2 development following architecture-centric methodology.

## Core Principles
- Architecture precedes implementation
- Agents handle complexity
- Knowledge compounds continuously
- Local-first, privacy-first

## Project Architecture
- Stack: TypeScript, React, Electron, SQLite
- Pattern: Local-first with optional cloud sync
- Agents: Specialized markdown-based AI agents
- Knowledge: Obsidian-integrated graph database

## Workflow Protocol
1. Complex tasks → Invoke specialized agent
2. Simple queries → Direct response
3. Architectural changes → ADR required
4. Code changes → Test + Lint required
5. All outputs → Update knowledge base

## Active Agents
- architecture-designer: System design
- user-guide-writer: Documentation
- code-generator-enhanced: Implementation
- conformance-checker: Validation

## Quality Gates
- TypeScript strict mode
- ESLint + Prettier
- Jest coverage > 80%
- E2E tests for critical paths

## Commands
- Install: npm install
- Dev: npm run dev
- Test: npm test
- Build: npm run build
- Lint: npm run lint
- Deploy: npm run deploy

## Sprint Context
@docs/sprints/current.md

## Recent Decisions
@docs/architecture/decisions/recent.md

## Known Issues
@.github/issues/blockers.md
```

## Monitoring and Metrics

### Health Indicators
1. **Size**: < 500 lines (main file)
2. **Specificity**: > 90% actionable directives
3. **Currency**: < 24 hours since last update
4. **Effectiveness**: Task success rate > 95%

### Anti-patterns to Avoid
- ❌ Long narrative explanations
- ❌ Redundant information
- ❌ Human-oriented documentation
- ❌ Outdated commands or paths
- ❌ Generic programming advice

## Integration with Development Flow

### 1. Issue Creation
```yaml
# .github/ISSUE_TEMPLATE/feature.yml
- type: textarea
  id: claude-context
  label: CLAUDE.md Updates
  description: Required updates to CLAUDE.md for this feature
```

### 2. PR Checklist
```markdown
- [ ] CLAUDE.md updated with new patterns
- [ ] Removed outdated directives
- [ ] Added new agent references if applicable
- [ ] Tested with Claude Code
```

### 3. CI/CD Integration
```yaml
# .github/workflows/claude-validation.yml
name: Validate CLAUDE.md
on: [push, pull_request]
jobs:
  validate:
    steps:
      - name: Check CLAUDE.md size
      - name: Validate markdown
      - name: Check import paths
      - name: Verify agent references
```

## Evolution Patterns

### Learning Capture
```markdown
## Learnings [Date]
- Pattern: [What worked]
- Anti-pattern: [What didn't]
- Directive: [New instruction added]
```

### Refactoring Triggers
1. Size exceeds 500 lines → Extract to imports
2. Redundancy detected → Consolidate directives
3. Sprint ends → Archive sprint-specific content
4. Major pivot → Rewrite core principles

## Success Metrics

### Quantitative
- Response accuracy: > 95%
- Task completion: > 90%
- Agent invocation success: > 98%
- Build success rate: > 99%

### Qualitative
- Clear architectural alignment
- Consistent code style
- Proper agent delegation
- Knowledge base growth

## Conclusion

CLAUDE.md is not just a file—it's the living nervous system of our AI-augmented development process. By maintaining it with discipline and treating it as a first-class artifact, we ensure that every interaction with Claude Code moves our project forward with precision and purpose.