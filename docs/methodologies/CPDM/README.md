# CPDM: Claude Projects Development Method

> **Status**: Implementation in Sprint 5 (2025-02-06 to 2025-02-10)
> **Version**: 1.0.0
> **Owner**: methodology-agent

## Overview

The Claude Projects Development Method (CPDM) is a comprehensive development methodology that provides end-to-end traceability from product vision to deployment with enforced quality gates at each phase transition.

## Core Philosophy

**"Every line of code traces back to the vision, every decision is documented, every phase has quality gates."**

CPDM ensures that:
- No code is written without clear purpose
- All architectural decisions are documented and confirmed
- Quality is built-in, not bolted-on
- Feedback loops drive continuous improvement

## The Seven Phases

### Phase 1: Vision
- **Purpose**: Align features with product vision
- **Owner**: vision-agent
- **Duration**: 1 day
- **Key Activities**: Triple Helix validation, ROI calculation, priority assignment
- **Quality Gates**: Triple Helix passed, ROI > 10x, PM approval

### Phase 2: Design
- **Purpose**: Transform features into architectural designs
- **Owner**: logical-architect-agent
- **Duration**: 2-3 days
- **Key Activities**: Layer assignment, domain modeling, interface design
- **Quality Gates**: Boundaries respected, domains clear, objects specified

### Phase 3: Decision
- **Purpose**: Make and document architectural decisions
- **Owner**: physical-architect-agent
- **Duration**: 1 day
- **Key Activities**: Component mapping, technology selection, ADR generation
- **Quality Gates**: ADRs confirmed, technologies consistent, deployment feasible

### Phase 4: Implementation
- **Purpose**: Build components according to specifications
- **Owner**: development-team + agents
- **Duration**: 3-5 days
- **Key Activities**: Code development, unit testing, documentation
- **Quality Gates**: Code reviewed, tests passing, docs complete

### Phase 5: Quality
- **Purpose**: Ensure implementation meets all standards
- **Owner**: quality-agent
- **Duration**: 1 day
- **Key Activities**: Integration testing, performance validation, security scanning
- **Quality Gates**: All tests pass, performance met, security clean

### Phase 6: Delivery
- **Purpose**: Deploy to production environment
- **Owner**: deployment-team
- **Duration**: 0.5 day
- **Key Activities**: Deployment, smoke testing, monitoring setup
- **Quality Gates**: Deployment successful, monitoring active, rollback ready

### Phase 7: Feedback
- **Purpose**: Collect metrics and improve
- **Owner**: trace-agent
- **Duration**: Ongoing
- **Key Activities**: Usage monitoring, feedback collection, improvement proposals
- **Quality Gates**: Metrics collected, feedback analyzed, actions identified

## Quality Gates Framework

### Enforcement Levels

1. **Mandatory** 🔴
   - Cannot proceed without passing
   - Examples: Triple Helix validation, ADR confirmation, security scan
   - Action on failure: Block progression

2. **Recommended** 🟡
   - Should pass but can override with justification
   - Examples: Code coverage > 80%, performance optimization
   - Action on failure: Warning + justification required

3. **Optional** 🟢
   - Nice to have improvements
   - Examples: Documentation enhancements, additional tests
   - Action on failure: Log for future improvement

## Workflow Patterns

### Standard Flow (5-10 days)
For regular feature development with full validation.

### Fast Track (1-2 days)
For bug fixes and minor changes with streamlined gates.

### Experimental Flow (Variable)
For prototypes and learning with relaxed gates.

## Implementation

### Required Agents
- vision-agent
- logical-architect-agent
- physical-architect-agent
- quality-agent (Sprint 5, Day 8)
- trace-agent (Sprint 5, Day 8)

### Required Infrastructure
- Message queue system
- ADR automation
- Test runners
- Deployment pipeline
- Monitoring system

### GitHub Integration (Key Differentiator)
CPDM **natively integrates with GitHub**, unlike other methodologies:

- **Issue Tracking**: Each feature automatically creates GitHub issue
- **ADR Management**: ADRs tracked as issues and PRs
- **Sprint Planning**: GitHub Projects integration
- **Code Reviews**: Quality gates tied to PR reviews
- **Deployment Tracking**: GitHub Actions for CI/CD
- **Feedback Collection**: Issues and discussions
- **Metrics**: GitHub Insights integration

This means:
- All decisions are traceable in GitHub history
- Collaboration happens where developers work
- No external tools needed
- Complete audit trail in version control

## Success Criteria

| Metric | Target |
|--------|--------|
| Cycle time reduction | 50% |
| Gate automation | > 80% |
| Defect escape rate | < 5% |
| Architecture compliance | > 95% |
| Feature → Vision traceability | 100% |
| Developer NPS | > 70 |

## Templates

See [templates/](./templates/) directory for:
- Phase checklists
- Gate evaluation forms
- ADR templates
- Workflow configurations

## Integration

CPDM integrates with:
- [Architecture-Centric Methodology](../../Architecture%20Centric%20Methodology.md)
- [Product Vision](../../architecture/01-product-vision/Product%20Vision.md)
- [Logical Architecture](../../architecture/02-logical-architecture/)
- [Physical Architecture](../../architecture/03-physical-architecture/)
- [ADR System](../../architecture/ADRs/)

## References

- [Quick Reference Guide](./CPDM-Quick-Reference.md)
- [Sprint 5 Implementation Plan](../../project-management/sprint-5-planning.md)
- [Original Concept Document](/sprints/current/day7-cpdm-concept.md)

---

*This methodology is being implemented in Sprint 5 (2025-02-06 to 2025-02-10)*
*For questions or improvements, contact the methodology-agent*