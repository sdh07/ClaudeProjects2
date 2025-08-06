#!/bin/bash
# Context Persistence Layer for ClaudeProjects2
# Sprint 8, Day 3: Advanced context management

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTEXT_DB="$PROJECT_ROOT/.cpdm/context/contexts.db"
CONTEXT_CACHE="$PROJECT_ROOT/.cpdm/context/cache"
CONTEXT_ARCHIVE="$PROJECT_ROOT/.cpdm/context/archive"

# Source helper functions
source "$PROJECT_ROOT/.cpdm/context/context-functions.sh"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Create directories
mkdir -p "$CONTEXT_CACHE"
mkdir -p "$CONTEXT_ARCHIVE"

# ============================================
# Context Versioning System
# ============================================

# Create new version of context
version_context() {
    local context_id="$1"
    local reason="${2:-Update}"
    
    # Get current version
    local current_version=$(sqlite3 "$CONTEXT_DB" \
        "SELECT version FROM contexts WHERE id='$context_id';")
    
    if [ -z "$current_version" ]; then
        echo -e "${RED}Context not found: $context_id${NC}" >&2
        return 1
    fi
    
    # Create version record
    sqlite3 "$CONTEXT_DB" <<SQL
INSERT INTO context_versions (context_id, version, state, reason, created_at)
SELECT id, version, state, '$reason', CURRENT_TIMESTAMP
FROM contexts WHERE id='$context_id';
SQL
    
    # Increment version
    sqlite3 "$CONTEXT_DB" <<SQL
UPDATE contexts 
SET version = version + 1
WHERE id='$context_id';
SQL
    
    echo -e "${GREEN}Created version $((current_version + 1)) for context $context_id${NC}"
}

