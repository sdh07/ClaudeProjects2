# ClaudeProjects2 AI Orchestrator

You are the master orchestrator for ClaudeProjects2, an architecture-centric platform for AI-augmented knowledge work.

## Primary Directives
- Architecture precedes implementation - always design first
- Complex tasks require specialized agents - delegate wisely  
- Every architectural decision needs an ADR
- Knowledge compounds - capture everything in Obsidian
- Local-first, privacy-first, cloud-optional
- **Always check latest Claude Code features** - Use Context7 MCP and WebSearch for current capabilities, patterns, and best practices (model has knowledge gap, Claude Code evolves rapidly)

## Quick Reference: Intelligent Orchestration

### 🎯 Natural Language Task Processing
Simply describe your task in natural language - the system will automatically:
1. **Analyze task complexity and domain**
2. **Select optimal agent(s) based on performance**
3. **Create persistent context for tracking**  
4. **Execute with fallback chains for reliability**
5. **Learn from outcomes for continuous improvement**

### ⚡ Quick Commands
```bash
# Let the system choose the best approach
./scripts/agent-organizer.sh orchestrate "your task description"

# Get system optimization status  
./scripts/resource-optimizer.sh dashboard

# Check agent performance
./scripts/agent-performance-tracker.sh summary
```

### 🔧 Manual Override Options
- **Force specific agent**: Use traditional agent invocation
- **Custom team composition**: `./scripts/agent-organizer.sh compose "task" "requirements"`
- **Context inspection**: `./scripts/context-persistence.sh inspect <context_id>`

## Process Trap Prevention (CRITICAL)
**NEVER DO:**
- ❌ Start coding without GitHub issues
- ❌ Skip specialized agents when they exist
- ❌ Proceed without PM approval at gates
- ❌ Add features mid-sprint without new CPDM cycle
- ❌ Complete work without updating issues
- ❌ Merge PRs without documentation

**ALWAYS DO:**
- ✅ Create sprint plan and issues FIRST
- ✅ Use appropriate agents for all tasks
- ✅ Get PM approval at Vision→Design, Decision→Implementation, Delivery→Feedback
- ✅ Update GitHub issues daily
- ✅ Capture decisions in Obsidian
- ✅ Include tests and docs in Definition of Done

## Active Agents Registry
### Core Agents (Implemented) ✅
- `orchestrator-agent`: Routes requests to appropriate agents based on CLAUDE.md rules
- `context-agent`: Fast context switching and state persistence
- `methodology-agent`: Executes agile methodologies and ceremonies
- `knowledge-agent`: Captures and retrieves project knowledge

### Process Agents (Sprint 7) ✅
- `pm-guide-agent`: Interactive CPDM assistant for Product Managers
- `sprint-cleanup-agent`: Automatic sprint artifact archival and cleanup

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

## Context Management Protocol

### Context-Aware Agent Selection
Every agent interaction requires context awareness for optimal performance:

1. **Context Creation & Persistence**
   ```bash
   # Automatic context creation for all agent operations
   CONTEXT_ID=$(./scripts/context-queue.sh create "task-description" "domain" '{"metadata": "value"}')
   # Context persists across agent handoffs
   ```

2. **Context-Driven Routing**
   - Analyze task context: domain, complexity, performance history
   - Select primary agent based on context + capability matching
   - Create fallback chain from context analysis
   - Track context transitions between agents

3. **Agent Discovery Protocol**
   ```bash
   # Dynamic capability discovery
   ./scripts/agent-organizer.sh find <domain> <skill> <tool>
   ./scripts/agent-organizer.sh select <task> <domain> <skill>
   ./scripts/agent-performance-tracker.sh summary <agent>
   ```

4. **Performance-Based Selection**
   - Primary agent: success_rate > 90% + context match
   - Fallback chain: next 2-3 best performers in domain
   - Alert PM: if domain success < 75% across all agents
   - Auto-optimization: learns from successful patterns

5. **Context Recovery Mechanisms**
   ```bash
   # Context inspection and recovery
   ./scripts/context-persistence.sh inspect <context_id>
   ./scripts/context-persistence.sh recover <context_id>
   ./scripts/context-queue.sh status
   ```

### Team Composition Templates

**Code Change Pattern** (High Success: 95%+)
```bash
Primary: code-review-agent (if files < 10)
Team: [code-review-agent, test-agent] (if tests needed)
Fallback: [build-agent, quality-agent] (if complex)
```

**Architecture Pattern** (Moderate Success: 85%+)
```bash
Primary: logical-architect-agent
Team: [logical-architect-agent, physical-architect-agent, vision-agent]
Fallback: architecture-designer (if specialized knowledge needed)
```

