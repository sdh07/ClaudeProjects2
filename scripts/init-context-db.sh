#!/bin/bash
# Initialize context database for ClaudeProjects2
# Part of Sprint 8: Sub-Agent Architecture Alignment

set -e

# Configuration
CONTEXT_DIR=".cpdm/context"
CONTEXT_DB="$CONTEXT_DIR/contexts.db"
BACKUP_DIR="$CONTEXT_DIR/backups"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Context Database Initialization${NC}"
echo "================================"

# Create directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p "$CONTEXT_DIR"
mkdir -p "$BACKUP_DIR"
mkdir -p ".cpdm/metrics"
mkdir -p ".cpdm/patterns"
mkdir -p ".cpdm/config"

# Backup existing database if it exists
if [ -f "$CONTEXT_DB" ]; then
    BACKUP_FILE="$BACKUP_DIR/contexts-$(date +%Y%m%d-%H%M%S).db"
    echo -e "${YELLOW}Backing up existing database to $BACKUP_FILE${NC}"
    cp "$CONTEXT_DB" "$BACKUP_FILE"
fi

# Initialize database
echo -e "${YELLOW}Creating database schema...${NC}"

sqlite3 "$CONTEXT_DB" <<'EOF'
-- Enable foreign keys
PRAGMA foreign_keys = ON;

-- Main context table
CREATE TABLE IF NOT EXISTS contexts (
    id TEXT PRIMARY KEY,
    task_id TEXT NOT NULL,
    parent_id TEXT,
    state TEXT NOT NULL DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    version INTEGER DEFAULT 1,
    status TEXT DEFAULT 'active',
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
    reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (context_id) REFERENCES contexts(id)
);

