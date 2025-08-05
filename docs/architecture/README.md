# ClaudeProjects2 Architecture Documentation

> Clean, agent-based architecture for 10x productivity through AI-augmented knowledge work

## Architecture Overview

ClaudeProjects2 implements a **pure agent-based architecture** where:
- Everything is a Claude Code agent (no traditional services)
- CLAUDE.md serves as living orchestration
- File-based message queues enable agent communication
- Local-first design with optional cloud sync
- Obsidian provides the knowledge management UI

## Documentation Structure

### 📘 [01 - Product Vision](01-product-vision/)
**WHY** we're building ClaudeProjects2
- Executable methodologies vision
- User stories and competitive landscape
- Business model and timing rationale

### 📗 [02 - Logical Architecture](02-logical-architecture/)
**WHAT** the system does conceptually
- Domain model and layered architecture
- Cross-cutting concerns (10x engine, context management)
- Quality attributes and data flows

### 📙 [03 - Physical Architecture](03-physical-architecture/)
**HOW** the system is built with agents
- Agent-based architecture design
- Communication protocols and performance
- Deployment specifications and integrations

### 📕 [Architecture Decision Records](ADRs/)
**Key decisions** that shape the system
- ADR-001: Agent-Based Architecture
- ADR-002: CLAUDE.md as Central Orchestration
- ADR-003: File-Based Message Queue
- ADR-004: Hybrid Obsidian Integration Strategy
- ADR-005: Multi-Layer Context Cache Strategy
- ADR-006: Local-First Architecture

## Quick Navigation

**Start Here**: [Product Vision](01-product-vision/README.md) → [Logical Overview](02-logical-architecture/Overview.md) → [Physical Architecture](03-physical-architecture/Agent-Based-Physical-Architecture.md)

**For Developers**: Jump to [Physical Architecture](03-physical-architecture/) for implementation details

**For Architects**: Review [ADRs](ADRs/) for key decisions

## Key Architectural Principles

1. **Agent-First**: Every component has intelligence
2. **Local-First**: Full functionality offline, privacy by default
3. **File-Based**: Simple, debuggable, portable
4. **Self-Improving**: Agents learn and evolve
5. **10x Productivity**: Every decision enables order-of-magnitude gains

## Living Architecture

This architecture evolves as:
- Agents improve themselves
- New patterns emerge
- User needs change
- Technology advances

Last Updated: Sprint 2 Complete (Architecture Readiness Achieved)