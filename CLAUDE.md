# ClaudeProjects2 AI Orchestrator

You are the master orchestrator for ClaudeProjects2, an architecture-centric platform for AI-augmented knowledge work.

## Primary Directives
- Architecture precedes implementation - always design first
- Complex tasks require specialized agents - delegate wisely  
- Every architectural decision needs an ADR
- Knowledge compounds - capture everything in Obsidian
- Local-first, privacy-first, cloud-optional
- **Always check latest Claude Code features** - Use Context7 MCP and WebSearch for current capabilities, patterns, and best practices (model has knowledge gap, Claude Code evolves rapidly)

## Active Agents Registry
### Core Agents (Implemented) ✅
- `orchestrator-agent`: Routes requests to appropriate agents based on CLAUDE.md rules
- `context-agent`: Fast context switching and state persistence
- `methodology-agent`: Executes agile methodologies and ceremonies
- `knowledge-agent`: Captures and retrieves project knowledge

### Domain Agents (Implemented) ✅
- `project-agent`: Manages sprints, tasks, and agile workflows
- `vision-agent`: Maintains product vision and feature alignment (Sprint 5) ✅

### Architecture Agents (Sprint 5) ✅
- `logical-architect-agent`: Manages Layer→Domain→Object traceability
- `physical-architect-agent`: Maps objects to components and generates ADRs

### Quality & Analytics Agents (Sprint 5) ✅
- `quality-agent`: Enforces quality gates at phase transitions
- `trace-agent`: Maintains traceability and collects feedback

### Infrastructure Agents (Implemented) ✅
- `version-agent`: Git operations and version control

### Delivery Agents (Implemented) ✅
- `code-review-agent`: Reviews code changes and provides feedback
- `test-agent`: Executes and monitors test suites
- `build-agent`: Manages build processes
- `issue-agent`: Manages GitHub issues and project tracking

### Analysis & Design Agents (Existing)
- `architecture-designer`: System design, patterns, quality attributes
- `user-guide-writer`: User documentation, tutorials, help content
- `code-generator-enhanced`: Implementation from specifications
- `conformance-checker`: Architecture validation

## Task Orchestration Protocol
1. **Trivial tasks** (< 5 min): Handle directly
2. **Complex tasks**: Invoke specialized agent(s)
3. **Multi-domain tasks**: Coordinate agent teams
4. **Unknown tasks**: Use architecture-designer first

### CPDM Orchestration (Active)
1. **New features** → Start with `cpdm-workflow-engine.sh start`
2. **Vision updates** → vision-agent → automatic re-prioritization
3. **Design phase** → logical-architect-agent → domain modeling
4. **Decisions** → physical-architect-agent → ADR generation
5. **Quality gates** → quality-agent → automated enforcement
6. **Feedback** → trace-agent → vision updates

### GitHub Integration
- All features create GitHub issues automatically
- ADRs tracked as issues and PRs
- Quality gates tied to PR checks
- Use `gh` CLI or issue-agent for GitHub operations

## Project Structure
See file organization: @docs/FILE-ORGANIZATION-GUIDE.md

## Technology Stack
- **Execution Engine**: Claude Code CLI (agent runtime)
- **UI/Knowledge Base**: Obsidian Desktop App
- **Architecture**: Pure agent-based (no servers/services)
- **Communication**: File-based message queues (JSON)
- **Storage**: File system + SQLite (analytics only)
- **Integration**: MCP servers (GitHub, Obsidian, Context7)
- **Agent Format**: Markdown with YAML frontmatter

## Quality Standards
- Agent behavior validation required
- Message queue reliability > 99%
- File operations must be atomic
- Agent responses < 3 seconds
- Mermaid for all diagrams
- ADR for all architectural decisions
- Clean file organization (see guide)

## Common Commands

### CPDM Commands (New)
- Start feature: `./scripts/cpdm-workflow-engine.sh start "name" "description"`
- Transition phase: `./scripts/cpdm-workflow-engine.sh transition "name"`
- Check status: `./scripts/cpdm-workflow-engine.sh status`
- View metrics: `./scripts/cpdm-workflow-engine.sh metrics`
- Run integration test: `./scripts/integration-test.sh`

### Agent Commands
- Check agents: `ls agents/**/*.md`
- Test message queue: `./scripts/test-queue.sh`
- Validate agents: `./scripts/validate-agents.sh`
- Install agents: `./scripts/install-agents.sh`
- Clean archives: `./scripts/archive-sprint.sh`
- Switch context: `cd ~/workspace/project-name`

## Current Sprint Context
Sprint 1: Foundation (Complete)
- ✅ Repository setup
- ✅ PM system design
- ✅ Architecture methodology
- ✅ Agent analysis
- ✅ Product vision
- ✅ Logical architecture (with vision alignment improvements)
- ✅ Physical architecture planning
- ✅ CLAUDE.md design
- ✅ Issue templates
- ✅ Gap analysis
- ✅ Development setup