-- Agent registry for capability tracking
CREATE TABLE IF NOT EXISTS agents (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT,
    capabilities TEXT,
    performance_metrics TEXT,
    last_active TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Message context mapping
CREATE TABLE IF NOT EXISTS message_contexts (
    message_id TEXT PRIMARY KEY,
    context_id TEXT NOT NULL,
    from_agent TEXT,
    to_agent TEXT,
    priority TEXT DEFAULT 'normal',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (context_id) REFERENCES contexts(id)
);

-- Performance metrics
CREATE TABLE IF NOT EXISTS performance_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    context_id TEXT,
    agent_id TEXT,
    operation TEXT,
    duration_ms INTEGER,
    success BOOLEAN,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (context_id) REFERENCES contexts(id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_contexts_task ON contexts(task_id);
CREATE INDEX IF NOT EXISTS idx_contexts_parent ON contexts(parent_id);
CREATE INDEX IF NOT EXISTS idx_contexts_status ON contexts(status);
CREATE INDEX IF NOT EXISTS idx_events_context ON context_events(context_id);
CREATE INDEX IF NOT EXISTS idx_events_timestamp ON context_events(timestamp);
CREATE INDEX IF NOT EXISTS idx_checkpoints_context ON checkpoints(context_id);
CREATE INDEX IF NOT EXISTS idx_message_contexts ON message_contexts(context_id);
CREATE INDEX IF NOT EXISTS idx_metrics_context ON performance_metrics(context_id);
CREATE INDEX IF NOT EXISTS idx_metrics_agent ON performance_metrics(agent_id);

-- Create triggers for updated_at
CREATE TRIGGER IF NOT EXISTS update_context_timestamp 
    AFTER UPDATE ON contexts
    FOR EACH ROW
    BEGIN
        UPDATE contexts SET updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.id;
    END;

-- Insert system context
INSERT OR IGNORE INTO contexts (id, task_id, state, status)
VALUES ('ctx-system', 'system', '{}', 'active');

-- Insert context-manager agent
INSERT OR IGNORE INTO agents (id, name, type, capabilities)
VALUES (
    'context-manager',
    'Context Manager',
    'core',
    '{"domains": ["context-management"], "skills": ["persistence", "recovery"]}'
);

-- Verify schema
SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;
EOF

echo -e "${GREEN}✓ Database schema created${NC}"

# Create helper functions script
echo -e "${YELLOW}Creating context helper functions...${NC}"

cat > "$CONTEXT_DIR/context-functions.sh" <<'EOF'
#!/bin/bash
# Context management helper functions

CONTEXT_DB=".cpdm/context/contexts.db"

# Generate UUID
generate_uuid() {
    uuidgen | tr '[:upper:]' '[:lower:]'
}

# Create new context
create_context() {
    local task_id="$1"
    local parent_id="${2:-}"
    local initial_state="${3:-{}}"
    local context_id="ctx-$(generate_uuid)"
    
    if [ -n "$parent_id" ]; then
        sqlite3 "$CONTEXT_DB" <<SQL
INSERT INTO contexts (id, task_id, parent_id, state)
VALUES ('$context_id', '$task_id', '$parent_id', '$initial_state');
SQL
    else
        sqlite3 "$CONTEXT_DB" <<SQL
INSERT INTO contexts (id, task_id, state)
VALUES ('$context_id', '$task_id', '$initial_state');
SQL
    fi
    
    echo "$context_id"
}

# Get context
get_context() {
    local context_id="$1"
    sqlite3 -json "$CONTEXT_DB" \
        "SELECT * FROM contexts WHERE id='$context_id';"
}

# Update context state
update_context() {
    local context_id="$1"
    local new_state="$2"
    
    sqlite3 "$CONTEXT_DB" <<SQL
UPDATE contexts 
SET state = '$new_state',
    version = version + 1
WHERE id = '$context_id';
SQL
}

# Create checkpoint
create_checkpoint() {
    local context_id="$1"
    local reason="${2:-Manual checkpoint}"
    local checkpoint_id="chk-$(generate_uuid)"
    
    sqlite3 "$CONTEXT_DB" <<SQL
INSERT INTO checkpoints (id, context_id, state_snapshot, reason)
SELECT '$checkpoint_id', id, state, '$reason'
FROM contexts WHERE id = '$context_id';
SQL
    
    echo "$checkpoint_id"
}

# Log context event
log_context_event() {
    local context_id="$1"
    local event_type="$2"
    local agent_id="${3:-}"
    local data="${4:-}"
    
    sqlite3 "$CONTEXT_DB" <<SQL
INSERT INTO context_events (context_id, event_type, agent_id, data)
VALUES ('$context_id', '$event_type', '$agent_id', '$data');
SQL
}

# Get context state
get_context_state() {
    local context_id="$1"
    sqlite3 -line "$CONTEXT_DB" \
        "SELECT state FROM contexts WHERE id='$context_id';" | \
        grep "state" | cut -d'=' -f2- | xargs
}

# List active contexts
list_active_contexts() {
    sqlite3 -json "$CONTEXT_DB" \
        "SELECT id, task_id, created_at FROM contexts WHERE status='active' ORDER BY created_at DESC;"
}
EOF

chmod +x "$CONTEXT_DIR/context-functions.sh"
echo -e "${GREEN}✓ Helper functions created${NC}"

# Create context-aware message queue wrapper
echo -e "${YELLOW}Creating context-queue wrapper...${NC}"

cat > "scripts/context-queue.sh" <<'EOF'
#!/bin/bash
# Context-aware message queue wrapper
# Integrates context management with existing message queue

source .cpdm/context/context-functions.sh

# Send message with context
send_with_context() {
    local from="$1"
    local to="$2"
    local type="$3"
    local data="$4"
    local context_id="$5"
    local priority="${6:-normal}"
    
    # Validate context exists
    if [ -z "$(get_context "$context_id")" ]; then
        echo -e "${RED}Error: Context $context_id not found${NC}" >&2
        return 1
    fi
    
    # Get current context state
    local context_state=$(get_context_state "$context_id")
    
    # Create enhanced payload with context
    local enhanced_data=$(jq -n \
        --arg ctx "$context_id" \
        --argjson state "$context_state" \
        --argjson data "$data" \
        '{context_id: $ctx, context_state: $state, payload: $data}')
    
    # Generate message ID
    local message_id="msg-$(generate_uuid)"
    
    # Log to message_contexts table
    sqlite3 "$CONTEXT_DB" <<SQL
INSERT INTO message_contexts (message_id, context_id, from_agent, to_agent, priority)
VALUES ('$message_id', '$context_id', '$from', '$to', '$priority');
SQL
    
    # Send via existing message queue
    ./scripts/message-queue-v2.sh send "$from" "$to" "$type" "$enhanced_data" "$priority"
    
    # Log context event
    log_context_event "$context_id" "message_sent" "$from" \
        "{\"to\": \"$to\", \"type\": \"$type\", \"message_id\": \"$message_id\"}"
    
    echo "Message $message_id sent with context $context_id"
}

# Receive message and extract context
receive_with_context() {
    local agent="$1"
    
    # Receive from existing queue
    local result=$(./scripts/message-queue-v2.sh receive "$agent")
    
    if [ -n "$result" ]; then
        # Extract context_id from message
        local context_id=$(echo "$result" | head -n -1 | jq -r '.body.payload.context_id // empty')
        
        if [ -n "$context_id" ]; then
            # Log context event
            log_context_event "$context_id" "message_received" "$agent"
            
            # Update agent last_active
            sqlite3 "$CONTEXT_DB" \
                "UPDATE agents SET last_active = CURRENT_TIMESTAMP WHERE id = '$agent';"
        fi
        
        echo "$result"
    fi
}

# Main command handler
case "$1" in
    create)
        create_context "$2" "$3" "$4"
        ;;
    send)
        send_with_context "$2" "$3" "$4" "$5" "$6" "$7"
        ;;
    receive)
        receive_with_context "$2"
        ;;
    get)
        get_context "$2"
        ;;
    update)
        update_context "$2" "$3"
        ;;
    checkpoint)
        create_checkpoint "$2" "$3"
        ;;
    list)
        list_active_contexts
        ;;
    *)
        echo "Usage: $0 {create|send|receive|get|update|checkpoint|list} [args...]"
        echo ""
        echo "Commands:"
        echo "  create <task_id> [parent_id] [initial_state]  - Create new context"
        echo "  send <from> <to> <type> <data> <context_id> [priority] - Send with context"
        echo "  receive <agent>                               - Receive with context"
        echo "  get <context_id>                              - Get context details"
        echo "  update <context_id> <new_state>               - Update context state"
        echo "  checkpoint <context_id> [reason]              - Create checkpoint"
        echo "  list                                          - List active contexts"
        exit 1
        ;;
