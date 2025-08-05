# ClaudeProjects Physical Architecture

## Overview

The physical architecture defines "how" the system is implemented, including technology choices, deployment topology, and infrastructure components. It maps the logical architecture to concrete implementations.

## Architecture Style

**Local-First Agent-Oriented Architecture**
- Claude Code CLI as the primary execution engine
- Obsidian desktop app as the knowledge management UI
- AI agents as markdown-based building blocks
- MCP ecosystem for integrations
- Progressive cloud enhancement for collaboration

## Technology Stack

```mermaid
graph TB
    subgraph "Presentation Layer"
        A[Claude Code CLI] --> A1[Agent Invocation]
        A --> A2[Project Commands]
        A --> A3[Workflow Execution]
        
        B[Obsidian Desktop] --> B1[Visual UI]
        B --> B2[Knowledge Graph]
        B --> B3[Document Editing]
    end
    
    subgraph "Application Layer"
        C[Claude Code Runtime] --> C1[Agent Engine]
        C --> C2[Task Orchestration]
        C --> C3[Context Management]
        
        D[MCP Servers] --> D1[GitHub MCP]
        D --> D2[Obsidian MCP]
        D --> D3[Context7 MCP]
        D --> D4[Sequential MCP]
    end
    
    subgraph "Domain Layer"
        E[Agent Definitions] --> E1[Markdown Files]
        E --> E2[Capability Index]
        E --> E3[Performance Metrics]
        
        F[Business Logic] --> F1[TypeScript]
        F --> F2[Event Sourcing]
        F --> F3[Domain Models]
    end
    
    subgraph "Infrastructure Layer"
        G[Local Storage] --> G1[SQLite]
        G --> G2[File System]
        G --> G3[Git Repos]
        
        H[External Services] --> H1[Claude API]
        H --> H2[GitHub API]
        H --> H3[Documentation APIs]
    end
```

## Component Architecture

### 1. Desktop Application (Electron)

```mermaid
graph LR
    subgraph "Main Process"
        MP[Main Process] --> WM[Window Manager]
        MP --> FS[File System API]
        MP --> IPC[IPC Handler]
        MP --> AU[Auto Updater]
    end
    
    subgraph "Renderer Process"
        RP[React App] --> UI[UI Components]
        RP --> SM[State Manager]
        RP --> RT[Router]
        RP --> AH[API Hooks]
    end
    
    subgraph "Background Process"
        BP[Worker Threads] --> AL[Agent Loader]
        BP --> SS[Sync Service]
        BP --> IN[Indexer]
    end
    
    IPC --> RP
    IPC --> BP
```

**Technology Choices**:
- **Electron**: Cross-platform desktop app
- **React**: Modern UI framework
- **TypeScript**: Type safety
- **Redux Toolkit**: State management
- **Tailwind CSS**: Styling
- **Vite**: Build tool

### 2. Local Agent Runtime

```mermaid
graph TB
    subgraph "Agent Runtime"
        AR[Runtime Core] --> AE[Agent Engine]
        AR --> CM[Context Manager]
        AR --> PM[Plugin Manager]
        
        AE --> LA[Local Agents]
        AE --> RA[Remote Agents]
        
        CM --> LK[Local Knowledge]
        CM --> PC[Project Context]
        CM --> UC[User Context]
    end
    
    subgraph "MCP Integration"
        MCP[MCP Server] --> GH[GitHub MCP]
        MCP --> OB[Obsidian MCP]
        MCP --> C7[Context7 MCP]
        MCP --> SQ[Sequential MCP]
    end
    
    AR --> MCP
```

**Technology Choices**:
- **Node.js**: JavaScript runtime
- **TypeScript**: Type safety
- **Bull**: Job queue for agent tasks
- **LangChain**: Agent orchestration
- **Ollama**: Local LLM support

### 3. Data Architecture

```mermaid
graph TD
    subgraph "Local Data"
        LD[Local Database] --> PD[Project Data]
        LD --> AD[Agent Data]
        LD --> KD[Knowledge Data]
        LD --> UD[User Data]
        
        FS[File System] --> MD[Markdown Docs]
        FS --> AT[Attachments]
        FS --> TM[Templates]
        
        IX[Search Index] --> FT[Full Text]
        IX --> VC[Vector Store]
    end
    
    subgraph "Sync Layer"
        SY[Sync Engine] --> CR[Conflict Resolution]
        SY --> DT[Delta Tracking]
        SY --> EN[Encryption]
    end
    
    subgraph "Cloud Data"
        CD[Cloud Database] --> TD[Team Data]
        CD --> SD[Shared Knowledge]
        CD --> AD2[Analytics Data]
        
        OS[Object Store] --> LF[Large Files]
        OS --> BK[Backups]
    end
    
    LD <==> SY
    SY <==> CD
```

**Technology Choices**:
- **SQLite**: Local database
- **PostgreSQL**: Cloud database
- **MinIO/S3**: Object storage
- **Redis**: Caching and pub/sub
- **Elasticsearch**: Full-text search
- **Pinecone**: Vector database

### 4. Security Architecture

