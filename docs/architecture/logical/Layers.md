# Architectural Layers

Each layer has a specific responsibility in delivering 10x productivity gains.

## Presentation Layer - "Democratize Excellence"

### Purpose
Make expert-level capabilities accessible to all users through intuitive interfaces.

### High-Level View

```mermaid
graph LR
    User((User))
    
    CP[ClaudeProjects UI]
    PROG[Progressive Experience]
    
    User --> CP
    User --> PROG
    
    CP --> APP[Application Layer]
    PROG --> APP
    
    style User fill:#fff,stroke:#333,stroke-width:3px
    style CP fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    style PROG fill:#e8f5e9,stroke:#388e3c,stroke-width:2px
    style APP fill:#f5f5f5,stroke:#666,stroke-width:1px,stroke-dasharray: 5 5
```

### Component Details

<details>
<summary><b>💻 ClaudeProjects UI</b> - Natural language and visual canvas</summary>

```mermaid
graph TB
    subgraph "Natural Language"
        TEXT[Text Chat]
        VOICE[Voice Commands]
        SUGGEST[AI Suggestions]
    end
    
    subgraph "Knowledge Canvas"
        DASH[Living Dashboards]
        KG[Knowledge Graph]
        FLOW[Methodology Flows]
        MON[Agent Monitor]
    end
    
    TEXT --> APP[Application Layer]
    VOICE --> APP
    DASH --> APP
    KG --> APP
    
    style TEXT fill:#e3f2fd
    style VOICE fill:#e3f2fd
    style SUGGEST fill:#e3f2fd
    style DASH fill:#f3e5f5
    style KG fill:#f3e5f5
    style FLOW fill:#f3e5f5
    style MON fill:#f3e5f5
```

**Key Features:**
- **Natural Language**: Conversational interface with text and voice
- **Knowledge Canvas**: Visual workspace for exploring and managing knowledge
- **Living Dashboards**: Real-time project status and metrics
- **Agent Monitor**: Visibility into AI agent activities
- **Context Preservation**: Seamless switching between UI modes

</details>

<details>
<summary><b>📈 Progressive Experience</b> - Grows with user expertise</summary>

```mermaid
graph LR
    BEG[Beginner] --> PRO[Professional]
    PRO --> EXP[Expert]
    EXP --> API[Developer]
    
    BEG -.-> T1[Templates]
    PRO -.-> T2[Methodologies]
    EXP -.-> T3[Custom Workflows]
    API -.-> T4[Automation]
    
    style BEG fill:#c8e6c9
    style PRO fill:#81c784
    style EXP fill:#4caf50
    style API fill:#2e7d32
```

**Growth Path:**
1. **Beginner**: Guided templates, simple tasks
2. **Professional**: Full methodology controls
3. **Expert**: Custom agent orchestration
4. **Developer**: API automation

</details>

### Interaction Flow

```mermaid
sequenceDiagram
    participant User
    participant NLI as Natural Language
    participant CTX as Context Engine
    participant SUGG as Suggestion Engine
    participant APP as Application Layer
    
    User->>NLI: "Create innovation sprint"
    NLI->>CTX: Parse intent & context
    CTX->>SUGG: Get relevant suggestions
    SUGG-->>User: "Similar projects used Design Sprint"
    User->>NLI: "Yes, use Design Sprint"
    NLI->>APP: Execute methodology request
    APP-->>User: Real-time progress updates
```

### Progressive Enhancement Model

```mermaid
graph LR
    subgraph "User Journey"
        A[First Use] --> B[Guided Templates]
        B --> C[Methodology Selection]
        C --> D[Custom Workflows]
        D --> E[Agent Orchestration]
        E --> F[API Automation]
    end
    
    subgraph "Interface Evolution"
        A -.-> G[Simple UI]
        C -.-> H[Advanced Controls]
        E -.-> I[Expert Dashboard]
        F -.-> J[Developer Tools]
    end
    
    style A fill:#e1f5fe
    style B fill:#b3e5fc
    style C fill:#81d4fa
    style D fill:#4fc3f7
    style E fill:#29b6f6
    style F fill:#039be5
```

---

## Application Layer - "10x Productivity Engine"

### Purpose
Orchestrate the Triple Helix to deliver order-of-magnitude productivity gains.

### High-Level View

