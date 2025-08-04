# Domain Business Logic

> Deep dive into the business rules and interactions within each domain. For domain overview, see [Layers](Layers.md#domain-layer---triple-helix-core).

## High-Level Domain Interactions

```mermaid
graph TB
    USER[User Domain]
    WORK[Workspace]
    PROJ[Project Domain]
    METH[Methodology Domain]
    AGENT[Agent Domain]
    KNOW[Knowledge Domain]
    MARKET[Marketplace Domain]
    
    USER -->|owns| WORK
    WORK -->|contains| PROJ
    PROJ -->|follows| METH
    PROJ -->|employs| AGENT
    PROJ -->|generates| KNOW
    KNOW -->|improves| METH
    METH -->|guides| AGENT
    AGENT -->|creates| KNOW
    MARKET -->|provides| METH
    MARKET -->|provides| AGENT
    USER -->|contributes to| MARKET
    
    style USER fill:#fce4ec,stroke:#c2185b
    style WORK fill:#f8bbd0,stroke:#ad1457
    style PROJ fill:#e8f5e9,stroke:#2e7d32
    style METH fill:#e3f2fd,stroke:#1976d2
    style AGENT fill:#f3e5f5,stroke:#7b1fa2
    style KNOW fill:#fff3e0,stroke:#f57c00
    style MARKET fill:#e1bee7,stroke:#6a1b9a
```

## Domain Details

<details>
<summary><b>👤 User Domain</b> - Identity, preferences, and growth</summary>

### Business Rules
- Users must authenticate before accessing workspace
- Each user owns exactly one workspace
- User preferences cascade to all their projects
- Growth level unlocks advanced features
- Users can share individual projects with others

### Growth Journey

```mermaid
stateDiagram-v2
    [*] --> Novice: First Login
    Novice --> Practitioner: Complete 5 Projects
    Practitioner --> Expert: Complete 20 Projects
    Expert --> Master: Complete 50 Projects
    Master --> Leader: Create Methodology
    
    Novice: Access to templates
    Practitioner: Choose methodologies
    Expert: Customize workflows
    Master: Create project types
    Leader: Share & monetize
```

### Permission Model
- **Owner**: Full control over own workspace
- **Collaborator**: Can edit shared projects
- **Viewer**: Read-only access to shared projects
- **Guest**: Limited access to specific deliverables

</details>

<details>
<summary><b>📂 Workspace Domain</b> - Project organization and team collaboration</summary>

### Business Rules
- One workspace per user (personal workspace)
- Project types are workspace-specific
- Projects can be shared individually
- Resource limits apply per workspace
- All user activity happens within their workspace

### Workspace Hierarchy

```mermaid
graph TB
    W[Workspace]
    
    subgraph "Configuration"
        PT[Project Types]
        TEMP[Templates]
        SET[Settings]
    end
    
    subgraph "Projects"
        P1[Active Projects]
        P2[Archived Projects]
    end
    
    subgraph "Collaboration"
        TEAM[Team Members]
        PERM[Permissions]
    end
    
    W --> Configuration
    W --> Projects
    W --> Collaboration
    
    PT --> P1
```

### Workspace Operations
- **Create Project**: From project type template
- **Work on Projects**: Execute methodologies with agents
- **Manage Project Types**: Create and customize types
- **Archive Projects**: Preserve but deactivate
- **Share Projects**: Grant access to specific projects
- **Export/Import**: Backup or migrate workspace data

</details>

<details>
<summary><b>📁 Project Domain</b> - Value creation through methodology execution</summary>

### Business Rules
- Projects must be created from a project type
- Cannot execute without assigned methodology
- All deliverables must be living documents
- Productivity metrics tracked automatically
- Knowledge capture is continuous, not post-hoc

### Project Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Created: From Type
    Created --> Planned: Methodology Selected
    Planned --> Active: Execution Started
    Active --> Paused: Temporary Hold
    Paused --> Active: Resume
    Active --> Completed: Goals Achieved
    Completed --> Archived: Knowledge Captured
    
    Active --> Active: Phase Transitions
    
    note right of Active
        Managed by integrated
        Agile PM system with
        sprints and tasks
    end note
```

### Productivity Measurement

```mermaid
graph LR
    subgraph "Traditional Baseline"
        T1[40 hours]
        T2[3 revisions]
        T3[60% reuse]
    end
    
    subgraph "With ClaudeProjects"
        C1[4 hours]
        C2[0 revisions]
        C3[85% reuse]
    end
    
    subgraph "10x Metrics"
        M1[10x Speed]
        M2[3x Quality]
        M3[1.4x Reuse]
    end
    
    T1 --> M1
    C1 --> M1
    T2 --> M2
    C2 --> M2
    T3 --> M3
    C3 --> M3
    
    style M1 fill:#4caf50,color:#fff
    style M2 fill:#4caf50,color:#fff
    style M3 fill:#4caf50,color:#fff
```

### Living Deliverables
- Auto-update when source data changes
- Version history with explanations
- Proactive refresh suggestions
- Cross-project synchronization

### Project Management Integration
- **Agile PM**: Built-in sprint planning and tracking
- **Task Management**: Break down methodology phases into tasks
- **Agent Assignment**: Assign tasks to appropriate AI agents
- **Progress Tracking**: Real-time visibility into project status
- **Sprint Reviews**: Automated retrospectives with insights

</details>

<details>
<summary><b>🎯 Project Types</b> - Reusable project configurations</summary>

### Business Rules
- Built-in types cannot be deleted
- Custom types can extend OR be completely new
- Types define default methodology
- Types specify agent team composition
- Types are private to workspace (future: marketplace)

### Type Inheritance

```mermaid
graph TB
    subgraph "System Types"
        BASE[Base Project Type]
        DS[Design Sprint]
        SALES[Sales Campaign]
        MKT[Marketing Campaign]
    end
    
    subgraph "Custom Types"
        CDS[My Design Sprint]
        CSALES[Enterprise Sales]
    end
    
    BASE --> DS
    BASE --> SALES
    BASE --> MKT
    DS --> CDS
    SALES --> CSALES
    
    style BASE fill:#e3f2fd
    style CDS fill:#ce93d8
    style CSALES fill:#ce93d8
```

### Type Components
- **Methodology**: Default workflow
- **Agent Team**: Pre-assigned specialists
- **Templates**: Starting documents
- **Metrics**: Success criteria
- **Settings**: Project defaults

</details>

<details>
<summary><b>📚 Methodology Domain</b> - Executable best practices</summary>

### Business Rules
- Methodologies have mandatory phases
- Quality gates cannot be skipped
- Each phase has success criteria
- Methodologies learn from outcomes
- Custom methodologies require validation

### Methodology Evolution

```mermaid
graph LR
    V1[Version 1.0]
    USE1[Project Uses]
    LEARN1[Capture Learnings]
    V2[Version 1.1]
    USE2[More Projects]
    LEARN2[Pattern Detection]
    V3[Version 2.0]
    
    V1 --> USE1
    USE1 --> LEARN1
    LEARN1 --> V2
    V2 --> USE2
    USE2 --> LEARN2
    LEARN2 --> V3
    
    style V1 fill:#bbdefb
    style V2 fill:#90caf9
    style V3 fill:#64b5f6
```

### Quality Gates
- **Entry Criteria**: Prerequisites met
- **Phase Validation**: Deliverables complete
- **Exit Criteria**: Quality standards met
- **Automated Checks**: AI validation
- **Human Override**: With justification

### Methodology Library
| Category | Count | Examples |
|----------|-------|----------|
| Innovation | 5 | Design Sprint, Double Diamond, Jobs-to-be-Done |
| Sales | 4 | MEDDIC, Challenger, Solution Selling, SPIN |
| Marketing | 6 | Growth Hacking, Content Strategy, ABM |
| Development | 5 | Agile, Waterfall, DDD, TDD, DevOps |
| Consulting | 4 | McKinsey 7S, BCG Matrix, Blue Ocean |

</details>

<details>
<summary><b>🏪 Marketplace Domain</b> - Community sharing and discovery</summary>

### Business Rules
- All shared content must pass quality validation
- Methodologies and agents can be published independently
- Publishers maintain ownership but grant usage rights
- Community ratings help surface quality content
- Versioning ensures compatibility

### Marketplace Components

```mermaid
graph TB
    subgraph "Repository"
        METH_REPO[Methodology Repository]
        AGENT_REPO[Agent Repository]
        TMPL_REPO[Template Repository]
    end
    
    subgraph "Discovery"
        SEARCH[Search Engine]
        REC[Recommendation Engine]
        CAT[Category Browser]
    end
    
    subgraph "Quality"
        VAL[Validation Service]
        TEST[Testing Framework]
        CERT[Certification Process]
    end
    
    subgraph "Community"
        RATE[Ratings & Reviews]
        DISC[Discussions]
        CONTRIB[Contributor Profiles]
    end
```

### Publishing Workflow

```mermaid
stateDiagram-v2
    [*] --> Draft: Create Content
    Draft --> Submitted: Submit for Review
    Submitted --> Testing: Automated Tests
    Testing --> Review: Community Review
    Review --> Approved: Pass Quality Gates
    Review --> Rejected: Fail Quality Gates
    Rejected --> Draft: Fix Issues
    Approved --> Published: Available in Marketplace
    Published --> Updated: New Version
    Updated --> Testing: Re-validate
```

### Discovery Features
- **Search**: Full-text and semantic search
- **Categories**: Browse by domain, complexity, use case
- **Recommendations**: Based on user profile and project history
- **Trending**: Popular and newly featured content
- **Collections**: Curated sets for specific industries

### Quality Assurance
- **Automated Testing**: Syntax validation, compatibility checks
- **Community Review**: Peer validation process
- **Usage Analytics**: Track effectiveness metrics
- **Continuous Monitoring**: Flag degraded quality
- **Version Compatibility**: Ensure backward compatibility

</details>

<details>
<summary><b>🤖 Agent Domain</b> - Specialized AI workforce with context management</summary>

### Business Rules
- Agents have defined specializations
- Teams form based on methodology needs
- Agents can work in parallel
- Performance tracked per agent
- Agents improve through usage
- Context persists across sessions
- Context evolves based on outcomes

### Agent Specialization Matrix

```mermaid
graph TB
    subgraph "By Domain"
        D1[Innovation Agents]
        D2[Sales Agents]
        D3[Marketing Agents]
        D4[Technical Agents]
    end
    
    subgraph "By Function"
        F1[Research Agents]
        F2[Analysis Agents]
        F3[Creative Agents]
        F4[Builder Agents]
    end
    
    subgraph "By Role"
        R1[Lead Agents]
        R2[Support Agents]
        R3[Review Agents]
        R4[Integration Agents]
    end
    
    TASK[Project Task]
    TASK --> D1
    TASK --> F1
    TASK --> R1
```

### Team Formation Rules
- Methodology specifies required roles
- System matches best available agents
- Parallel execution when possible
- Automatic workload balancing
- Fallback agents for availability

### Performance Tracking
- Task completion time
- Output quality scores
- Collaboration effectiveness
- Learning rate
- User satisfaction

### Agent Context Management

```mermaid
graph TB
    subgraph "Context Types"
        WORK[Working Memory]
        PROJ[Project Context]
        LEARN[Learning Context]
        COLLAB[Collaboration Context]
    end
    
    subgraph "Context Operations"
        SWITCH[Context Switching]
        PERSIST[Context Persistence]
        SHARE[Context Sharing]
        EVOLVE[Context Evolution]
    end
    
    AGENT[Agent Core] --> WORK
    AGENT --> PROJ
    AGENT --> LEARN
    AGENT --> COLLAB
    
    WORK --> SWITCH
    PROJ --> PERSIST
    COLLAB --> SHARE
    LEARN --> EVOLVE
```

### Context Components

#### Working Memory
- **Current Task**: Active goal and progress
- **Recent Actions**: Last N operations for continuity
- **Temporary State**: Session-specific information
- **Active Tools**: Currently loaded capabilities

#### Project Context
- **Project History**: All past interactions on project
- **Methodology State**: Current phase and progress
- **Deliverables**: Generated artifacts and documents
- **Decisions**: Key choices and rationale

#### Learning Context
- **Performance Metrics**: Success/failure patterns
- **Effective Strategies**: What worked well
- **User Preferences**: Learned style preferences
- **Domain Knowledge**: Accumulated expertise

#### Collaboration Context
- **Team State**: Other agents' current work
- **Handoff Points**: Clear transition information
- **Shared Goals**: Team objectives
- **Communication History**: Inter-agent messages

### Context Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Initialize: Agent Activated
    Initialize --> Load: Restore Context
    Load --> Active: Working
    Active --> Save: Checkpoint
    Save --> Active: Continue
    Active --> Handoff: Team Collaboration
    Handoff --> Active: Resume
    Active --> Complete: Task Done
    Complete --> Persist: Store Learning
    Persist --> [*]
    
    note right of Save
        Periodic saves ensure
        no context loss
    end note
```

### Context Evolution Mechanism
- **Pattern Recognition**: Identify successful approaches
- **Preference Learning**: Adapt to user style
- **Knowledge Accumulation**: Build domain expertise
- **Performance Optimization**: Improve based on metrics
- **Collaborative Learning**: Learn from team interactions

</details>

<details>
<summary><b>🧠 Knowledge Domain</b> - Living organizational memory</summary>

### Business Rules
- All project artifacts become knowledge
- Knowledge links automatically form
- Patterns emerge from usage
- Insights proactively surface
- Privacy controls respect boundaries

### Knowledge Flow

```mermaid
graph TB
    subgraph "Capture"
        C1[Project Decisions]
        C2[Agent Outputs]
        C3[User Actions]
        C4[Outcomes]
    end
    
    subgraph "Process"
        P1[Extract Patterns]
        P2[Find Connections]
        P3[Generate Insights]
    end
    
    subgraph "Apply"
        A1[Improve Methods]
        A2[Train Agents]
        A3[Suggest Actions]
    end
    
    C1 --> P1
    C2 --> P1
    C3 --> P2
    C4 --> P3
    
    P1 --> A1
    P2 --> A2
    P3 --> A3
```

### Living Document Features
- **Auto-Update**: When sources change
- **Version Intelligence**: Explain why changed
- **Cross-Reference**: Link related docs
- **Predictive Updates**: Suggest refreshes
- **Quality Decay**: Flag stale content

### Organizational Learning
- Success pattern recognition
- Failure analysis and prevention
- Best practice extraction
- Predictive recommendations
- Knowledge gap identification

</details>

## Cross-Domain Interactions

### The Triple Helix in Action

```mermaid
sequenceDiagram
    participant User
    participant Project
    participant Methodology
    participant Agents
    participant Knowledge
    
    User->>Project: Start new project
    Project->>Methodology: Load methodology
    Methodology->>Agents: Define team needs
    Agents->>Project: Execute phases
    Project->>Knowledge: Capture outputs
    Knowledge->>Methodology: Improve process
    Methodology->>Agents: Update guidance
    
    Note over Knowledge: Continuous improvement cycle
```

### Event-Driven Coordination
- **Project Events**: Trigger methodology phases
- **Methodology Events**: Activate agent teams
- **Agent Events**: Generate knowledge
- **Knowledge Events**: Evolve methodologies
- **User Events**: Personalize experience

## Business Value Streams

### Time-to-Value Acceleration
Traditional: Research → Design → Build → Test → Deploy (weeks)  
ClaudeProjects: All phases parallel with AI agents (hours)

### Quality Improvement
Traditional: Multiple revision cycles, defects found late  
ClaudeProjects: First-time quality through methodology enforcement

### Knowledge Compound Effect
Traditional: Knowledge lost between projects  
ClaudeProjects: Every project makes the next one better

## Next Steps

- Review [Cross-Cutting Concerns](Cross-Cutting.md) for system-wide features
- Explore [Quality Attributes](Quality-Attributes.md) for performance requirements
- See [Flows](Flows.md) for detailed execution examples