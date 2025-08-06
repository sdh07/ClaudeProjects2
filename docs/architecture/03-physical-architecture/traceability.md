# Physical Architecture Traceability

> **Purpose**: Complete traceability from domain objects to physical components, technology choices, and deployment artifacts, with ADR documentation for all significant decisions.

## Overview

This document tracks how logical domain objects become real, running components with:
- **Object → Component mapping**
- **Technology selection (documented as ADRs)**
- **Component granularity (autonomous agent decisions)**
- **Full deployment validation (sprint demos)**

## Object-to-Component Mapping

### Standard Patterns

| Object Type | Maps To | Technology | Storage | Example |
|-------------|---------|------------|---------|---------|
| **Aggregate** | Agent or Service | Claude Code agent / TypeScript | File-based store | Project → project-agent |
| **Entity** | Model + Repository | TypeScript interface | JSON/Markdown | Document → document.ts |
| **Value Object** | Immutable Type | TypeScript type/class | Embedded | Priority → types/priority.ts |
| **Domain Service** | Stateless Function | TypeScript / Agent capability | None | LinkResolver → link-resolver.ts |
| **Domain Event** | Message Entry | JSON message | Message queue | DocumentCreated → queue/event.json |
| **Repository** | Storage Adapter | File system operations | File system | DocumentRepo → doc-repository.ts |

### Decision Criteria

```yaml
use_agent_when:
  - Complexity score > 7
  - Natural language processing required
  - Multi-step reasoning needed
  - Learning/adaptation beneficial
  - Methodology execution

use_typescript_when:
  - Simple CRUD operations
  - Data transformations
  - Performance critical
  - Deterministic logic
  - Utility functions
```

## Technology Stack (Per ADR-013)

### Core Technologies

| Layer | Technology | ADR | Rationale |
|-------|------------|-----|-----------|
| **Agents** | Claude Code | ADR-013 | AI-native capabilities |
| **Logic** | TypeScript | ADR-013 | Type safety, performance |
| **Storage** | File System | ADR-003 | Local-first, simple |
| **Messaging** | File Queues | ADR-007 | No external dependencies |
| **Configuration** | CLAUDE.md | ADR-009 | Living orchestration |
| **Documentation** | Markdown | ADR-004 | Human-readable |
| **Search** | SQLite FTS | Pending | Full-text search need |

## Component Specifications

### Real Example: Knowledge Domain Implementation

#### Logical Objects (Input from logical-architect-agent)
```yaml
domain: knowledge_domain
objects:
  - type: aggregate
    name: KnowledgeBase
    complexity: 8
  - type: entity
    name: Document
    complexity: 7
  - type: value_object
    name: Link
    complexity: 3
  - type: service
    name: LinkResolutionService
    complexity: 6
```

#### Physical Components (Output from physical-architect-agent)
```yaml
components:
  knowledge-agent:
    type: claude_code_agent
    location: /agents/domain/knowledge-agent.md
    rationale: "Complexity 8, needs AI reasoning"
    
  document-model:
    type: typescript_interface
    location: /models/document.ts
    includes: [validation, schema]
    
  document-repository:
    type: file_adapter
    location: /repositories/document-repository.ts
    storage: /knowledge-base/*.md
    
  link-type:
    type: immutable_type
    location: /types/link.ts
    
  link-resolver:
    type: typescript_service
    location: /services/link-resolver.ts
    rationale: "Deterministic logic, performance critical"
    
  document-indexer:
    type: sqlite_adapter
    location: /services/document-indexer.ts
    adr_pending: "SQLite for search performance"
```

## ADR Tracking

### ADRs Generated This Sprint

| ADR | Title | Status | Trigger | Confirmed By |
|-----|-------|--------|---------|--------------|
| ADR-013 | Claude Code Agents as Primary Technology | Accepted | Architecture design | Stephan |
| ADR-014 | SQLite for Document Search | Proposed | Performance < 100ms | Pending |
| ADR-015 | Markdown for Document Storage | Proposed | Human readability | Pending |

### ADR Automation Status
- **Confirmation Required**: ✅ All ADRs need user confirmation
- **Technology Preferences**: ✅ Documented as ADRs
- **Pending Confirmations**: 2 (ADR-014, ADR-015)

## Deployment Specifications

### Component Deployment Map

```yaml
deployment:
  /agents/:
    domain/:
      - knowledge-agent.md
      - project-agent.md
    architecture/:
      - physical-architect-agent.md
      - logical-architect-agent.md
      
  /models/:
    knowledge/:
      - document.ts
      - knowledge-base.ts
      
  /services/:
    knowledge/:
      - link-resolver.ts
      - document-indexer.ts
      
  /repositories/:
    knowledge/:
      - document-repository.ts
      - knowledge-base-repository.ts
      
  /types/:
    shared/:
      - link.ts
      - priority.ts
      - status.ts
```

### Activation Methods

| Component Type | Activation | Validation | Monitoring |
|----------------|------------|------------|------------|
| Agents | CLAUDE.md reference | Specification test | State files |
| Services | Import statements | Unit tests | Performance logs |
| Models | Import statements | Schema validation | Usage metrics |
| Repositories | Dependency injection | Integration tests | Access patterns |

## Validation Strategy

### Sprint Demo Requirements

```yaml
demo_checklist:
  traceability:
    - [ ] Show complete path: Vision → Object → Component → Running System
    - [ ] Demonstrate ADR triggers and confirmations
    - [ ] Display component interactions
    
  functionality:
    - [ ] Live system operation
    - [ ] Feature working end-to-end
    - [ ] Error handling demonstration
    
  performance:
    - [ ] Meet stated requirements
    - [ ] Show monitoring metrics
    - [ ] Demonstrate scalability
    
  documentation:
    - [ ] Updated architecture docs
    - [ ] ADRs confirmed and filed
    - [ ] Traceability matrix current
```

## Metrics

### Current Status

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Object → Component Coverage | 100% | 65% | 🟡 In Progress |
| ADR Documentation | All significant | 13 ADRs | ✅ On Track |
| Component Tests | 100% | 40% | 🟡 Building |
| Deployment Validation | Full demo | Scheduled | 📅 Sprint End |

### Traceability Completeness

```
Vision (100%) → Features (100%) → Layers (100%) → Domains (100%) → 
Objects (65%) → Components (65%) → Technologies (80%) → Deployment (40%)
```

## Component Granularity Decisions

The physical-architect-agent makes autonomous decisions based on:

| Factor | Favors Smaller | Favors Larger |
|--------|----------------|---------------|
| High Cohesion | ✓ | |
| Low Coupling | | ✓ |
| High Complexity | ✓ | |
| High Reusability | ✓ | |
| Hard to Test | ✓ | |

### Recent Decisions
- **Document aggregate**: Split into model + repository + agent (high complexity)
- **Link value object**: Keep as single type file (low complexity, high cohesion)
- **LinkResolutionService**: Separate service (high reusability)

## Next Steps

1. Complete remaining object → component mappings
2. Generate ADRs for pending technology decisions
3. Build component test suites
4. Prepare sprint end demonstration

---

## Quick Reference

### Request Component Mapping
```
physical-architect-agent map-object Document
→ Returns: Components, technology, storage, deployment
```

### Generate ADR
```
physical-architect-agent propose-adr "SQLite for search"
→ Returns: ADR proposal for confirmation
```

### Validate Deployment
```
physical-architect-agent validate-component knowledge-agent
→ Returns: Deployment status, test results
```

---

*Maintained by: physical-architect-agent*
*Last Updated: 2025-02-06*
*ADR Confirmation: Required*
*Validation: Full with demo*