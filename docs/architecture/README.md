# ClaudeProjects2 Architecture Guide

> Progressive disclosure architecture documentation - start simple, dive deep as needed.

## Quick Overview

ClaudeProjects2 implements the **Triple Helix** innovation (Methodology → AI Agents → Knowledge) to deliver **10x productivity gains** for knowledge workers.

## Architecture Organization

### 📋 [Logical Architecture](logical/)
**What the system does** - Business capabilities and domains

Progressive exploration:
- [Overview](logical/Overview.md) - Triple Helix and principles
- [Layers](logical/Layers.md) - Detailed layer specifications  
- [Domains](logical/Domains.md) - Business logic deep dive
- [Cross-Cutting](logical/Cross-Cutting.md) - System-wide concerns
- [Quality Attributes](logical/Quality-Attributes.md) - 10x enablers
- [Flows](logical/Flows.md) - Real-world examples

### 🔧 [Physical Architecture](physical/)
**How it's built** - Technologies and infrastructure

Progressive exploration:
- [Overview](physical/Overview.md) - Technology decisions
- [Technology Stack](physical/Technology-Stack.md) - Detailed choices
- [Deployment](physical/Deployment.md) - Setup and scaling
- [Data Architecture](physical/Data-Architecture.md) - Storage design
- [Security](physical/Security.md) - Privacy and protection
- [Agent Implementation](physical/Agent-Implementation.md) - Runtime details

### 🤖 [Agent Architecture](Agent-Architecture.md)
**AI building blocks** - Agent design and orchestration
- Markdown-based agent definitions
- Claude Code integration patterns
- Agent collaboration protocols
- Performance optimization

## Key Architectural Decisions

1. **[ADR-001: Agent Architecture Pattern](decisions/ADR-001-Agent-Architecture-Pattern.md)** - Why we chose markdown-based agents
2. **ADR-002: Local-First Data** *(coming soon)* - Privacy and performance rationale
3. **ADR-003: MCP Integration Strategy** *(coming soon)* - Leveraging the ecosystem

## For Different Audiences

### 👩‍💻 For Developers
1. Start with [Agent Architecture](Agent-Architecture.md) to understand how to build agents
2. Review [Physical Architecture](Physical-Architecture.md#technology-stack) for tech stack
3. Check `/agents/` directory for examples

### 🏗️ For Architects  
1. Begin with [Logical Architecture](Logical-Architecture.md) for system design
2. Review architectural decisions in `decisions/`
3. Explore [Physical Architecture](Physical-Architecture.md#deployment-architecture) for deployment

### 📊 For Product Managers
1. Read [Logical Architecture](Logical-Architecture.md#core-domains) for business capabilities
2. See [Product Vision](Product%20Vision.md) for strategic context
3. Review quality attributes for system characteristics

## Architecture Principles

1. **Architecture-First**: Design before implementation
2. **Agent-Oriented**: AI agents as first-class citizens
3. **Local-First**: Your data, your machine, your control
4. **Progressive Enhancement**: Cloud features are optional
5. **Knowledge-Centric**: Every action feeds the knowledge graph

## Quick Links

- **Setup**: [Development Setup](../Development%20Setup%20Complete.md)
- **Agents**: See `/agents/` directory
- **Workflows**: [PM System Design](../PM-System-Comprehensive-Report.md)
- **Specifications**: See `/docs/specs/` directory

## Next Steps

- **New to the project?** Start with [Logical Architecture](Logical-Architecture.md)
- **Ready to code?** Jump to [Agent Architecture](Agent-Architecture.md)
- **Setting up?** Follow [Physical Architecture](Physical-Architecture.md#deployment-architecture)