# Architecture Diagrams for Sprint 2 Demo
**Visual Assets for Presentation**

## 1. System Overview Diagram

```mermaid
graph TB
    subgraph "User Environment"
        U[User]
        CLI[Claude Code CLI]
        OBS[Obsidian Desktop]
    end
    
    subgraph "ClaudeProjects2 System"
        subgraph "Orchestration Layer"
            CLAUDE[CLAUDE.md<br/>Living Documentation]
        end
        
        subgraph "Agent Ecosystem"
            CORE[Core Agents<br/>Always Active]
            DOMAIN[Domain Agents<br/>On Demand]
            INFRA[Infrastructure Agents<br/>System Level]
        end
        
        subgraph "Storage Layer"
            MSG[(Message Queue)]
            CTX[(Context Cache)]
            STATE[(Agent State)]
        end
        
        subgraph "Integration Layer"
            VAULT[(Obsidian Vault)]
            GIT[(Git Repository)]
            SQL[(Analytics DB)]
        end
    end
    
    U --> CLI
    U --> OBS
    CLI --> CLAUDE
    CLAUDE --> CORE
    CORE --> DOMAIN
    CORE --> INFRA
    CORE --> MSG
    DOMAIN --> CTX
    INFRA --> STATE
    INFRA --> VAULT
    INFRA --> GIT
    DOMAIN --> SQL
    OBS --> VAULT
    
    style CLAUDE fill:#ffd700,stroke:#ff6b6b,stroke-width:3px
    style CORE fill:#4ecdc4,stroke:#45b7d1,stroke-width:2px
```

## 2. Agent Communication Flow

```mermaid
sequenceDiagram
    participant User
    participant CLI as Claude Code
    participant CLAUDE as CLAUDE.md
    participant ORC as Orchestrator
    participant QUEUE as Message Queue
    participant AGENT as Domain Agent
    participant CTX as Context
    
    User->>CLI: "Research competitor pricing"
    CLI->>CLAUDE: Parse request
    CLAUDE->>ORC: Route to research-agent
    ORC->>CTX: Load context
    CTX-->>ORC: Context ready
    ORC->>QUEUE: Queue message
    QUEUE->>AGENT: Deliver task
    AGENT->>AGENT: Execute research
    AGENT->>CTX: Update findings
    AGENT->>QUEUE: Send results
    QUEUE->>ORC: Return results
    ORC->>CLI: Format response
    CLI->>User: Present findings
```

## 3. Context Cache Architecture

```mermaid
graph TB
    subgraph "Context Request Flow"
        REQ[Context Request]
        L1{L1 Cache?}
        L2{L2 Cache?}
        L3{L3 Cache?}
        DISK[Load from Disk]
        RET[Return Context]
    end
    
    subgraph "Cache Layers"
        subgraph "L1: Hot Cache"
            HC[10-50 contexts<br/>Uncompressed<br/>< 10ms]
        end
        
        subgraph "L2: Warm Cache"
            WC[100-500 contexts<br/>Compressed<br/>< 50ms]
        end
        
        subgraph "L3: Cold Cache"
            CC[1000+ contexts<br/>Disk cached<br/>< 200ms]
        end
        
        subgraph "L4: Storage"
            ST[All contexts<br/>File system<br/>< 500ms]
        end
    end
    
    REQ --> L1
    L1 -->|Hit| RET
    L1 -->|Miss| L2
    L2 -->|Hit| RET
    L2 -->|Miss| L3
    L3 -->|Hit| RET
    L3 -->|Miss| DISK
    DISK --> RET
    
    HC --> WC
    WC --> CC
    CC --> ST
    
    style HC fill:#ff6b6b
    style WC fill:#ffd93d
    style CC fill:#6bcf7f
    style ST fill:#4ecdc4
```

## 4. Obsidian Integration Strategy

```mermaid
graph LR
    subgraph "Decision Engine"
        OA[obsidian-agent]
        DEC{Operation Type?}
    end
    
    subgraph "Execution Paths"
        subgraph "MCP Path"
            MCP[MCP Server]
            FEAT[Rich Features<br/>Graph Queries<br/>Plugin Ops]
        end
        
        subgraph "File System Path"
            FS[Direct Files]
            PERF[Performance<br/>Bulk Ops<br/>Large Files]
        end
        
        subgraph "Hybrid Path"
            HYB[Combined]
            SRCH[Search<br/>Create Note<br/>Sync]
        end
    end
    
    subgraph "Obsidian"
        API[REST API]
        VAULT[(Vault Files)]
        UI[Obsidian UI]
    end
    
    OA --> DEC
    DEC -->|Features| MCP
    DEC -->|Performance| FS
    DEC -->|Mixed| HYB
    
    MCP --> FEAT
    FEAT --> API
    
    FS --> PERF
    PERF --> VAULT
    
    HYB --> SRCH
    SRCH --> API
    SRCH --> VAULT
    
    API --> UI
    VAULT --> UI
    
    style OA fill:#9c27b0
    style MCP fill:#ffd93d
    style FS fill:#4caf50
```

## 5. Agent Lifecycle State Machine

