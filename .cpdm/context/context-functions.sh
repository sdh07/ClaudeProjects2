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