```mermaid
graph TB
    subgraph "Client Security"
        CS[Client Security] --> LE[Local Encryption]
        CS --> KS[Keychain Storage]
        CS --> SB[Sandbox]
    end
    
    subgraph "Transport Security"
        TS[Transport] --> TLS[TLS 1.3]
        TS --> CP[Certificate Pinning]
        TS --> MT[Mutual TLS]
    end
    
    subgraph "Cloud Security"
        CLS[Cloud Security] --> AU[Auth Service]
        CLS --> RB[RBAC]
        CLS --> EN[Encryption at Rest]
        
        AU --> OA[OAuth 2.0]
        AU --> SA[SAML]
        AU --> MF[MFA]
    end
    
    subgraph "Data Security"
        DS[Data Security] --> E2E[E2E Encryption]
        DS --> ZK[Zero Knowledge]
        DS --> AR[Access Audit]
    end
```

## Deployment Architecture

### Development Environment

```yaml
version: '3.8'
services:
  app:
    build: ./app
    volumes:
      - ./app:/app
      - /app/node_modules
    ports:
      - "3000:3000"
  
  api:
    build: ./api
    environment:
      - DATABASE_URL=postgresql://...
    ports:
      - "8000:8000"
  
  postgres:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  redis:
    image: redis:7-alpine
  
  minio:
    image: minio/minio
    command: server /data
```

### Production Architecture

```mermaid
graph TB
    subgraph "User Devices"
        U1[Desktop App]
        U2[CLI Tool]
        U3[Web App]
    end
    
    subgraph "Edge Layer"
        CDN[CloudFlare CDN]
        LB[Load Balancer]
    end
    
    subgraph "Application Layer"
        API1[API Server 1]
        API2[API Server 2]
        APIN[API Server N]
        
        WS1[WebSocket Server 1]
        WS2[WebSocket Server 2]
    end
    
    subgraph "Service Layer"
        AS[Agent Service]
        SS[Sync Service]
        NS[Notification Service]
    end
    
    subgraph "Data Layer"
        PG[(PostgreSQL Primary)]
        PGR[(PostgreSQL Replica)]
        RD[(Redis Cluster)]
        S3[(S3 Storage)]
    end
    
    U1 --> CDN
    U2 --> CDN
    U3 --> CDN
    
    CDN --> LB
    LB --> API1
    LB --> API2
    LB --> APIN
    
    API1 --> AS
    API2 --> AS
    
    AS --> PG
    SS --> PG
    NS --> RD
```

## Directory Structure

```
ClaudeProjects2/
├── apps/
│   ├── desktop/          # Electron app
│   │   ├── src/
│   │   │   ├── main/    # Main process
│   │   │   ├── renderer/# React app
│   │   │   └── preload/ # Preload scripts
│   │   └── package.json
│   │
│   ├── cli/             # CLI tool
│   │   ├── src/
│   │   │   ├── commands/
│   │   │   ├── agents/
│   │   │   └── utils/
│   │   └── package.json
│   │
│   └── web/             # Web app
│       ├── src/
│       └── package.json
│
├── packages/            # Shared packages
│   ├── core/           # Core business logic
│   ├── agents/         # Agent definitions
│   ├── ui/            # UI components
│   └── types/         # TypeScript types
│
├── services/           # Backend services
│   ├── api/           # Main API
│   ├── sync/          # Sync service
│   ├── agents/        # Agent service
│   └── auth/          # Auth service
│
├── infrastructure/     # IaC and deployment
│   ├── terraform/
│   ├── kubernetes/
│   └── docker/
│
├── docs/              # Documentation
├── scripts/           # Build scripts
└── tests/            # Test suites
```

## Performance Optimizations

### 1. Local-First Performance
- SQLite for instant queries
- In-memory caching
- Background indexing
- Lazy loading

### 2. Network Optimization
- Delta sync only
- Compression (Brotli)
- Request batching
- Offline queue

### 3. Agent Performance
- Local LLM for simple tasks
- Agent result caching
- Parallel execution
- Progressive enhancement

## Scalability Strategy

### Horizontal Scaling
- Stateless API servers
- Distributed agent pools
- Read replicas
- CDN for static assets

### Vertical Scaling
- Agent GPU clusters
- High-memory cache nodes
- SSD-optimized databases

## Monitoring & Observability

```mermaid
graph LR
    A[Application] --> B[OpenTelemetry]
    B --> C[Metrics]
    B --> D[Traces]
    B --> E[Logs]
    
    C --> F[Prometheus]
    D --> G[Jaeger]
    E --> H[Loki]
    
    F --> I[Grafana]
    G --> I
    H --> I
```

**Metrics to Track**:
- Response times
- Agent performance
- Sync latency
- Error rates
- Resource usage

## Disaster Recovery

### Backup Strategy
- Local: Continuous file backup
- Cloud: Daily snapshots
- Critical: Real-time replication

### Recovery Targets
- RPO: 1 hour
- RTO: 4 hours
- Data retention: 90 days

## Cost Optimization

### Infrastructure Costs
- Local-first reduces cloud costs
- Serverless for burst workloads
- Reserved instances for base load
- Spot instances for agents

### Estimated Monthly Costs (1000 users)
- Compute: $2,000
- Storage: $500
- Network: $300
- AI APIs: $1,500
- **Total**: ~$4,300

## Future Considerations

### Phase 1 (Current)
- Desktop app with local agents
- Basic cloud sync
- Core MCP integrations

### Phase 2 (6 months)
- Mobile apps
- Enhanced collaboration
- Custom model training

### Phase 3 (12 months)
- Enterprise features
- On-premise deployment
- Advanced analytics

## Conclusion

This physical architecture provides a robust, scalable, and privacy-focused implementation of ClaudeProjects. The local-first approach ensures performance and data sovereignty while cloud services enable collaboration and advanced AI capabilities.