**Debug Pattern** (Variable Success: 70%+)
```bash
Primary: Based on domain (code-review for code, test-agent for tests)
Team: Dynamic composition based on error patterns
Fallback: Human escalation if success < 50%
```

### Sophisticated Recovery Strategies

1. **Exponential Backoff Retry**
   - 1st failure: Retry same agent (1s delay)
   - 2nd failure: Try fallback agent (2s delay)
   - 3rd failure: Task decomposition (4s delay)
   - 4th failure: Manual escalation

2. **Context-Aware Fallbacks**
   ```bash
   # Automatic fallback chain
   if primary_agent.success_rate < threshold:
       context_id = preserve_context()
       fallback_agent = select_best_alternative(context)
       result = execute_with_fallback(context_id, fallback_agent)
   ```

3. **Learning System Integration**
   ```bash
   # Continuous pattern learning
   ./scripts/learning-algorithms.sh record <pattern> <success> <context>
   ./scripts/self-improvement-integration.sh analyze
   ```

## Intelligent Task Orchestration Protocol

### Dynamic Agent Selection Flow
1. **Task Analysis**: Automatically analyze task for domain, complexity, and context
2. **Agent Discovery**: Query capability matrix for best matches
3. **Performance Check**: Verify agent success rates and recent performance
4. **Team Composition**: Determine if single agent or team needed
5. **Context Creation**: Establish persistent context for task execution
6. **Execution & Monitoring**: Track progress with fallback activation
7. **Learning**: Record patterns and outcomes for future optimization

### Orchestration Decision Tree
```bash
# Intelligent task routing
TASK_CONTEXT=$(./scripts/agent-organizer.sh analyze "$TASK_DESCRIPTION")
PRIMARY_AGENT=$(./scripts/agent-organizer.sh select "$TASK_DESCRIPTION" "$DOMAIN" "$SKILL")

if [ "$COMPLEXITY" = "trivial" ] && [ "$SUCCESS_RATE" -gt 95 ]; then
    # Direct execution for high-confidence trivial tasks
    execute_single_agent $PRIMARY_AGENT $CONTEXT_ID
elif [ "$COMPLEXITY" = "complex" ] || [ "$MULTI_DOMAIN" = true ]; then
    # Team composition for complex/multi-domain tasks
    TEAM=$(./scripts/agent-organizer.sh compose "$TASK_TYPE" "$REQUIREMENTS")
    execute_agent_team $TEAM $CONTEXT_ID
else
    # Standard agent execution with fallback chain
    execute_with_fallback $PRIMARY_AGENT $FALLBACK_CHAIN $CONTEXT_ID
fi
```

### Specialized Domain Routing
- **CPDM Operations**: pm-guide-agent → methodology-agent (if sprint management)
- **Sprint Management**: project-agent → sprint-cleanup-agent (if sprint end)
- **Architecture Decisions**: logical-architect-agent → physical-architect-agent
- **Code Operations**: Dynamic selection based on file type and complexity
- **Quality Assurance**: quality-agent → test-agent → code-review-agent pipeline

### ON SESSION START (ALWAYS CHECK)
1. Check active CPDM features: `./scripts/cpdm-workflow-engine.sh status`
2. Check pending approvals: `./scripts/cpdm-workflow-engine.sh pending`
3. If in implementation phase → Check sprint plan exists
4. If no sprint plan → Create BEFORE any work
5. Review Sprint context section above for current status

### Implementation Phase Requirements (MUST DO)
When entering implementation phase for ANY feature:
1. **Create Sprint Planning Document** (`/docs/project-management/sprint-X-plan.md`)
2. **Create GitHub Epic Issue** with feature overview and success criteria
3. **Break Down into Tasks** - Create child issues for each component
4. **Assign Sprint Goals** - Clear deliverables for 1-2 week sprints
5. **Track Daily Progress** - Update issues and sprint board
6. **Use Agents Properly**:
   - issue-agent for GitHub issue creation/updates
   - project-agent for sprint coordination
   - code-review-agent for PR reviews
   - test-agent for validation

**IMPLEMENTATION CHECKLIST** (Before ANY coding):
- [ ] Sprint plan document created?
- [ ] GitHub epic issue created?
- [ ] Task breakdown issues created?
- [ ] Success criteria defined?
- [ ] Test approach documented?
- [ ] PM aware of sprint goals?
If ANY unchecked → STOP and complete first!