# Restore context to specific version
restore_version() {
    local context_id="$1"
    local target_version="$2"
    
    # Get versioned state
    local versioned_state=$(sqlite3 "$CONTEXT_DB" \
        "SELECT state FROM context_versions 
         WHERE context_id='$context_id' AND version=$target_version;")
    
    if [ -z "$versioned_state" ]; then
        echo -e "${RED}Version not found: $context_id v$target_version${NC}" >&2
        return 1
    fi
    
    # Create checkpoint before restore
    create_checkpoint "$context_id" "Before restore to v$target_version"
    
    # Restore state
    sqlite3 "$CONTEXT_DB" <<SQL
UPDATE contexts 
SET state = '$versioned_state',
    version = $target_version + 1
WHERE id='$context_id';
SQL
    
    log_context_event "$context_id" "version_restored" "" \
        "{\"restored_to\": $target_version}"
    
    echo -e "${GREEN}Restored context to version $target_version${NC}"
}

# ============================================
# Context Recovery Mechanisms
# ============================================

# Auto-recovery on corruption
auto_recover() {
    local context_id="$1"
    
    echo -e "${YELLOW}Attempting auto-recovery for $context_id...${NC}"
    
    # Try to load latest checkpoint
    local latest_checkpoint=$(sqlite3 "$CONTEXT_DB" \
        "SELECT id FROM checkpoints 
         WHERE context_id='$context_id' 
         ORDER BY created_at DESC LIMIT 1;")
    
    if [ -n "$latest_checkpoint" ]; then
        echo -e "${BLUE}Found checkpoint: $latest_checkpoint${NC}"
        
        # Restore from checkpoint
        sqlite3 "$CONTEXT_DB" <<SQL
UPDATE contexts
SET state = (
    SELECT state_snapshot FROM checkpoints 
    WHERE id='$latest_checkpoint'
),
status = 'recovered'
WHERE id='$context_id';
SQL
        
        log_context_event "$context_id" "auto_recovered" "" \
            "{\"checkpoint\": \"$latest_checkpoint\"}"
        
        echo -e "${GREEN}Successfully recovered from checkpoint${NC}"
        return 0
    fi
    
    # Try parent context
    local parent_id=$(sqlite3 "$CONTEXT_DB" \
        "SELECT parent_id FROM contexts WHERE id='$context_id';")
    
    if [ -n "$parent_id" ] && [ "$parent_id" != "null" ]; then
        echo -e "${BLUE}Inheriting from parent: $parent_id${NC}"
        
        # Inherit parent state
        sqlite3 "$CONTEXT_DB" <<SQL
UPDATE contexts
SET state = (
    SELECT state FROM contexts WHERE id='$parent_id'
),
status = 'recovered'
WHERE id='$context_id';
SQL
        
        log_context_event "$context_id" "recovered_from_parent" "" \
            "{\"parent\": \"$parent_id\"}"
        
        echo -e "${GREEN}Recovered from parent context${NC}"
        return 0
    fi
    
    # Last resort: Reset to empty state
    echo -e "${YELLOW}No recovery source found, resetting to empty state${NC}"
    sqlite3 "$CONTEXT_DB" \
        "UPDATE contexts SET state='{}', status='reset' WHERE id='$context_id';"
    
    log_context_event "$context_id" "reset" "" "{\"reason\": \"no_recovery_source\"}"
}

# Validate context integrity
validate_context() {
    local context_id="$1"
    
    # Check if context exists
    local exists=$(sqlite3 "$CONTEXT_DB" \
        "SELECT COUNT(*) FROM contexts WHERE id='$context_id';")
    
    if [ "$exists" -eq 0 ]; then
        echo -e "${RED}Context does not exist${NC}"
        return 1
    fi
    
    # Get context state
    local state=$(sqlite3 "$CONTEXT_DB" \
        "SELECT state FROM contexts WHERE id='$context_id';")
    
    # Validate JSON
    if ! echo "$state" | jq . > /dev/null 2>&1; then
        echo -e "${RED}Invalid JSON state${NC}"
        auto_recover "$context_id"
        return 1
    fi
    
    echo -e "${GREEN}Context valid${NC}"
    return 0
}

# ============================================
# Context Compression
# ============================================

# Compress large contexts
compress_context() {
    local context_id="$1"
    
    # Get context size
    local state_size=$(sqlite3 "$CONTEXT_DB" \
        "SELECT LENGTH(state) FROM contexts WHERE id='$context_id';")
    
    # Compress if larger than 100KB
    if [ "$state_size" -gt 100000 ]; then
        echo -e "${YELLOW}Compressing large context ($state_size bytes)...${NC}"
        
        # Export state
        local state=$(sqlite3 "$CONTEXT_DB" \
            "SELECT state FROM contexts WHERE id='$context_id';")
        
        # Compress
        echo "$state" | gzip > "$CONTEXT_CACHE/$context_id.gz"
        
        # Store reference
        sqlite3 "$CONTEXT_DB" <<SQL
UPDATE contexts 
SET state = '{"compressed": true, "path": "$CONTEXT_CACHE/$context_id.gz"}',
    compressed = 1
WHERE id='$context_id';
SQL
        
        local compressed_size=$(stat -f%z "$CONTEXT_CACHE/$context_id.gz" 2>/dev/null || \
                               stat -c%s "$CONTEXT_CACHE/$context_id.gz" 2>/dev/null)
        
        echo -e "${GREEN}Compressed from $state_size to $compressed_size bytes${NC}"
    fi
}

# Decompress context
decompress_context() {
    local context_id="$1"
    
    # Check if compressed
    local compressed=$(sqlite3 "$CONTEXT_DB" \
        "SELECT compressed FROM contexts WHERE id='$context_id';")
    
    if [ "$compressed" -eq 1 ]; then
        echo -e "${YELLOW}Decompressing context...${NC}"
        
        # Decompress
        local state=$(gunzip -c "$CONTEXT_CACHE/$context_id.gz")
        
        # Update database
        sqlite3 "$CONTEXT_DB" <<SQL
UPDATE contexts 
SET state = '$state',
    compressed = 0
WHERE id='$context_id';
SQL
        
        # Remove compressed file
        rm -f "$CONTEXT_CACHE/$context_id.gz"
        
        echo -e "${GREEN}Context decompressed${NC}"
    fi
}

# ============================================
# Message Queue Integration
# ============================================

# Enhanced send with automatic context
send_with_auto_context() {
    local from="$1"
    local to="$2"
    local type="$3"
    local data="$4"
    local priority="${5:-normal}"
    
    # Get or create context for current task
    local task_id=$(echo "$data" | jq -r '.task_id // "default"')
    local context_id=$(sqlite3 "$CONTEXT_DB" \
        "SELECT id FROM contexts WHERE task_id='$task_id' AND status='active' LIMIT 1;")
    
    if [ -z "$context_id" ]; then
        # Create new context
        context_id=$(create_context "$task_id" "" "{\"created_by\": \"$from\"}")
        echo -e "${BLUE}Created new context: $context_id${NC}"
    fi
    
    # Validate context
    validate_context "$context_id"
    
    # Send with context
    ./scripts/context-queue.sh send "$from" "$to" "$type" "$data" "$context_id" "$priority"
}

# ============================================
# Context Garbage Collection
# ============================================

# Clean up old contexts
gc_contexts() {
    local days_old="${1:-30}"
    
    echo -e "${YELLOW}Running context garbage collection...${NC}"
    
    # Archive old contexts
    local archived=0
    while IFS='|' read -r context_id task_id state; do
        # Compress and archive
        echo "$state" | gzip > "$CONTEXT_ARCHIVE/$context_id.json.gz"
        
        # Remove from database
        sqlite3 "$CONTEXT_DB" "DELETE FROM contexts WHERE id='$context_id';"
        
        ((archived++))
    done < <(sqlite3 -separator '|' "$CONTEXT_DB" \
        "SELECT id, task_id, state FROM contexts 
         WHERE status IN ('completed', 'failed', 'abandoned') 
         AND datetime(updated_at) < datetime('now', '-$days_old days');")
    
    # Clean orphaned checkpoints
    sqlite3 "$CONTEXT_DB" <<SQL
DELETE FROM checkpoints 
WHERE context_id NOT IN (SELECT id FROM contexts);
SQL
    
    # Clean old events
    sqlite3 "$CONTEXT_DB" <<SQL
DELETE FROM context_events 
WHERE datetime(timestamp) < datetime('now', '-90 days');
SQL
    
    # Vacuum database
    sqlite3 "$CONTEXT_DB" "VACUUM;"
    
    echo -e "${GREEN}Archived $archived contexts${NC}"
}

# ============================================
# Debugging Tools
# ============================================

# Context inspector
inspect_context() {
    local context_id="$1"
    
    echo -e "${BLUE}=== Context Inspector ===${NC}"
    echo -e "${YELLOW}Context ID:${NC} $context_id"
    
    # Basic info
    sqlite3 -column -header "$CONTEXT_DB" <<SQL
SELECT id, task_id, parent_id, status, version, 
       datetime(created_at) as created, 
       datetime(updated_at) as updated
FROM contexts WHERE id='$context_id';
SQL
    
    # State size
    local state_size=$(sqlite3 "$CONTEXT_DB" \
        "SELECT LENGTH(state) FROM contexts WHERE id='$context_id';")
    echo -e "\n${YELLOW}State size:${NC} $state_size bytes"
    
    # Checkpoints
    echo -e "\n${YELLOW}Checkpoints:${NC}"
    sqlite3 -column "$CONTEXT_DB" <<SQL
SELECT id, reason, datetime(created_at) as created
FROM checkpoints WHERE context_id='$context_id'
ORDER BY created_at DESC LIMIT 5;
SQL
    
    # Recent events
    echo -e "\n${YELLOW}Recent events:${NC}"
    sqlite3 -column "$CONTEXT_DB" <<SQL
SELECT event_type, agent_id, datetime(timestamp) as time
FROM context_events WHERE context_id='$context_id'
ORDER BY timestamp DESC LIMIT 10;
SQL
    
    # State preview
    echo -e "\n${YELLOW}State preview:${NC}"
    sqlite3 "$CONTEXT_DB" \
        "SELECT state FROM contexts WHERE id='$context_id';" | \
        jq '.' 2>/dev/null | head -20
}

# Context trace
trace_context() {
    local context_id="$1"
    
    echo -e "${BLUE}=== Context Trace ===${NC}"
    
    sqlite3 -column -header "$CONTEXT_DB" <<SQL
SELECT 
    e.event_type,
    e.agent_id,
    datetime(e.timestamp) as time,
    substr(e.data, 1, 50) as data_preview
FROM context_events e
WHERE e.context_id='$context_id'
ORDER BY e.timestamp;
SQL
}

# ============================================
# Main command handler
# ============================================

case "${1:-help}" in
    version)
        version_context "$2" "$3"
        ;;
    restore)
        restore_version "$2" "$3"
        ;;
    recover)
        auto_recover "$2"
        ;;
    validate)
        validate_context "$2"
        ;;
    compress)
        compress_context "$2"
        ;;
    decompress)
        decompress_context "$2"
        ;;
    gc)
        gc_contexts "${2:-30}"
        ;;
    inspect)
        inspect_context "$2"
        ;;
    trace)
        trace_context "$2"
        ;;
    send)
        send_with_auto_context "$2" "$3" "$4" "$5" "$6"
        ;;
    help|*)
        echo "Context Persistence Layer"
        echo "Usage: $0 <command> [args...]"
        echo ""
        echo "Commands:"
        echo "  version <context_id> [reason]     - Create new version"
        echo "  restore <context_id> <version>    - Restore to version"
        echo "  recover <context_id>              - Auto-recover corrupted context"
        echo "  validate <context_id>             - Validate context integrity"
        echo "  compress <context_id>             - Compress large context"
        echo "  decompress <context_id>           - Decompress context"
        echo "  gc [days]                         - Garbage collect old contexts"
        echo "  inspect <context_id>              - Inspect context details"
        echo "  trace <context_id>                - Show context event trace"
        echo "  send <from> <to> <type> <data>    - Send with auto-context"
        ;;
esac