```mermaid
graph TB
    PRES[Presentation Layer]
    
    MO[Master Orchestrator]
    ME[Methodology Engine]
    AC[Agent Coordinator]
    KS[Knowledge Synthesizer]
    PM[Project Manager]
    SYNC[Synchronization Service]
    
    PRES --> MO
    MO --> ME
    MO --> AC
    MO --> KS
    MO --> PM
    MO --> SYNC
    
    DOM[Domain Layer]
    
    ME --> DOM
    AC --> DOM
    KS --> DOM
    PM --> DOM
    SYNC --> DOM
    
    style PRES fill:#f5f5f5,stroke:#666,stroke-width:1px,stroke-dasharray: 5 5
    style MO fill:#e1f5fe,stroke:#0288d1,stroke-width:3px
    style ME fill:#f3e5f5,stroke:#6a1b9a,stroke-width:2px
    style AC fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style KS fill:#fff3e0,stroke:#e65100,stroke-width:2px
    style PM fill:#e0f2f1,stroke:#00695c,stroke-width:2px
    style SYNC fill:#e1bee7,stroke:#6a1b9a,stroke-width:2px
    style DOM fill:#f5f5f5,stroke:#666,stroke-width:1px,stroke-dasharray: 5 5
```

### Service Details

<details>
<summary><b>🎯 Master Orchestrator</b> - Central command and control</summary>

```mermaid
graph TB
    REQ[User Request]
    
    IA[Intent Analyzer]
    MS[Methodology Selector]
    TF[Team Former]
    PM[Progress Monitor]
    
    REQ --> IA
    IA --> MS
    MS --> TF
    TF --> PM
    PM --> RES[Results]
    
    style REQ fill:#fff,stroke:#333
    style IA fill:#b3e5fc
    style MS fill:#b3e5fc
    style TF fill:#b3e5fc
    style PM fill:#b3e5fc
    style RES fill:#fff,stroke:#333
```

**Responsibilities:**
- Understand user intent
- Select best methodology
- Form specialist teams
- Monitor execution
- Deliver results

</details>

<details>
<summary><b>📚 Methodology Engine</b> - Executable best practices</summary>

```mermaid
graph LR
    LIB[(Method Library)]
    
    DS[Design Sprint]
    MED[MEDDIC]
    AGI[Agile]
    MORE[20+ More]
    
    LIB --> DS
    LIB --> MED
    LIB --> AGI
    LIB --> MORE
    
    EX[Execution Engine]
    DS --> EX
    
    style LIB fill:#e1bee7
    style EX fill:#ce93d8
```

**Features:**
- 20+ pre-built methodologies
- Quality gates enforcement
- Continuous improvement
- Custom methodology creation

</details>

<details>
<summary><b>👥 Agent Coordinator</b> - AI team management</summary>

```mermaid
graph TB
    TASK[Task]
    
    CAP[Capability Matching]
    TEAM[Team Formation]
    WORK[Workload Balance]
    
    TASK --> CAP
    CAP --> TEAM
    TEAM --> WORK
    
    A1[Agent 1]
    A2[Agent 2]
    A3[Agent 3]
    
    WORK --> A1
    WORK --> A2
    WORK --> A3
    
    style CAP fill:#c8e6c9
    style TEAM fill:#c8e6c9
    style WORK fill:#c8e6c9
```

**Capabilities:**
- Match tasks to specialists
- Form dynamic teams
- Balance workloads
- Track performance

</details>

<details>
<summary><b>🧠 Knowledge Synthesizer</b> - Living knowledge system</summary>

```mermaid
graph TB
    CAP[Capture]
    DET[Detect Patterns]
    GEN[Generate Insights]
    UPD[Update Docs]
    
    CAP --> DET
    DET --> GEN
    GEN --> UPD
    UPD -.-> CAP
    
    style CAP fill:#ffe0b2
    style DET fill:#ffe0b2
    style GEN fill:#ffe0b2
    style UPD fill:#ffe0b2
```

**Functions:**
- Auto-documentation
- Pattern detection
- Insight generation
- Living documents

</details>

<details>
<summary><b>📋 Project Manager</b> - Agile project tracking</summary>

```mermaid
graph TB
    PROJ[Project]
    
    SPRINT[Sprint Planning]
    TASK[Task Management]
    TRACK[Progress Tracking]
    REPORT[Status Reports]
    
    PROJ --> SPRINT
    SPRINT --> TASK
    TASK --> TRACK
    TRACK --> REPORT
    
    style SPRINT fill:#b2dfdb
    style TASK fill:#80cbc4
    style TRACK fill:#4db6ac
    style REPORT fill:#26a69a
```

