# ADR-003: File-Based Message Queue for Agent Communication

**Status**: Accepted  
**Date**: 2025-08-05  
**Decision Makers**: Architecture Team  
**Related Issues**: #24, #25

## Context

Agents need to communicate asynchronously in ClaudeProjects2. Traditional message queue solutions (RabbitMQ, Redis, Kafka) require separate services, which conflicts with our agent-based architecture and local-first principle.

### Requirements
- Asynchronous message passing between agents
- Message persistence and durability
- Priority queuing
- No external dependencies
- Simple debugging and inspection
- Work with file system events

## Decision

We will implement a **file-based message queue** using the local file system:

1. Messages are JSON files in designated directories
2. Directory structure provides queue organization
3. File names include timestamp for ordering
4. Atomic file operations ensure consistency
5. File system watchers enable real-time communication

## Consequences

### Positive
- **Zero Dependencies**: Uses only file system
- **Transparent**: Messages are human-readable files
- **Debuggable**: Can inspect queue state directly
- **Durable**: Messages persist through crashes
- **Simple**: No complex protocols or services
- **Fast**: Local file I/O is quick

### Negative
- **File System Limits**: Max files per directory
- **I/O Overhead**: Each message requires file operations
- **No Remote Access**: Only works locally
- **Cleanup Required**: Old messages must be archived

### Neutral
- Performance depends on file system
- Requires careful directory structure design
- File locking needed for consistency

## Implementation

### Directory Structure
```
.claudeprojects/messages/
├── queues/                    # Active message queues
│   ├── {agent-id}/           # Per-agent inbox
│   │   ├── priority/         # High priority messages
│   │   ├── normal/           # Normal priority
│   │   └── low/              # Low priority
├── processing/               # Messages being processed
│   └── {agent-id}/
│       └── {msg-id}.lock    # Lock files
├── dead-letter/             # Failed messages
└── archive/                 # Completed messages
```

### Message Format
```json
{
  "header": {
    "id": "msg-uuid",
    "timestamp": "2024-01-15T10:00:00Z",
    "from": "orchestrator-agent",
    "to": "methodology-agent",
    "priority": "normal",
    "ttl": 300000
  },
  "body": {
    "type": "request",
    "action": "execute_phase",
    "payload": { }
  }
}
```

### Atomic Operations
```typescript
// Atomic write using rename
async function writeMessage(message: Message) {
  const tempPath = `.tmp-${message.id}`;
  const finalPath = `${timestamp}-${message.id}.json`;
  
  await fs.writeFile(tempPath, JSON.stringify(message));
  await fs.rename(tempPath, finalPath); // Atomic
}

// Lock-based processing
async function processMessage(path: string) {
  const lockPath = `${path}.lock`;
  
  try {
    // Create lock (fails if exists)
    await fs.writeFile(lockPath, process.pid, { flag: 'wx' });
    
    // Process message
    const message = JSON.parse(await fs.readFile(path));
    await handleMessage(message);
    
    // Cleanup
    await fs.unlink(path);
    await fs.unlink(lockPath);
  } catch (e) {
    if (e.code === 'EEXIST') {
      // Another agent is processing
      return;
    }
    throw e;
  }
}
```

## Alternatives Considered

### 1. In-Memory Message Passing
- Direct agent-to-agent communication
- Rejected: No persistence, complex coordination

### 2. SQLite-Based Queue
- Messages in database tables
- Rejected: More complex, requires SQL

### 3. Named Pipes / Unix Sockets
- OS-level IPC mechanisms
- Rejected: Platform-specific, no persistence

### 4. External Message Queue
- Redis, RabbitMQ, etc.
- Rejected: Requires additional services

## Performance Considerations

### Benchmarks
- Message write: < 5ms
- Message read: < 2ms  
- Queue scan: < 10ms for 1000 messages
- File watch latency: < 100ms

### Optimizations
- Batch processing for high throughput
- Directory sharding for large queues
- Periodic archival of old messages
- Memory-mapped files for large payloads

## Monitoring

### Metrics
```typescript
interface QueueMetrics {
  messagesPerSecond: number;
  averageLatency: number;
  queueDepth: number;
  deadLetterCount: number;
  oldestMessage: Date;
}
```

## References

- File system atomic operations
- Message queue patterns
- [Agent Communication Protocol design](./Agent-Communication-Protocol.md)

## Review

Review after processing 10,000 messages to evaluate performance and identify bottlenecks.