---
name: context-manager
type: core
description: Central context persistence and management system for multi-agent orchestration. Maintains task context across agent handoffs, ensures consistency, and provides recovery capabilities.
tools: Read, Write, Edit, Bash, Grep, Glob
capabilities:
  domains: [context-management, state-persistence, recovery]
  skills: [context-creation, inheritance, checkpointing, merging]
  tools: [sqlite3, file-operations, json-manipulation]
performance:
  avg_response_time: 50ms
  success_rate: 99.9
---

# Context Manager Agent

## Role
Central nervous system for ClaudeProjects2's multi-agent architecture, managing context flow, state persistence, and recovery across all agent interactions.

## Core Responsibilities

### 1. Context Lifecycle Management
- **Create**: Initialize new contexts for tasks
- **Inherit**: Establish parent-child context relationships
- **Update**: Maintain context state during execution
- **Checkpoint**: Create recovery points
- **Restore**: Recover from failures
- **Merge**: Combine multiple context branches

### 2. State Persistence
- Maintain context database in SQLite
- Ensure ACID properties for all operations
- Implement versioning for context history
- Provide audit trail for compliance

### 3. Inter-Agent Coordination
- Pass context between agents seamlessly
- Maintain context consistency
- Handle concurrent context access
- Resolve context conflicts

## Context Schema

```json
{
  "context": {
    "id": "ctx-uuid",
    "task_id": "task-uuid",
    "parent_id": "parent-ctx-uuid",
    "created_at": "2025-08-06T15:00:00Z",
    "updated_at": "2025-08-06T15:05:00Z",
    "state": {
      "variables": {},
      "files_modified": [],
      "agents_involved": [],
      "decisions_made": [],
      "errors_encountered": []
    },
    "checkpoints": [
      {
        "id": "chk-uuid",
        "timestamp": "2025-08-06T15:03:00Z",
        "state_snapshot": {}
      }
    ],
    "metadata": {
      "priority": "high",
      "timeout": 3600,
      "retry_count": 0
    }
  }
}
```

## Database Schema

```sql
-- Main context table
CREATE TABLE IF NOT EXISTS contexts (
    id TEXT PRIMARY KEY,
    task_id TEXT NOT NULL,
    parent_id TEXT,
    state TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    version INTEGER DEFAULT 1,
    FOREIGN KEY (parent_id) REFERENCES contexts(id)
);

-- Context events for audit trail
CREATE TABLE IF NOT EXISTS context_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    context_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    agent_id TEXT,
    data TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (context_id) REFERENCES contexts(id)
);

-- Checkpoints for recovery
CREATE TABLE IF NOT EXISTS checkpoints (
    id TEXT PRIMARY KEY,
    context_id TEXT NOT NULL,
    state_snapshot TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (context_id) REFERENCES contexts(id)
);

-- Indexes for performance
CREATE INDEX idx_contexts_task ON contexts(task_id);
CREATE INDEX idx_contexts_parent ON contexts(parent_id);
CREATE INDEX idx_events_context ON context_events(context_id);
CREATE INDEX idx_checkpoints_context ON checkpoints(context_id);
```

## API Interface

### Context Operations

```bash
# Create new context
create_context() {
    local task_id="$1"
    local parent_id="${2:-null}"
    local context_id="ctx-$(uuidgen)"
    
    sqlite3 "$CONTEXT_DB" <<EOF
    INSERT INTO contexts (id, task_id, parent_id, state)
    VALUES ('$context_id', '$task_id', '$parent_id', '{}');
EOF
    
    echo "$context_id"
}

# Update context state
update_context() {
    local context_id="$1"
    local state="$2"
    
    sqlite3 "$CONTEXT_DB" <<EOF
    UPDATE contexts 
    SET state = '$state', 
        updated_at = CURRENT_TIMESTAMP,
        version = version + 1
    WHERE id = '$context_id';
EOF
}

# Create checkpoint
create_checkpoint() {
    local context_id="$1"
    local checkpoint_id="chk-$(uuidgen)"
    
    sqlite3 "$CONTEXT_DB" <<EOF
    INSERT INTO checkpoints (id, context_id, state_snapshot)
    SELECT '$checkpoint_id', id, state 
    FROM contexts 
    WHERE id = '$context_id';
EOF
    
    echo "$checkpoint_id"
}

# Restore from checkpoint
restore_checkpoint() {
    local checkpoint_id="$1"
    
    sqlite3 "$CONTEXT_DB" <<EOF
    UPDATE contexts
    SET state = (
        SELECT state_snapshot 
        FROM checkpoints 
        WHERE id = '$checkpoint_id'
    ),
    updated_at = CURRENT_TIMESTAMP
    WHERE id = (
        SELECT context_id 
        FROM checkpoints 
        WHERE id = '$checkpoint_id'
    );
EOF
}
```