**Features:**
- Sprint planning & tracking
- Task assignment to agents
- Progress visualization
- Burndown charts
- Status reporting
- Blocker management

</details>

<details>
<summary><b>🔄 Synchronization Service</b> - Multi-user collaboration & offline support</summary>

```mermaid
graph TB
    SYNC[Sync Service]
    
    STATE[State Manager]
    CONFLICT[Conflict Resolver]
    QUEUE[Sync Queue]
    DETECT[Change Detector]
    
    SYNC --> STATE
    SYNC --> CONFLICT
    SYNC --> QUEUE
    SYNC --> DETECT
    
    subgraph "Sync Targets"
        PROJ[Projects]
        KNOW[Knowledge]
        WORK[Workspaces]
    end
    
    QUEUE --> PROJ
    QUEUE --> KNOW
    QUEUE --> WORK
    
    style SYNC fill:#e1bee7,stroke:#6a1b9a,stroke-width:2px
    style STATE fill:#f3e5f5
    style CONFLICT fill:#f3e5f5
    style QUEUE fill:#f3e5f5
    style DETECT fill:#f3e5f5
```

**Capabilities:**
- **State Management**: Track online/offline status, local changes
- **Conflict Resolution**: Automatic and manual merge strategies
- **Queue Management**: Prioritized sync operations
- **Change Detection**: Efficient diff algorithms
- **Real-time Collaboration**: Live updates for shared projects

**Sync Strategies:**
- **Optimistic Updates**: Apply locally, sync eventually
- **Conflict-Free Replicated Data Types (CRDTs)**: For collaborative editing
- **Priority Queuing**: Critical changes sync first
- **Batch Operations**: Efficient network usage

</details>

### Orchestration Flow

```mermaid
sequenceDiagram
    participant User
    participant MO as Master Orchestrator
    participant ME as Methodology Engine
    participant AC as Agent Coordinator
    participant KS as Knowledge Synthesizer
    participant Agents as Agent Team
    
    User->>MO: Project request
    MO->>ME: Select methodology
    ME-->>MO: Design Sprint selected
    MO->>AC: Form specialist team
    AC-->>MO: Team ready (5 agents)
    
    par Parallel Execution
        MO->>Agents: Execute Phase 1
        Agents->>KS: Capture insights
    and
        MO->>Agents: Execute Phase 2
        Agents->>KS: Document decisions
    end
    
    KS->>MO: Synthesized results
    MO-->>User: Living deliverables
```

### Productivity Multipliers

```mermaid
graph LR
    subgraph "Traditional Process"
        T1[Sequential Tasks] --> T2[Manual Handoffs]
        T2 --> T3[Context Loss]
        T3 --> T4[Rework]
        T4 --> T5[40 Hours]
    end
    
    subgraph "ClaudeProjects Process"
        C1[Parallel Agents] --> C2[Automated Flow]
        C2 --> C3[Context Preserved]
        C3 --> C4[First-Time Quality]
        C4 --> C5[4 Hours]
    end
    
    T5 -.->|10x Faster| C5
    
    style T5 fill:#ffcdd2
    style C5 fill:#c8e6c9
```

---

## Domain Layer - "Triple Helix Core"

### Purpose
Implement core business logic that powers the Triple Helix innovation.

### High-Level View

```mermaid
graph TB
    APP[Application Layer]
    
    USER[User Domain]
    WORK[Workspace]
    PROJ[Project Domain]
    METH[Methodology Domain]
    AGENT[Agent Domain]
    KNOW[Knowledge Domain]
    MARKET[Marketplace Domain]
    
    APP --> USER
    USER --> WORK
    WORK --> PROJ
    PROJ --> METH
    PROJ --> AGENT
    PROJ --> KNOW
    MARKET --> METH
    MARKET --> AGENT
    USER --> MARKET
    
    INFRA[Infrastructure Layer]
    
    USER --> INFRA
    WORK --> INFRA
    PROJ --> INFRA
    METH --> INFRA
    AGENT --> INFRA
    KNOW --> INFRA
    MARKET --> INFRA
    
    style APP fill:#f5f5f5,stroke:#666,stroke-width:1px,stroke-dasharray: 5 5
    style USER fill:#fce4ec,stroke:#c2185b,stroke-width:2px
    style WORK fill:#f8bbd0,stroke:#ad1457,stroke-width:2px
    style PROJ fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style METH fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    style AGENT fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    style KNOW fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    style MARKET fill:#e1bee7,stroke:#6a1b9a,stroke-width:2px
    style INFRA fill:#f5f5f5,stroke:#666,stroke-width:1px,stroke-dasharray: 5 5
```

