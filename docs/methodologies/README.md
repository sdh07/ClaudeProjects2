# ClaudeProjects2 Methodologies

This directory contains all development methodologies used in ClaudeProjects2.

## Available Methodologies

### 1. Architecture-Centric Methodology
- **Location**: `/docs/Architecture Centric Methodology.md`
- **Purpose**: Foundation methodology for architecture-first development
- **Key Concepts**: Architecture precedes implementation

### 2. CPDM (Claude Projects Development Method)
- **Location**: `/docs/methodologies/CPDM/`
- **Purpose**: End-to-end development methodology with quality gates
- **Key Concepts**: Seven phases from Vision to Feedback with enforced quality gates
- **Status**: Active - Sprint 5 implementation

### 3. Agile with Architecture Focus
- **Location**: `/docs/Project Management System.md`
- **Purpose**: Sprint-based delivery with architecture emphasis
- **Key Concepts**: Sprints, demos, retrospectives with architecture validation

## Methodology Selection Guide

| Scenario | Recommended Methodology | Reason |
|----------|------------------------|---------|
| New feature development | CPDM | Full traceability and quality gates |
| Bug fixes | CPDM Fast Track | Streamlined path for quick fixes |
| Architecture changes | Architecture-Centric + CPDM | Architecture validation critical |
| Experimental features | CPDM Experimental Flow | Relaxed gates for learning |
| Sprint planning | Agile with Architecture | Proven sprint structure |

## Integration Points

All methodologies integrate with:
- **Vision**: Product Vision drives all development
- **Architecture**: Logical and Physical architecture guide implementation
- **Agents**: Agent-based execution model
- **Quality**: Automated quality gates and validation
- **Traceability**: Complete audit trail from vision to deployment

## Key Principles

1. **Architecture First**: Design before implementation
2. **Quality Gates**: Automated validation at phase transitions
3. **Full Traceability**: Every artifact traces to vision
4. **Agent Automation**: Agents handle complex tasks
5. **Local-First**: Everything runs locally

## Quick Links

- [CPDM Quick Reference](./CPDM/CPDM-Quick-Reference.md)
- [Architecture Methodology](../Architecture%20Centric%20Methodology.md)
- [Project Management](../Project%20Management%20System.md)
- [Product Vision](../architecture/01-product-vision/Product%20Vision.md)

---

*Maintained by: methodology-agent*
*Last Updated: 2025-02-06*