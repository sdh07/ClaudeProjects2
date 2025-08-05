# Agent Communication Protocol & State Management
**Sprint 2, Thursday - Issue #25**
**Date**: 2025-08-05

## Executive Summary

This document provides the detailed design for agent communication and state management in ClaudeProjects2. It addresses the critical need for reliable, performant, and scalable inter-agent communication while maintaining state consistency across parallel agent operations.

## Design Principles

1. **Simplicity First**: File-based messaging for debuggability
2. **Eventual Consistency**: Agents converge to consistent state
3. **Failure Resilience**: Every operation can recover
4. **Performance Aware**: Minimize I/O operations
5. **Observable**: All communication is traceable

## Message Queue Architecture

### 1. File-Based Message Queue

```
.claudeprojects/messages/
├── queues/                    # Active message queues
│   ├── {agent-id}/           # Per-agent inbox
│   │   ├── priority/         # High priority messages
│   │   │   └── {timestamp}-{msg-id}.json
│   │   ├── normal/           # Normal priority
│   │   │   └── {timestamp}-{msg-id}.json
│   │   └── low/              # Low priority
│   │       └── {timestamp}-{msg-id}.json
├── processing/               # Messages being processed
│   └── {agent-id}/
│       └── {msg-id}.lock    # Lock files
├── dead-letter/             # Failed messages
│   └── {date}/
│       └── {msg-id}.json
└── archive/                 # Completed messages
    └── {date}/
        └── {hour}/
            └── {msg-id}.json
```

### 2. Message Format Specification

```typescript
interface AgentMessage {
  header: {
    id: string;                    // UUID v4
    version: "1.0";               // Protocol version
    timestamp: string;            // ISO 8601
    from: string;                 // Sending agent ID
    to: string | string[];        // Recipient(s)
    replyTo?: string;            // Response destination
    correlationId?: string;      // Links related messages
    priority: "high" | "normal" | "low";
    ttl?: number;                // Time to live (ms)
    retryCount?: number;         // Current retry attempt
    maxRetries?: number;         // Max retry attempts
  };
  
  routing: {
    broadcast?: boolean;         // Send to all agents
    topic?: string;             // Pub/sub topic
    exclusive?: boolean;        // Single consumer
  };
  
  body: {
    type: "request" | "response" | "event" | "command";
    action: string;             // Specific operation
    payload: any;               // Action-specific data
    context?: {
      projectId: string;
      workingDirectory: string;
      methodology?: string;
      phase?: string;
    };
  };
  
  metadata: {
    traceId: string;           // Distributed tracing
    spanId: string;
    tags?: Record<string, string>;
    metrics?: {
      queueTime?: number;
      processingTime?: number;
    };
  };
}
```

### 3. Message Operations

#### Sending Messages
```typescript
class MessageQueue {
  async send(message: AgentMessage): Promise<void> {
    // 1. Validate message schema
    this.validateMessage(message);
    
    // 2. Add metadata
    message.metadata.queueTime = Date.now();
    
    // 3. Determine priority queue
    const queuePath = this.getQueuePath(message.header.to, message.header.priority);
    
    // 4. Write atomically
    const tempPath = `${queuePath}/.tmp-${message.header.id}`;
    const finalPath = `${queuePath}/${Date.now()}-${message.header.id}.json`;
    
    await fs.writeFile(tempPath, JSON.stringify(message, null, 2));
    await fs.rename(tempPath, finalPath); // Atomic operation
    
    // 5. Notify watchers (optional)
    this.emitNewMessage(message.header.to);
  }
}
```