### Domain Details

<details>
<summary><b>👤 User Domain</b> - Identity and preferences</summary>

```mermaid
graph TB
    U[User]
    W[Workspace]
    PREF[Preferences]
    HIST[History]
    
    U --> W
    U --> PREF
    U --> HIST
    W --> PROJ[Projects]
    
    style U fill:#ffcdd2,stroke:#c2185b,stroke-width:2px
    style W fill:#f8bbd0,stroke:#ad1457,stroke-width:2px
```

**Key Concepts:**
- User identity & auth
- Personal preferences
- Learning history
- Workspace ownership

</details>

<details>
<summary><b>📂 Workspace</b> - Project container</summary>

```mermaid
graph TB
    W[Workspace]
    PT[Project Types]
    P1[Project 1]
    P2[Project 2]
    P3[Project N]
    
    W --> PT
    PT --> P1
    PT --> P2
    PT --> P3
    
    W --> SET[Settings]
    W --> CPT[Custom Types]
    W --> TEAM[Teams]
    
    style W fill:#f8bbd0,stroke:#ad1457,stroke-width:2px
    style PT fill:#ce93d8,stroke:#8e24aa,stroke-width:2px
    style P1 fill:#c8e6c9
    style P2 fill:#c8e6c9
    style P3 fill:#c8e6c9
```

**Workspace Features:**
- Project type library
- Custom project types
- Shared settings & templates
- Team collaboration space
- Resource management

</details>

<details>
<summary><b>📁 Project Domain</b> - Value creation hub</summary>

```mermaid
graph TB
    W[Workspace]
    PT[Project Type]
    P[Project]
    M[Methodology]
    A[Agents]
    K[Knowledge]
    MET[Metrics]
    
    W --> PT
    PT --> P
    P --> M
    P --> A
    P --> K
    P --> MET
    
    MET --> PROD[10x Productivity]
    
    style W fill:#f8bbd0,stroke:#ad1457
    style PT fill:#ce93d8,stroke:#8e24aa
    style P fill:#a5d6a7,stroke:#2e7d32,stroke-width:2px
    style PROD fill:#4caf50,color:#fff
```

**Core Functions:**
- Created from project types
- Lives within workspace
- Execute methodologies
- Coordinate agents
- Capture knowledge
- Measure 10x gains

</details>

<details>
<summary><b>🎯 Project Types</b> - Reusable project templates</summary>

```mermaid
graph LR
    subgraph "Built-in Types"
        DS[Design Sprint]
        SC[Sales Campaign]
        MC[Marketing Campaign]
        SD[Software Development]
    end
    
    subgraph "Custom Types"
        CT1[My Innovation Process]
        CT2[Team Retrospective]
        CT3[Client Onboarding]
    end
    
    NEW[New Project]
    DS --> NEW
    CT1 --> NEW
    
    style DS fill:#bbdefb
    style SC fill:#bbdefb
    style CT1 fill:#ce93d8
    style CT2 fill:#ce93d8
    style NEW fill:#a5d6a7
```

**Features:**
- Pre-configured methodologies
- Default agent teams
- Template deliverables
- Custom type creation
- Type sharing & export

</details>

<details>
<summary><b>📚 Methodology Domain</b> - Executable excellence</summary>

```mermaid
graph LR
    subgraph "Available Methods"
        DS[Design Sprint]
        MED[MEDDIC]
        AGI[Agile]
        MORE[17+ More]
    end
    
    EX[Execute]
    LEA[Learn & Improve]
    
    DS --> EX
    EX --> LEA
    LEA -.-> DS
    
    style DS fill:#bbdefb
    style EX fill:#90caf9
    style LEA fill:#64b5f6
```

**Categories:**
- Innovation (Design Sprint, Double Diamond)
- Sales (MEDDIC, Challenger)
- Marketing (Growth, Content)
- Development (Agile, DDD)

</details>

<details>
<summary><b>🤖 Agent Domain</b> - Specialized workforce</summary>