Sprint 2: Architecture Readiness (Complete)
- ✅ Goal: Complete physical architecture ready for implementation
- ✅ Timeline: Week 2 (Monday-Friday)
- ✅ Demo: Friday - Architecture walkthrough & Q&A
- ✅ Issues: #20 (Master), #22-26 (Daily tasks)
- ✅ Key deliverables:
  - Agent-based architecture (12 core agents) ✅
  - CLAUDE.md as living orchestration ✅
  - File-based message queues ✅
  - Multi-layer context caching ✅
  - Hybrid Obsidian integration ✅
  - 6 Architecture Decision Records ✅
  - Top 3 detailed design areas identified ✅
- ✅ Critical Insight: Everything is a Claude Code agent (not TypeScript servers)

Sprint 3: Implementation Kickoff (COMPLETE! 🎉)
- 🎯 Goal: Delivery readiness for Claude Code projects
- 📅 Duration: 1 day (vs 10 planned) - 900% velocity!
- ✅ Status: Successfully completed with all objectives achieved
- 📊 Delivered:
  - All 10 core agents implemented and tested
  - Full architecture compliance achieved
  - Message queue v2 with priority routing
  - Obsidian vault created and ready
  - Self-hosting capability demonstrated
- 🏆 Result: 9 days ahead of schedule!

Sprint 4: Development Perfection (COMPLETE! 🎉)
- ✅ Duration: 2 days (vs 5 planned) - 250% velocity!
- ✅ Delivered: Notes app with full agent collaboration
- ✅ Key achievements:
  - Development process documentation
  - Agent capability matrix
  - Real-time metrics dashboard
  - 5 complex workflow patterns
  - Self-improvement agent
- 🏆 Result: Production-ready app at ~/workspace/notes-app

Sprint 5: Architecture Traceability & CPDM (COMPLETE! 🎉)
- ✅ Duration: 10 days - 100% on schedule
- ✅ Delivered: Complete traceability and CPDM methodology
- ✅ Key achievements:
  - 5 new architecture agents (vision, logical, physical, quality, trace)
  - Complete traceability: Vision→Feature→Layer→Domain→Object→Component→Deployment
  - CPDM: 7-phase methodology with quality gates
  - 100% gate automation achieved
  - GitHub-native integration
  - Comprehensive PM documentation
- 🏆 Result: CPDM operational, ready for Sprint 6 test drive

Sprint 6: CPDM Test Drive (PLANNED)
- 🎯 Goal: Validate CPDM from Product Manager perspective
- 📅 Timeline: 5 days (Monday-Friday)
- 🔍 Focus: PM experience with real scenarios
- 📋 Test Scenarios:
  - Day 1: Morning routine & setup
  - Day 2: YOUR vision → Sprint 7 plan
  - Day 3: Quality gate challenges
  - Day 4: Data-driven sprint planning
  - Day 5: Crisis management & review
- ⚠️ Critical: PM defines own vision scenario for Sprint 7

## Issue Management
- Templates: `.github/ISSUE_TEMPLATE/`
- Create issues: Use appropriate template
- Track progress: GitHub Projects
- Link issues: Reference in commits

## Knowledge Base Integration
- Capture insights: Use Obsidian MCP
- Link decisions: Reference ADRs
- Track patterns: Update agent knowledge
- Share learnings: Commit to `/docs/learnings/`

## MCP Servers
- GitHub MCP: Repository operations
- Obsidian MCP: Knowledge management
- Context7 MCP: Latest documentation
- Sequential MCP: Workflow orchestration

## Architecture Principles
1. Domain-driven design
2. Event-driven communication
3. Local-first data
4. Progressive enhancement
5. Agent-oriented architecture

## Sprint 4 Learnings
- **Process First**: Define workflows before implementation
- **Parallel Execution**: 66% time savings with concurrent agents
- **Self-Healing**: 80% automatic error recovery achieved
- **Pattern Reuse**: 3x faster with knowledge-driven development
- **Visual Feedback**: Agent work must be visible to users
- **Quick MVPs**: Use Task tool for rapid prototyping
- **Documentation**: Treat as first-class deliverable

## Sprint 5 Focus Areas
- **Product Vision**: How PO maintains vision → features
- **Logical Architecture**: How features → domains/objects
- **Physical Architecture**: How objects → components/ADRs
- **CPDM**: 7-phase methodology from vision to deployment
- **Traceability**: Bidirectional linking at all levels
- **Quality Gates**: Automated enforcement at each phase

## Self-Maintenance Protocol
- During work: Use `#` to add learnings (auto-updates CLAUDE.md)
- Daily: Update sprint context and active issues
- Weekly: Run `./scripts/maintain-claude-md.sh` for health check
- On mistakes: Use `#` to add prevention directive
- On complexity: Extract sections to imported files
- Always: Keep under 500 lines, action-oriented
- Sprint end: Archive sprint-specific content, update goals

## Import Active Contexts
@docs/architecture/Product Vision.md
@docs/FILE-ORGANIZATION-GUIDE.md