#### Receiving Messages
```typescript
class MessageReceiver {
  async receive(agentId: string): Promise<AgentMessage | null> {
    // 1. Check priority queues in order
    for (const priority of ["priority", "normal", "low"]) {
      const queuePath = this.getQueuePath(agentId, priority);
      const messages = await this.listMessages(queuePath);
      
      if (messages.length > 0) {
        // 2. Attempt to acquire lock
        const message = messages[0];
        const lockPath = `.claudeprojects/messages/processing/${agentId}/${message.id}.lock`;
        
        try {
          // 3. Create lock file atomically
          await fs.writeFile(lockPath, process.pid.toString(), { flag: 'wx' });
          
          // 4. Read and parse message
          const content = await fs.readFile(message.path, 'utf-8');
          const parsed = JSON.parse(content);
          
          // 5. Move to processing
          await fs.unlink(message.path);
          
          return parsed;
        } catch (e) {
          // Lock already exists, try next message
          continue;
        }
      }
    }
    
    return null;
  }
}
```

#### Message Acknowledgment
```typescript
class MessageAcknowledger {
  async ack(agentId: string, messageId: string): Promise<void> {
    // 1. Remove lock file
    const lockPath = `.claudeprojects/messages/processing/${agentId}/${messageId}.lock`;
    await fs.unlink(lockPath);
    
    // 2. Archive message (optional)
    if (this.config.archiveMessages) {
      await this.archiveMessage(messageId);
    }
  }
  
  async nack(agentId: string, message: AgentMessage, error: Error): Promise<void> {
    // 1. Remove lock file
    const lockPath = `.claudeprojects/messages/processing/${agentId}/${message.header.id}.lock`;
    await fs.unlink(lockPath);
    
    // 2. Check retry policy
    const retryCount = (message.header.retryCount || 0) + 1;
    const maxRetries = message.header.maxRetries || 3;
    
    if (retryCount < maxRetries) {
      // 3. Requeue with backoff
      message.header.retryCount = retryCount;
      const backoffMs = Math.min(1000 * Math.pow(2, retryCount), 30000);
      
      setTimeout(() => {
        this.send(message);
      }, backoffMs);
    } else {
      // 4. Move to dead letter queue
      await this.moveToDeadLetter(message, error);
    }
  }
}
```

### 4. Communication Patterns

#### Request-Response Pattern
```typescript
async function requestResponse(
  from: string,
  to: string,
  action: string,
  payload: any,
  timeoutMs: number = 30000
): Promise<any> {
  const correlationId = generateId();
  
  // Send request
  await messageQueue.send({
    header: {
      id: generateId(),
      version: "1.0",
      timestamp: new Date().toISOString(),
      from,
      to,
      correlationId,
      priority: "normal"
    },
    body: {
      type: "request",
      action,
      payload
    }
  });
  
  // Wait for response
  const response = await waitForResponse(correlationId, timeoutMs);
  if (!response) {
    throw new Error(`Request timeout: ${action}`);
  }
  
  return response.body.payload;
}
```

#### Publish-Subscribe Pattern
```typescript
class PubSubManager {
  private subscriptions: Map<string, Set<string>> = new Map();
  
  subscribe(topic: string, agentId: string): void {
    if (!this.subscriptions.has(topic)) {
      this.subscriptions.set(topic, new Set());
    }
    this.subscriptions.get(topic)!.add(agentId);
  }
  
  async publish(topic: string, message: AgentMessage): Promise<void> {
    const subscribers = this.subscriptions.get(topic) || new Set();
    
    for (const agentId of subscribers) {
      await messageQueue.send({
        ...message,
        header: {
          ...message.header,
          to: agentId
        },
        routing: {
          ...message.routing,
          topic
        }
      });
    }
  }
}
```

#### Event Broadcasting
```typescript
async function broadcastEvent(
  from: string,
  event: string,
  data: any
): Promise<void> {
  await messageQueue.send({
    header: {
      id: generateId(),
      version: "1.0",
      timestamp: new Date().toISOString(),
      from,
      to: "*", // Special broadcast address
      priority: "normal"
    },
    routing: {
      broadcast: true
    },
    body: {
      type: "event",
      action: event,
      payload: data
    }
  });
}
```

## State Management Architecture

