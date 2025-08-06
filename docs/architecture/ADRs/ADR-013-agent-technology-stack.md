# ADR-013: Claude Code Agents as Primary Implementation Technology

## Status
Accepted

## Date
2025-02-06

## Context
ClaudeProjects2 requires a technology stack that can handle complex reasoning, natural language processing, and adaptive workflows while maintaining simplicity and local-first operation. Traditional service architectures would require multiple technologies and complex integration.

## Decision
Use Claude Code agents as the primary implementation technology for all complex domain logic, with TypeScript modules for simple operations and file-based storage for all persistence.

## Consequences

### Positive
- **Unified technology**: Single paradigm for all complex logic
- **AI-native**: Natural language processing built-in
- **Adaptive**: Agents can learn and improve
- **Simple deployment**: Just Claude Code CLI needed
- **Local-first**: Everything runs on user's machine
- **No servers required**: Pure agent-based architecture

### Negative
- **Performance overhead**: Agents slower than native code for simple operations
- **Resource usage**: More memory/CPU than traditional services
- **Learning curve**: Developers need to understand agent paradigm
- **Debugging complexity**: Agent behaviors can be non-deterministic

### Neutral
- **File-based everything**: All storage is files (no databases)
- **Message queue pattern**: All communication via file-based queues
- **CLAUDE.md orchestration**: Central configuration file

## Alternatives Considered
- **Traditional microservices**: Too complex for local deployment
- **Serverless functions**: Requires cloud infrastructure
- **Monolithic application**: Lacks flexibility and modularity
- **Pure TypeScript**: Lacks AI capabilities

## Traceability
- **Triggered by**: Physical architecture design requirements
- **Affects**: All components in the system
- **Related ADRs**: ADR-003 (File-based architecture), ADR-007 (Message queues)
- **Implements**: Triple Helix vision (Agents component)

## Confirmation
- **Requested from**: Product Manager
- **Date requested**: 2025-02-06
- **Confirmed by**: Stephan
- **Date confirmed**: 2025-02-06

## Notes
This is a foundational decision that affects all other technology choices. The agent-first approach is what makes ClaudeProjects2 unique and enables the 10x productivity gains promised in the vision.