```mermaid
graph TB
    subgraph "Agent Types"
        RES[Research]
        CRE[Creative]
        ANA[Analysis]
        BUI[Builder]
    end
    
    TASK[Task]
    TASK --> RES
    TASK --> CRE
    
    TEAM[Form Team]
    RES --> TEAM
    CRE --> TEAM
    
    style RES fill:#e1bee7
    style CRE fill:#e1bee7
    style TEAM fill:#ba68c8,color:#fff
```

**Specializations:**
- Domain experts
- Process specialists
- Collaboration roles
- Quality assurance

</details>

<details>
<summary><b>🧠 Knowledge Domain</b> - Living memory</summary>

```mermaid
graph TB
    CAP[Capture]
    CON[Connect]
    PAT[Patterns]
    PRE[Predict]
    
    CAP --> CON
    CON --> PAT
    PAT --> PRE
    PRE -.-> CAP
    
    style CAP fill:#ffe0b2
    style CON fill:#ffcc80
    style PAT fill:#ffb74d
    style PRE fill:#ffa726
```

**Capabilities:**
- Auto-updating docs
- Pattern recognition
- Predictive insights
- Continuous learning

</details>

<details>
<summary><b>🏪 Marketplace Domain</b> - Community ecosystem</summary>

```mermaid
graph TB
    MARKET[Marketplace]
    
    REPO[Community Repository]
    DISC[Discovery Service]
    QUAL[Quality Assurance]
    CONT[Contribution Manager]
    
    MARKET --> REPO
    MARKET --> DISC
    MARKET --> QUAL
    MARKET --> CONT
    
    subgraph "Content Types"
        METH_C[Methodologies]
        AGENT_C[Agents]
        TMPL_C[Templates]
    end
    
    REPO --> METH_C
    REPO --> AGENT_C
    REPO --> TMPL_C
    
    style MARKET fill:#e1bee7,stroke:#6a1b9a,stroke-width:2px
    style REPO fill:#f3e5f5
    style DISC fill:#f3e5f5
    style QUAL fill:#f3e5f5
    style CONT fill:#f3e5f5
```

**Functions:**
- **Repository**: Store and version community content
- **Discovery**: Search, filter, recommend
- **Quality**: Validate, test, certify
- **Contribution**: Publish, update, maintain

**Key Features:**
- Community-driven methodologies
- Shareable agent configurations
- Quality validation process
- Version compatibility tracking
- Usage analytics & ratings

</details>


---

## Infrastructure Layer - "Local-First Foundation"

### Purpose
Provide reliable, performant, privacy-preserving technical foundation.

### High-Level View

```mermaid
graph TB
    DOM[Domain Layer]
    
    DATA[Local Data]
    AGENT[Agent Infra]
    INT[Integration]
    KNOW[Knowledge Infra]
    
    DOM --> DATA
    DOM --> AGENT
    DOM --> INT
    DOM --> KNOW
    
    AGENT -.->|Uses| INT
    
    DATA <--> AGENT
    AGENT <--> INT
    INT <--> KNOW
    KNOW <--> DATA
    
    style DOM fill:#f5f5f5,stroke:#666,stroke-width:1px,stroke-dasharray: 5 5
    style DATA fill:#e3f2fd,stroke:#1565c0,stroke-width:3px
    style AGENT fill:#f3e5f5,stroke:#6a1b9a,stroke-width:2px
    style INT fill:#e8f5e9,stroke:#388e3c,stroke-width:2px
    style KNOW fill:#fff3e0,stroke:#e65100,stroke-width:2px
```

### Infrastructure Details

<details>
<summary><b>💾 Local Data Management</b> - Privacy-first storage</summary>

```mermaid
graph TB
    FS[(File System)]
    SQL[(SQLite)]
    GIT[Git Repo]
    OBS[Obsidian Vault]
    
    FS --> SQL
    FS --> GIT
    FS --> OBS
    
    style FS fill:#bbdefb,stroke:#1565c0,stroke-width:2px
    style SQL fill:#90caf9
    style GIT fill:#64b5f6
    style OBS fill:#42a5f5
```

**Components:**
- File System: Primary storage for all project files
- SQLite: Structured data & metrics
- Git: Version control
- Obsidian: Knowledge UI

</details>

<details>
<summary><b>🤖 Agent Infrastructure</b> - AI management</summary>