### 1. State Store Design

```
.claudeprojects/state/
├── agents/                    # Agent-specific state
│   ├── {agent-id}/
│   │   ├── current.json      # Current state
│   │   ├── checkpoint/       # State checkpoints
│   │   │   └── {timestamp}.json
│   │   └── locks/           # State locks
│   │       └── {section}.lock
├── shared/                   # Shared state
│   ├── project.json         # Project-wide state
│   ├── methodology.json     # Methodology state
│   └── context.json        # Shared context
└── transactions/            # Transaction log
    └── {date}/
        └── {transaction-id}.json
```

### 2. State Schema

```typescript
interface AgentState {
  meta: {
    agentId: string;
    version: number;              // Optimistic locking
    lastModified: string;         // ISO 8601
    checksum: string;            // SHA-256 of state
  };
  
  runtime: {
    status: "idle" | "busy" | "error" | "terminated";
    currentTask?: {
      id: string;
      action: string;
      startTime: string;
      progress?: number;
    };
    health: {
      memoryUsage: number;
      lastHeartbeat: string;
      errorCount: number;
    };
  };
  
  domain: {
    // Agent-specific state
    [key: string]: any;
  };
  
  context: {
    workingDirectory: string;
    environment: Record<string, string>;
    capabilities: string[];
  };
}
```

### 3. State Operations

#### Reading State
```typescript
class StateManager {
  async readState(agentId: string, section?: string): Promise<any> {
    const statePath = `.claudeprojects/state/agents/${agentId}/current.json`;
    
    try {
      const content = await fs.readFile(statePath, 'utf-8');
      const state = JSON.parse(content);
      
      // Verify checksum
      const calculatedChecksum = this.calculateChecksum(state);
      if (calculatedChecksum !== state.meta.checksum) {
        throw new Error('State corruption detected');
      }
      
      return section ? state[section] : state;
    } catch (e) {
      if (e.code === 'ENOENT') {
        return this.createInitialState(agentId);
      }
      throw e;
    }
  }
}
```

#### Writing State with Optimistic Locking
```typescript
class StateWriter {
  async updateState(
    agentId: string,
    updates: Partial<AgentState>,
    expectedVersion?: number
  ): Promise<void> {
    const lockPath = `.claudeprojects/state/agents/${agentId}/locks/write.lock`;
    
    // Acquire exclusive lock
    const lock = await this.acquireLock(lockPath);
    
    try {
      // Read current state
      const current = await this.readState(agentId);
      
      // Check version for optimistic locking
      if (expectedVersion && current.meta.version !== expectedVersion) {
        throw new Error('State version mismatch - concurrent modification');
      }
      
      // Merge updates
      const updated = this.deepMerge(current, updates);
      updated.meta.version++;
      updated.meta.lastModified = new Date().toISOString();
      updated.meta.checksum = this.calculateChecksum(updated);
      
      // Create checkpoint
      await this.createCheckpoint(agentId, current);
      
      // Write atomically
      const tempPath = `.claudeprojects/state/agents/${agentId}/.tmp-current`;
      const finalPath = `.claudeprojects/state/agents/${agentId}/current.json`;
      
      await fs.writeFile(tempPath, JSON.stringify(updated, null, 2));
      await fs.rename(tempPath, finalPath);
      
      // Log transaction
      await this.logTransaction(agentId, updates);
      
    } finally {
      await this.releaseLock(lock);
    }
  }
}
```

#### State Synchronization
```typescript
class StateSynchronizer {
  async syncStates(agents: string[]): Promise<void> {
    const sharedStatePath = '.claudeprojects/state/shared/context.json';
    
    // Collect relevant state from all agents
    const agentStates = await Promise.all(
      agents.map(id => this.readState(id))
    );
    
    // Merge shared context
    const sharedContext = this.mergeContexts(agentStates);
    
    // Update shared state
    await fs.writeFile(
      sharedStatePath,
      JSON.stringify(sharedContext, null, 2)
    );
    
    // Notify agents of context update
    await this.broadcastContextUpdate(agents, sharedContext);
  }
}
```