```mermaid
stateDiagram-v2
    [*] --> Discovered: Agent file created
    Discovered --> Registered: Valid metadata
    Registered --> Ready: Loaded in pool
    
    state Active {
        Ready --> Assigned: Task received
        Assigned --> Executing: Processing
        Executing --> Completing: Finishing
        Completing --> Ready: Available again
    }
    
    Ready --> Learning: Self-improvement
    Learning --> Updated: Enhanced
    Updated --> Ready: Reloaded
    
    Ready --> Hibernating: Low activity
    Hibernating --> Ready: Awakened
    
    Ready --> Terminating: Shutdown
    Terminating --> [*]
```

## 6. Message Queue Structure

```mermaid
graph TD
    subgraph "Message Queue File System"
        ROOT[.claudeprojects/messages/]
        
        subgraph "Active Queues"
            Q1[queues/orchestrator/]
            Q2[queues/methodology-agent/]
            Q3[queues/research-agent/]
            
            Q1P[priority/]
            Q1N[normal/]
            Q1L[low/]
        end
        
        subgraph "Processing"
            PROC[processing/]
            LOCK[{agent-id}/{msg-id}.lock]
        end
        
        subgraph "Archive"
            DL[dead-letter/]
            ARCH[archive/]
        end
    end
    
    ROOT --> Q1
    ROOT --> Q2
    ROOT --> Q3
    Q1 --> Q1P & Q1N & Q1L
    ROOT --> PROC
    PROC --> LOCK
    ROOT --> DL
    ROOT --> ARCH
    
    style Q1P fill:#ff6b6b
    style Q1N fill:#ffd93d
    style Q1L fill:#6bcf7f
```

## 7. Performance Metrics Dashboard

```mermaid
graph LR
    subgraph "Real-Time Metrics"
        subgraph "Latency"
            ML[Message: 50ms<br/>Context: 320ms<br/>Agent: 200ms]
        end
        
        subgraph "Throughput"
            TP[Messages/sec: 1000<br/>Contexts/sec: 50<br/>Agents Active: 15]
        end
        
        subgraph "Cache Performance"
            CP[L1 Hit: 42%<br/>L2 Hit: 31%<br/>L3 Hit: 12%<br/>Total: 85%]
        end
        
        subgraph "Resource Usage"
            RU[CPU: 45%<br/>Memory: 1.2GB<br/>Disk I/O: 25MB/s]
        end
    end
    
    ML --> Dashboard
    TP --> Dashboard
    CP --> Dashboard
    RU --> Dashboard
    
    style ML fill:#4ecdc4
    style TP fill:#6bcf7f
    style CP fill:#ffd93d
    style RU fill:#ff9800
```

## 8. Innovation Sprint Flow

```mermaid
graph TB
    subgraph "Day 1: Understand"
        U1[User Need] --> R1[research-agent]
        R1 --> K1[knowledge-agent]
        K1 --> I1[Initial Insights]
    end
    
    subgraph "Day 2: Ideate"
        I1 --> IN1[innovation-agent]
        IN1 --> CR1[creative-agent]
        CR1 --> ID1[100+ Ideas]
    end
    
    subgraph "Day 3: Decide"
        ID1 --> AN1[analytics-agent]
        AN1 --> PR1[prioritization-agent]
        PR1 --> D1[Top 10 Ideas]
    end
    
    subgraph "Day 4: Prototype"
        D1 --> B1[builder-agent]
        B1 --> T1[test-agent]
        T1 --> P1[Working Prototypes]
    end
    
    subgraph "Day 5: Test"
        P1 --> V1[validation-agent]
        V1 --> PRE1[presentation-agent]
        PRE1 --> F1[Final Deliverables]
    end
    
    style U1 fill:#e91e63
    style F1 fill:#4caf50
```

## 9. Self-Improvement Cycle

```mermaid
graph TB
    subgraph "Learning Loop"
        OBS[Observe Patterns]
        DET[Detect Improvements]
        UPD[Update Behavior]
        TEST[Test Changes]
        APP[Apply Learning]
        SHARE[Share Knowledge]
    end
    
    OBS --> DET
    DET --> UPD
    UPD --> TEST
    TEST --> APP
    APP --> SHARE
    SHARE --> OBS
    
    SHARE --> CLAUDE[Update CLAUDE.md]
    SHARE --> AGENTS[Train Other Agents]
    SHARE --> KB[Knowledge Base]
    
    style OBS fill:#9c27b0
    style SHARE fill:#4caf50
```

## 10. Deployment Architecture

```mermaid
graph TB
    subgraph "Local Machine"
        subgraph "System Files"
            CP[~/ClaudeProjects2/]
            AGT[agents/]
            CFG[config/]
            RT[runtime/]
        end
        
        subgraph "User Data"
            VLT[~/Documents/ClaudeProjects2-Vault/]
            PROJ[Projects/]
            KNOW[Knowledge/]
            METH[Methodologies/]
        end
        
        subgraph "Project Instance"
            PWD[./my-project/]
            CLMD[CLAUDE.md]
            CLPR[.claudeprojects/]
            DELIV[deliverables/]
        end
    end
    
    CP --> AGT & CFG & RT
    VLT --> PROJ & KNOW & METH
    PWD --> CLMD & CLPR & DELIV
    
    style CP fill:#4ecdc4
    style VLT fill:#ffd93d
    style PWD fill:#6bcf7f
```

## Usage Instructions

These diagrams can be:
1. Rendered in any Mermaid-compatible viewer
2. Exported as SVG/PNG for presentations
3. Embedded in documentation
4. Used in the demo walkthrough

Each diagram illustrates a key architectural concept and can be shown during the relevant section of the demo presentation.