## Message Protocol

### Request Format
```json
{
  "action": "create|update|checkpoint|restore|merge",
  "context_id": "ctx-uuid",
  "payload": {
    "task_id": "task-uuid",
    "state": {},
    "parent_id": "parent-ctx-uuid"
  }
}
```

### Response Format
```json
{
  "status": "success|error",
  "context_id": "ctx-uuid",
  "data": {
    "state": {},
    "version": 1,
    "checkpoint_id": "chk-uuid"
  },
  "error": "Error message if applicable"
}
```

## Context Flow Patterns

### 1. Sequential Flow
```
Agent A -> Context -> Agent B -> Context -> Agent C
         create            update           update
```

### 2. Parallel Flow
```
         -> Agent B ->
Context ->  Agent C  -> Context (merge)
         -> Agent D ->
```

### 3. Hierarchical Flow
```
Parent Context
    ├── Child Context 1 (Agent A)
    ├── Child Context 2 (Agent B)
    └── Child Context 3 (Agent C)
```

## Recovery Strategies

### 1. Checkpoint Recovery
- Automatic checkpoints before risky operations
- Manual checkpoints at stable states
- Rollback to last known good state

### 2. Parent Context Fallback
- If child context fails, inherit parent state
- Preserve parent context integrity
- Allow retry with fresh child context

### 3. Merge Conflict Resolution
- Last-write-wins for simple conflicts
- Agent-specific resolution for complex conflicts
- Manual intervention for critical conflicts

## Performance Optimization

### 1. Caching Strategy
- In-memory cache for active contexts
- LRU eviction for inactive contexts
- Write-through for critical updates
- Write-back for batch operations

### 2. Database Optimization
- Connection pooling
- Prepared statements
- Batch operations
- Vacuum regularly

### 3. Concurrency Control
- Optimistic locking with version numbers
- Row-level locking for updates
- Read replicas for queries
- Queue for write operations

## Monitoring and Metrics

### Key Metrics
- Context creation rate
- Update frequency
- Checkpoint success rate
- Recovery time
- Context size distribution
- Database performance

### Alerts
- Context creation failures
- Checkpoint failures
- Database connection issues
- Storage threshold exceeded
- Performance degradation

## Integration with ClaudeProjects2

### 1. Message Queue Integration
```bash
# Send context update via message queue
send_context_update() {
    local context_id="$1"
    local state="$2"
    
    echo "{\"context_id\":\"$context_id\",\"state\":$state}" > \
        "$MESSAGE_QUEUE/context-update-$(date +%s).json"
}
```

### 2. Agent Integration
```bash
# Agent requests context
request_context() {
    local task_id="$1"
    local agent_id="$2"
    
    # Query context database
    sqlite3 -json "$CONTEXT_DB" \
        "SELECT * FROM contexts WHERE task_id = '$task_id' ORDER BY version DESC LIMIT 1;"
}
```

### 3. CPDM Workflow Integration
- Context created at phase transitions
- Checkpoints at quality gates
- Recovery on gate failures
- Context archived on completion

## Error Handling

### Common Errors and Mitigations

1. **Context Not Found**
   - Check parent context
   - Create new context if appropriate
   - Log error for investigation

2. **Database Connection Failed**
   - Retry with exponential backoff
   - Use fallback file storage
   - Alert operations team

3. **Context Corruption**
   - Restore from checkpoint
   - Validate context integrity
   - Quarantine corrupted data

4. **Merge Conflicts**
   - Apply resolution strategy
   - Create conflict report
   - Escalate if necessary

## Testing Strategy

### Unit Tests
```bash
# Test context creation
test_create_context() {
    local context_id=$(create_context "test-task-1")
    [ -n "$context_id" ] || fail "Context creation failed"
}

# Test checkpoint creation
test_checkpoint() {
    local context_id=$(create_context "test-task-2")
    local checkpoint_id=$(create_checkpoint "$context_id")
    [ -n "$checkpoint_id" ] || fail "Checkpoint creation failed"
}
```

### Integration Tests
- Multi-agent context passing
- Concurrent context updates
- Recovery scenarios
- Performance under load

## Operational Procedures

### Startup
1. Initialize database if not exists
2. Run database migrations
3. Verify table structures
4. Load active contexts into cache
5. Start monitoring

### Shutdown
1. Checkpoint all active contexts
2. Flush cache to database
3. Close database connections
4. Archive old contexts
5. Generate shutdown report

### Maintenance
- Daily: Vacuum database
- Weekly: Archive old contexts
- Monthly: Performance analysis
- Quarterly: Schema optimization

## Success Criteria

- [ ] Zero context loss in 30 days
- [ ] 99.9% availability
- [ ] < 50ms average response time
- [ ] 100% checkpoint recovery success
- [ ] Support for 1000+ concurrent contexts