### 4. Transaction Management

```typescript
interface StateTransaction {
  id: string;
  timestamp: string;
  agentId: string;
  operation: "create" | "update" | "delete";
  before?: any;
  after: any;
  metadata: {
    causedBy?: string;    // Message ID that triggered change
    duration: number;     // Operation duration
  };
}

class TransactionLogger {
  async logTransaction(transaction: StateTransaction): Promise<void> {
    const date = new Date().toISOString().split('T')[0];
    const logPath = `.claudeprojects/state/transactions/${date}/${transaction.id}.json`;
    
    await fs.mkdir(path.dirname(logPath), { recursive: true });
    await fs.writeFile(logPath, JSON.stringify(transaction, null, 2));
  }
  
  async rollback(transactionId: string): Promise<void> {
    const transaction = await this.loadTransaction(transactionId);
    
    if (transaction.before) {
      await this.stateManager.updateState(
        transaction.agentId,
        transaction.before
      );
    }
  }
}
```

## Performance Optimization

### 1. Message Queue Performance

#### Batch Processing
```typescript
class BatchProcessor {
  async processBatch(agentId: string, maxBatch: number = 10): Promise<AgentMessage[]> {
    const messages: AgentMessage[] = [];
    
    for (let i = 0; i < maxBatch; i++) {
      const message = await this.receiver.receive(agentId);
      if (!message) break;
      messages.push(message);
    }
    
    return messages;
  }
}
```

#### Directory Watching
```typescript
class QueueWatcher {
  private watchers: Map<string, fs.FSWatcher> = new Map();
  
  watchQueue(agentId: string, callback: () => void): void {
    const queuePath = `.claudeprojects/messages/queues/${agentId}`;
    
    const watcher = fs.watch(queuePath, { recursive: true }, (event, filename) => {
      if (event === 'rename' && filename?.endsWith('.json')) {
        callback();
      }
    });
    
    this.watchers.set(agentId, watcher);
  }
}
```

### 2. State Caching

```typescript
class StateCache {
  private cache: LRUCache<string, any>;
  private writeBuffer: Map<string, any> = new Map();
  private flushInterval: NodeJS.Timeout;
  
  constructor(maxSize: number = 100) {
    this.cache = new LRUCache({ max: maxSize });
    
    // Periodic flush of write buffer
    this.flushInterval = setInterval(() => {
      this.flushWriteBuffer();
    }, 1000);
  }
  
  async get(key: string): Promise<any> {
    // Check write buffer first
    if (this.writeBuffer.has(key)) {
      return this.writeBuffer.get(key);
    }
    
    // Check cache
    if (this.cache.has(key)) {
      return this.cache.get(key);
    }
    
    // Load from disk
    const value = await this.loadFromDisk(key);
    this.cache.set(key, value);
    return value;
  }
  
  async set(key: string, value: any): Promise<void> {
    this.cache.set(key, value);
    this.writeBuffer.set(key, value);
  }
  
  private async flushWriteBuffer(): Promise<void> {
    const entries = Array.from(this.writeBuffer.entries());
    this.writeBuffer.clear();
    
    await Promise.all(
      entries.map(([key, value]) => this.writeToDisk(key, value))
    );
  }
}
```

## Error Handling & Recovery

### 1. Message Queue Recovery

```typescript
class QueueRecovery {
  async recoverStuckMessages(): Promise<void> {
    const processingDir = '.claudeprojects/messages/processing';
    const agents = await fs.readdir(processingDir);
    
    for (const agentId of agents) {
      const locks = await fs.readdir(`${processingDir}/${agentId}`);
      
      for (const lockFile of locks) {
        const lockPath = `${processingDir}/${agentId}/${lockFile}`;
        const stats = await fs.stat(lockPath);
        
        // Check if lock is older than timeout
        const ageMs = Date.now() - stats.mtimeMs;
        if (ageMs > 300000) { // 5 minutes
          // Recover message
          const messageId = lockFile.replace('.lock', '');
          await this.recoverMessage(agentId, messageId);
        }
      }
    }
  }
}
```

