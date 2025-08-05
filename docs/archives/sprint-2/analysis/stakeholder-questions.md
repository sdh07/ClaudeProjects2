# Stakeholder Questions
**Sprint 2, Monday - Issue #22**
**Date**: 2025-08-05

## Purpose
This document compiles critical questions that need stakeholder input before finalizing the physical architecture. Questions are organized by priority and impact on architectural decisions.

## Critical Questions (Must Have Before Wednesday)

### 1. Claude Code Integration Depth
**Context**: Claude Code is identified as the primary AI execution environment, but integration approach is undefined.

**Questions**:
- Should we use Claude Code's markdown agent format directly or create our own abstraction layer?
- Which Claude Code features are essential vs optional?
  - Sub-agent spawning?
  - Context management (CLAUDE.md)?
  - Tool usage patterns?
  - Memory/state persistence?
- Are there any Claude Code limitations we should design around?
- Should agents be hot-reloadable or require restart?

### 2. Obsidian Integration Architecture
**Context**: Obsidian is the knowledge platform, but integration method unclear.

**Questions**:
- Should we integrate via:
  - Obsidian plugin (deeper integration but more complex)?
  - File system watching (simpler but limited)?
  - Obsidian API (if available)?
- How should we handle Obsidian vault structure?
  - One vault per project?
  - Shared vault with project folders?
  - Separate vaults for methodologies/knowledge?
- What about mobile Obsidian sync?
- Should we support Obsidian Sync service or build our own?

### 3. Performance Requirements Clarification
**Context**: Vision promises specific performance targets but hardware assumptions unclear.

**Questions**:
- What are the minimum hardware requirements we're targeting?
  - RAM (8GB, 16GB, 32GB)?
  - CPU (cores, generation)?
  - Storage (SSD required)?
- What's the expected size of:
  - A typical project after 6 months?
  - Knowledge base after 1 year?
  - Number of concurrent agents?
- Should we optimize for:
  - Memory usage (many small agents)?
  - CPU usage (fewer powerful agents)?
  - Disk I/O (knowledge queries)?

## High Priority Questions (Need by Thursday)

### 4. Agent Architecture Specifics
**Questions**:
- How much customization should end-users have over agents?
  - Just parameters/prompts?
  - Full agent creation capability?
  - Visual agent builder?
- Should agents be able to create/modify other agents?
- What's the agent versioning strategy?
- How do we handle agent failures/errors?

### 5. Multi-User Collaboration Model
**Questions**:
- In a local-first architecture, how should collaboration work?
  - P2P sync between workstations?
  - Optional cloud relay?
  - Git-like merge model?
- How do we handle concurrent edits?
- What about async collaboration (leave messages for others)?
- Should we support real-time presence indicators?

### 6. Business Model Technical Enforcement
**Questions**:
- How should we differentiate open source vs paid features?
  - Compile-time flags?
  - Runtime license checks?
  - Plugin architecture?
- What specific features are paid-only?
  - Advanced agents?
  - Certain methodologies?
  - Team features?
  - Performance optimizations?
- How do we handle license validation in offline mode?

## Medium Priority Questions (For Demo Prep)

### 7. Technology Stack Preferences
**Questions**:
- Any strong preferences for:
  - Frontend framework (React, Vue, Svelte)?
  - Desktop framework (Electron, Tauri)?
  - Database (SQLite, DuckDB)?
  - Language (TypeScript throughout)?
- Any technologies to avoid?
- Open source license preferences (MIT, Apache, GPL)?

### 8. User Experience Priorities
**Questions**:
- What's more important:
  - Beautiful UI or functional UI?
  - Feature richness or simplicity?
  - Flexibility or opinionated workflows?
- Should we have:
  - Dark mode from day 1?
  - Keyboard-first navigation?
  - Voice input support?
- Mobile experience priority?

### 9. Integration Ecosystem
**Questions**:
- Which integrations are priority 1?
  - GitHub/GitLab?
  - Google Workspace?
  - Microsoft Office?
  - Slack/Discord?
- Should integrations be:
  - Built-in?
  - Plugin-based?
  - Via MCP servers?

## Questions About Constraints

### 10. Technical Constraints
- Maximum acceptable application size?
- Specific security requirements (encryption standards)?
- Compliance requirements (GDPR, HIPAA)?
- Cross-platform priority (Mac first, then Windows)?

### 11. Timeline Constraints
- MVP feature set for Sprint 3?
- Alpha/Beta release targets?
- When do we need revenue features?

### 12. Resource Constraints
- Team size assumptions?
- Budget for third-party services?
- Infrastructure limitations?

## Strategic Questions

### 13. Competitive Differentiation
- What's our unique advantage that competitors can't copy?
- How do we protect our methodology IP?
- What makes our agents special?

### 14. Future Vision
- Should architecture support future SaaS offering?
- Plan for enterprise features?
- AI model agnosticism important?

### 15. Community Building
- How open should development be?
- Contribution model for methodologies?
- Revenue sharing with contributors?

## Risk Mitigation Questions

### 16. Technical Risks
- What if Claude Code changes significantly?
- What if Obsidian's architecture limits us?
- How do we handle AI model deprecation?

### 17. Business Risks
- What if users don't see 10x value?
- How do we handle methodology quality?
- What about agent misbehavior?

## Immediate Decision Points

**For Tuesday's Research**:
1. Claude Code integration approach preference?
2. Obsidian integration depth?
3. Performance vs feature tradeoffs?

**For Wednesday's Design**:
1. Monolithic vs microservices?
2. Plugin architecture everywhere or selective?
3. How much to build vs integrate?

## Request for Stakeholder

Please prioritize answering the **Critical Questions** section first, as these directly impact Tuesday and Wednesday's architectural work. Other questions can be addressed throughout the week or deferred to Sprint 3 planning.

### Preferred Response Format
For each question, please indicate:
- **Answer**: Direct response
- **Flexibility**: How firm is this decision?
- **Rationale**: Why this choice?
- **Alternatives**: Acceptable compromises?

This will help us make informed architectural decisions that align with the product vision while remaining pragmatic about implementation realities.