esac
EOF

chmod +x "scripts/context-queue.sh"
echo -e "${GREEN}✓ Context-queue wrapper created${NC}"

# Test the setup
echo -e "${YELLOW}Testing context system...${NC}"

# Create test context
TEST_CTX=$(./scripts/context-queue.sh create "test-task-001" "" '{"test": true}')
echo -e "${GREEN}✓ Test context created: $TEST_CTX${NC}"

# Create checkpoint
TEST_CHK=$(source "$CONTEXT_DIR/context-functions.sh" && create_checkpoint "$TEST_CTX" "Test checkpoint")
echo -e "${GREEN}✓ Test checkpoint created: $TEST_CHK${NC}"

# Verify database
echo -e "\n${GREEN}Database Statistics:${NC}"
sqlite3 "$CONTEXT_DB" <<EOF
SELECT 'Contexts' as table_name, COUNT(*) as count FROM contexts
UNION ALL
SELECT 'Events', COUNT(*) FROM context_events
UNION ALL  
SELECT 'Checkpoints', COUNT(*) FROM checkpoints
UNION ALL
SELECT 'Agents', COUNT(*) FROM agents;
EOF

echo -e "\n${GREEN}✅ Context database initialization complete!${NC}"
echo -e "${YELLOW}Database location: $CONTEXT_DB${NC}"
echo -e "${YELLOW}Helper functions: $CONTEXT_DIR/context-functions.sh${NC}"
echo -e "${YELLOW}Context queue wrapper: scripts/context-queue.sh${NC}"

echo -e "\n${GREEN}Next steps:${NC}"
echo "1. Test context creation: ./scripts/context-queue.sh create 'my-task'"
echo "2. Send context message: ./scripts/context-queue.sh send 'agent1' 'agent2' 'task' '{}' '$TEST_CTX'"
echo "3. List contexts: ./scripts/context-queue.sh list"