### 2. State Recovery

```typescript
class StateRecovery {
  async recoverFromCheckpoint(agentId: string, timestamp?: string): Promise<void> {
    const checkpointDir = `.claudeprojects/state/agents/${agentId}/checkpoint`;
    
    if (timestamp) {
      // Recover specific checkpoint
      const checkpointPath = `${checkpointDir}/${timestamp}.json`;
      await this.restoreCheckpoint(agentId, checkpointPath);
    } else {
      // Find latest checkpoint
      const checkpoints = await fs.readdir(checkpointDir);
      const latest = checkpoints.sort().pop();
      
      if (latest) {
        await this.restoreCheckpoint(agentId, `${checkpointDir}/${latest}`);
      }
    }
  }
}
```

## Security Considerations

### 1. Message Validation

```typescript
class MessageValidator {
  private schema = Joi.object({
    header: Joi.object({
      id: Joi.string().uuid().required(),
      version: Joi.string().valid("1.0").required(),
      timestamp: Joi.string().isoDate().required(),
      from: Joi.string().required(),
      to: Joi.alternatives().try(
        Joi.string(),
        Joi.array().items(Joi.string())
      ).required(),
      priority: Joi.string().valid("high", "normal", "low").required()
    }).required(),
    body: Joi.object({
      type: Joi.string().valid("request", "response", "event", "command").required(),
      action: Joi.string().required(),
      payload: Joi.any()
    }).required()
  });
  
  validate(message: any): void {
    const { error } = this.schema.validate(message);
    if (error) {
      throw new ValidationError(`Invalid message: ${error.message}`);
    }
  }
}
```

### 2. Access Control

```typescript
class MessageAccessControl {
  canSend(fromAgent: string, toAgent: string, action: string): boolean {
    // Check agent permissions
    const permissions = this.getAgentPermissions(fromAgent);
    
    // Validate target agent
    if (!permissions.canCommunicateWith.includes(toAgent)) {
      return false;
    }
    
    // Validate action
    if (!permissions.allowedActions.includes(action)) {
      return false;
    }
    
    return true;
  }
}
```

## Monitoring & Observability

### 1. Queue Metrics

```typescript
interface QueueMetrics {
  agentId: string;
  timestamp: string;
  queued: {
    priority: number;
    normal: number;
    low: number;
  };
  processing: number;
  deadLetter: number;
  throughput: {
    messagesPerSecond: number;
    bytesPerSecond: number;
  };
  latency: {
    p50: number;
    p95: number;
    p99: number;
  };
}
```

### 2. State Metrics

```typescript
interface StateMetrics {
  agentId: string;
  stateSize: number;
  version: number;
  lastModified: string;
  checkpointCount: number;
  transactionRate: number;
}
```

## Implementation Roadmap

### Phase 1: Core Infrastructure (Week 1)
- Message queue implementation
- Basic state management
- Error handling

### Phase 2: Advanced Features (Week 2)
- Pub/sub patterns
- State synchronization
- Performance optimization

### Phase 3: Production Hardening (Week 3)
- Monitoring integration
- Security enhancements
- Recovery mechanisms

## Conclusion

This agent communication protocol and state management design provides:

1. **Reliability**: File-based queues with atomic operations
2. **Performance**: Caching, batching, and efficient I/O
3. **Scalability**: Supports many concurrent agents
4. **Debuggability**: Human-readable files and clear structure
5. **Resilience**: Comprehensive error recovery

The design balances simplicity with capability, ensuring the system can deliver on the 10x productivity promise while remaining maintainable and extensible.