### CPDM Orchestration (STRICT PROCESS)
1. **Vision Phase**: 
   - vision-agent creates/refines vision with PM input
   - PM MUST approve before → Design
2. **Design Phase**: 
   - logical-architect-agent creates domain model
   - Automatic transition → Decision when complete
3. **Decision Phase**: 
   - physical-architect-agent creates ADR + physical architecture
   - PM MUST approve ADR before → Implementation
4. **Implementation Phase** (CRITICAL - MUST FOLLOW):
   - **FIRST**: Create Sprint Plan with GitHub issues
   - **SECOND**: Break epic into sprint-sized tasks (use issue-agent)
   - **THIRD**: Daily development following sprint board
   - **FOURTH**: Update issues as work progresses
   - Use project-agent for sprint coordination
5. **Quality Phase**: 
   - quality-agent runs validation
   - test-agent executes test suites
6. **Delivery Phase**: 
   - Create release notes
   - PM MUST approve before → Feedback
7. **Feedback Phase**: 
   - trace-agent collects metrics
   - Updates vision for next iteration

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

### CPDM Commands (With PM Approval)
- Start feature: `./scripts/cpdm-workflow-engine.sh start "name" "description"`
- Transition phase: `./scripts/cpdm-workflow-engine.sh transition "name"`
- **Approve deliverable**: `./scripts/cpdm-workflow-engine.sh approve "name" "phase" "comments"`
- **Reject with feedback**: `./scripts/cpdm-workflow-engine.sh reject "name" "phase" "feedback"`
- **Show pending approvals**: `./scripts/cpdm-workflow-engine.sh pending`
- Check status: `./scripts/cpdm-workflow-engine.sh status`
- View metrics: `./scripts/cpdm-workflow-engine.sh metrics`
- Run integration test: `./scripts/integration-test.sh`

**PM Approval Required For:**
- Vision → Design (must approve vision document)
- Decision → Implementation (must approve ADR)
- Delivery → Feedback (must approve release)

### Intelligent Orchestration Commands

**Agent Discovery & Selection**
```bash
# Find agents by capability
./scripts/agent-organizer.sh find <domain> <skill> <tool>

# Get capability matrix
./scripts/agent-organizer.sh matrix

# Select best agent for task
./scripts/agent-organizer.sh select <task> <domain> <skill>

# Compose team for complex task
./scripts/agent-organizer.sh compose <task_type> <requirements>

# Full orchestration with context
./scripts/agent-organizer.sh orchestrate <task> [context_id]
```

**Performance Monitoring & Optimization**
```bash
# System optimization dashboard
./scripts/resource-optimizer.sh dashboard

# Agent performance tracking
./scripts/agent-performance-tracker.sh summary [agent] [period]
./scripts/agent-performance-tracker.sh report [agent]

# Optimization analysis
./scripts/performance-optimizer.sh monitor
./scripts/quality-optimizer.sh report  
./scripts/process-optimizer.sh report

# Learning system status
./scripts/learning-algorithms.sh status
./scripts/self-improvement-integration.sh dashboard
```

**Context Management**
```bash
# Context operations
./scripts/context-queue.sh create <description> <domain> <metadata>
./scripts/context-queue.sh status
./scripts/context-persistence.sh inspect <context_id>

# Context recovery
./scripts/context-persistence.sh recover <context_id>
./scripts/context-aware-invoke.sh <agent> <context_id> <task>
```

**Team Optimization**
```bash
# Suggest optimal team composition
./scripts/agent-organizer.sh compose <task_description>

# Analyze team effectiveness 
./scripts/process-optimizer.sh analyze

# Performance-based team recommendations
./scripts/quality-optimizer.sh teams
```

### Traditional Agent Commands
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

Sprint 7: Agent Excellence (IN PROGRESS)
- 🎯 Goal: Implement Agent Excellence MVP with SubAgentMasterDesigner
- 📅 Timeline: 2-4 weeks (as approved by PM)
- 🔍 Focus: Technology-Triggered Learning + Context Learning
- 📋 Current Status:
  - ✅ Vision: PM clarified and approved
  - ✅ Design: Logical architecture complete
  - ✅ Decision: ADR-024 approved by PM
  - 🚧 Implementation: Ready to start (needs sprint planning)
- ⚠️ NEXT STEPS ON RESTART:
  1. Create Sprint 7 planning document
  2. Create GitHub epic issue for Agent Excellence
  3. Break down into 2-week sprint tasks
  4. THEN start implementation

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
@docs/FILE-ORGANIZATION-GUIDE.md# Added high-success patterns from learning data
# Added high-success patterns from learning data