```mermaid
graph LR
    REG[(Registry)]
    PERF[Performance]
    CTX[Context]
    UPD[Updates]
    
    REG --> PERF
    PERF --> UPD
    CTX --> REG
    UPD -.-> REG
    
    style REG fill:#e1bee7
    style PERF fill:#ce93d8
    style CTX fill:#ba68c8
    style UPD fill:#ab47bc
```

**Functions:**
- Registry: Discovery
- Performance: Tracking
- Context: State management
- Updates: Improvements

</details>

<details>
<summary><b>🔌 Integration Services</b> - External connections</summary>

```mermaid
graph TB
    LAR[Local Agent Runtime]
    MCP[MCP Servers]
    AI[AI Providers]
    STD[Standards]
    
    LAR --> MCP
    MCP --> AI
    STD --> LAR
    
    AGENTS[All Agents]
    AGENTS -.->|Execute via| LAR
    
    style LAR fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style MCP fill:#a5d6a7
    style AI fill:#81c784
    style STD fill:#66bb6a
    style AGENTS fill:#f3e5f5
```

**Integrations:**
- Local Agent Runtime (primary agent execution interface)
- MCP ecosystem
- AI providers
- Import/export

</details>

<details>
<summary><b>📚 Knowledge Infrastructure</b> - Smart storage</summary>

```mermaid
graph TB
    VEC[(Vector Store)]
    EVT[(Event Store)]
    GDB[(Graph DB)]
    SYNC[Sync Engine]
    
    VEC --> GDB
    EVT --> SYNC
    GDB --> SYNC
    SYNC -.-> VEC
    
    style VEC fill:#ffe0b2
    style EVT fill:#ffcc80
    style GDB fill:#ffb74d
    style SYNC fill:#ffa726
```

**Capabilities:**
- Semantic search
- Event sourcing
- Relationship graphs
- Bidirectional sync

</details>

### Data Flow Architecture

```mermaid
sequenceDiagram
    participant User
    participant Local as Local Storage
    participant Sync as Sync Engine
    participant Cloud as Cloud Services
    participant MCP as MCP Servers
    
    User->>Local: Create project
    Local-->>User: Instant response
    
    opt When Online
        Local->>Sync: Queue changes
        Sync->>Cloud: Encrypted sync
        Sync->>MCP: Integration updates
    end
    
    User->>Local: Work offline
    Local-->>User: Full functionality
    
    alt Coming Online
        Sync->>Cloud: Batch sync
        Cloud-->>Sync: Merge changes
        Sync->>Local: Update local
    end
```

### Privacy & Performance

```mermaid
graph LR
    subgraph "Privacy First"
        P1[Local Processing]
        P2[Encrypted Storage]
        P3[User Controls]
        P4[No Telemetry]
    end
    
    subgraph "Performance Gains"
        F1[< 100ms UI]
        F2[< 500ms Query]
        F3[< 3s Agent Response]
        F4[100% Offline]
    end
    
    P1 --> F1
    P1 --> F2
    P2 --> F4
    P3 --> F3
    
    style P1 fill:#e8f5e9
    style P2 fill:#e8f5e9
    style P3 fill:#e8f5e9
    style P4 fill:#e8f5e9
    style F1 fill:#e3f2fd
    style F2 fill:#e3f2fd
    style F3 fill:#e3f2fd
    style F4 fill:#e3f2fd
```

## Integration Points

```mermaid
graph TB
    subgraph "External Integrations"
        GH[GitHub MCP]
        OB[Obsidian MCP]
        C7[Context7 MCP]
    end
    
    subgraph "Infrastructure Layer"
        LAR[Local Agent Runtime]
        INFRA[Integration Services]
        
        LAR --> INFRA
    end
    
    subgraph "Domain Layer"
        PROJ[Projects]
        KNOW[Knowledge]
        AGENT[Agents]
    end
    
    GH --> INFRA
    OB --> INFRA
    C7 --> INFRA
    
    INFRA --> PROJ
    INFRA --> KNOW
    AGENT -->|Execute via| LAR
    
    style GH fill:#f5f5f5
    style OB fill:#f5f5f5
    style C7 fill:#f5f5f5
    style LAR fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
```

## Next Steps

- Explore [Domains](Domains.md) for detailed business logic
- Review [Cross-Cutting Concerns](Cross-Cutting.md) for system-wide features
- See [Flows](Flows.md) for real-world examples