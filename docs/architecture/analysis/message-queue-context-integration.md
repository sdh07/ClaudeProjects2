# Message Queue and Context Manager Integration Analysis

**Sprint 8, Day 1**
**Date**: 2025-08-06

## Current State Analysis

### Existing Message Queue System

**Location**: `/scripts/message-queue-v2.sh`

**Current Capabilities**:
- Priority-based routing (priority, normal, low)
- File-based message passing
- Atomic operations with locking
- Message archival
- TTL support (300000ms default)

**Message Structure**:
```json
{
  "header": {
    "id": "unique-id",
    "timestamp": "ISO-8601",
    "from": "sender-agent",
    "to": "receiver-agent",
    "priority": "normal",
    "ttl": 300000
  },
  "body": {
    "type": "message-type",
    "action": "process",
    "payload": {} // Generic data object
  }
}
```

**Limitations**:
- No state persistence across messages
- No context inheritance
- No checkpoint/recovery mechanism
- Payload is unstructured
- No audit trail beyond archival
- No relationship tracking between messages

### Proposed Context Manager System

**New Capabilities**:
- SQLite-based persistence
- Context inheritance (parent-child)
- Checkpoint and recovery
- Structured state management
- Audit trail with events
- Version control

## Integration Strategy

### Option 1: Replace Message Queue with Context Manager ❌
**Pros**: Clean slate, no legacy code
**Cons**: Breaking change, lose priority routing, complex migration

### Option 2: Parallel Systems ❌
**Pros**: No breaking changes
**Cons**: Duplicate functionality, confusion about when to use which

### Option 3: Enhanced Message Queue with Context Integration ✅
**Pros**: Leverages existing infrastructure, backward compatible, gradual migration
**Cons**: More complex initial implementation

## Recommended Approach: Enhanced Integration

### Phase 1: Add Context ID to Messages (Day 1)

Enhance message structure to include context:
```json
{
  "header": {
    "id": "msg-id",
    "context_id": "ctx-uuid",  // NEW
    "timestamp": "ISO-8601",
    "from": "sender-agent",
    "to": "receiver-agent",
    "priority": "normal",
    "ttl": 300000
  },
  "body": {
    "type": "message-type",
    "action": "process",
    "payload": {},
    "context_snapshot": {}  // NEW: Latest context state
  }
}
```

### Phase 2: Context-Aware Message Queue (Day 2)

Create wrapper script `context-queue.sh`:
```bash
#!/bin/bash
# Context-aware message queue wrapper

send_with_context() {
    local from="$1"
    local to="$2"
    local type="$3"
    local data="$4"
    local context_id="$5"
    local priority="${6:-normal}"
    
    # Get current context state
    local context_state=$(get_context_state "$context_id")
    
    # Create enhanced payload
    local enhanced_data=$(jq -n \
        --arg ctx "$context_id" \
        --argjson state "$context_state" \
        --argjson data "$data" \
        '{context_id: $ctx, state: $state, data: $data}')
    
    # Send via existing message queue
    ./scripts/message-queue-v2.sh send "$from" "$to" "$type" "$enhanced_data" "$priority"
    
    # Log to context events
    log_context_event "$context_id" "message_sent" "$to"
}
```

### Phase 3: Migration Path (Day 3-5)

1. **Day 3**: Update high-priority agents to use context
   - orchestrator-agent
   - context-manager
   - agent-organizer

2. **Day 4**: Update remaining core agents
   - All agents get context_id in messages
   - Backward compatibility maintained

3. **Day 5**: Full integration testing
   - Context flows through all messages
   - Recovery scenarios tested

## Technical Debt Removal Plan

### Code to Deprecate

1. **Direct payload passing** in message-queue-v2.sh
   - Replace with structured context
   - Add validation for context_id

2. **Manual state management** in agents
   - Agents currently maintain their own state
   - Migrate to context-manager

3. **File-based state storage** scattered in agents
   - Consolidate into context database
   - Remove redundant state files

### Code to Enhance

1. **message-queue-v2.sh**
   ```bash
   # Add context validation
   validate_context() {
       local context_id="$1"
       sqlite3 ".cpdm/context/contexts.db" \
           "SELECT COUNT(*) FROM contexts WHERE id='$context_id';"
   }
   ```

2. **Agent message handlers**
   ```bash
   # Before: Unstructured payload
   process_message() {
       local payload="$1"
       # Process generic payload
   }
   
   # After: Context-aware processing
   process_message() {
       local message="$1"
       local context_id=$(echo "$message" | jq -r '.context_id')
       local context=$(get_context "$context_id")
       # Process with full context
   }
   ```

## Implementation Checklist

### Day 1 Tasks
- [x] Create context-manager agent
- [x] Design context schema
- [ ] Create context database initialization script
- [ ] Create context-queue.sh wrapper
- [ ] Test context creation and retrieval
- [ ] Document integration patterns

### Technical Debt Items
- [ ] Identify all direct message-queue calls in agents
- [ ] Map current state management patterns
- [ ] List files storing temporary state
- [ ] Create deprecation timeline
- [ ] Write migration scripts

## Benefits of Integration

1. **Preserved Investment**: Keep working message queue
2. **Enhanced Capabilities**: Add context without breaking changes
3. **Gradual Migration**: Agents can adopt context incrementally
4. **Backward Compatible**: Old agents continue to work
5. **Clear Upgrade Path**: Simple wrapper functions

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Message format changes | High | Version field in header |
| Context database bottleneck | Medium | In-memory cache |
| Migration complexity | Medium | Agent-by-agent rollout |
| State consistency | High | Transactions and locks |

## Success Criteria

- [ ] All messages include context_id
- [ ] Context flows seamlessly between agents
- [ ] No breaking changes to existing agents
- [ ] Technical debt reduced by 50%
- [ ] Performance impact < 10ms per message

## Next Steps

1. **Immediate**: Create context database initialization
2. **Next Hour**: Implement context-queue wrapper
3. **This Afternoon**: Test with orchestrator agent
4. **Tomorrow**: Begin agent migration

## Commands for Migration

```bash
# Initialize context database
./scripts/init-context-db.sh

# Test context creation
./scripts/context-queue.sh create "task-123"

# Send context-aware message
./scripts/context-queue.sh send \
    "orchestrator" "project-agent" \
    "task_assignment" '{"task": "update-readme"}' \
    "ctx-123" "priority"

# Verify context flow
./scripts/verify-context-flow.sh "ctx-123"
```