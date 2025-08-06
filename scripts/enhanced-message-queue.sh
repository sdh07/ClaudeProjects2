#!/bin/bash
# Enhanced Message Queue with Full Context Integration
# Sprint 8, Day 3: Context-aware messaging

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QUEUE_DIR="$PROJECT_ROOT/.claudeprojects/messages"
CONTEXT_DB="$PROJECT_ROOT/.cpdm/context/contexts.db"

# Source context functions
source "$PROJECT_ROOT/.cpdm/context/context-functions.sh"

# Enhanced message structure with context
send_enhanced_message() {
    local from="$1"
    local to="$2"
    local type="$3"
    local data="$4"
    local priority="${5:-normal}"
    
    # Extract or create context
    local task_id=$(echo "$data" | jq -r '.task_id // "task-'$(date +%s)'"')
    local context_id=$(echo "$data" | jq -r '.context_id // empty')
    
    if [ -z "$context_id" ]; then
        # Check for existing context for this task
        context_id=$(sqlite3 "$CONTEXT_DB" \
            "SELECT id FROM contexts WHERE task_id='$task_id' 
             AND status='active' ORDER BY created_at DESC LIMIT 1;")
        
        if [ -z "$context_id" ]; then
            # Create new context
            context_id=$(create_context "$task_id" "" \
                "{\"initiated_by\": \"$from\", \"target\": \"$to\"}")
            echo "Created new context: $context_id" >&2
        fi
    fi
    
    # Get current context state
    local context_state=$(get_context_state "$context_id")
    
    # Create checkpoint before sending to risky agents
    case "$to" in
        *test*|*build*|*deploy*)
            local checkpoint_id=$(create_checkpoint "$context_id" "Before $to")
            echo "Created checkpoint: $checkpoint_id" >&2
            ;;
    esac
    
    # Enhance message with full context
    local enhanced_data=$(jq -n \
        --arg ctx "$context_id" \
        --arg task "$task_id" \
        --argjson state "${context_state:-{}}" \
        --argjson original "$data" \
        '{
            context_id: $ctx,
            task_id: $task,
            context_state: $state,
            payload: $original,
            metadata: {
                from: "'$from'",
                to: "'$to'",
                type: "'$type'",
                priority: "'$priority'",
                timestamp: "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"
            }
        }')
    
    # Log context event
    log_context_event "$context_id" "message_sent" "$from" \
        "{\"to\": \"$to\", \"type\": \"$type\"}"
    
    # Send via original message queue
    ./scripts/message-queue-v2.sh send "$from" "$to" "$type" "$enhanced_data" "$priority"
    
    echo "Message sent with context $context_id"
}

# Receive and process with context
receive_enhanced_message() {
    local agent="$1"
    
    # Receive from queue
    local result=$(./scripts/message-queue-v2.sh receive "$agent")
    
    if [ -n "$result" ]; then
        # Extract message file path (last line)
        local msg_file=$(echo "$result" | tail -1)
        
        # Extract message content (all but last line)
        local msg_content=$(echo "$result" | head -n -1)
        
        # Extract context_id
        local context_id=$(echo "$msg_content" | jq -r '.body.payload.context_id // empty')
        
        if [ -n "$context_id" ]; then
            # Log receipt
            log_context_event "$context_id" "message_received" "$agent"
            
            # Update agent activity
            sqlite3 "$CONTEXT_DB" <<SQL
INSERT OR REPLACE INTO agents (id, name, type, last_active)
VALUES ('$agent', '$agent', 'unknown', CURRENT_TIMESTAMP);
SQL
            
            # Validate context
            if ! ./scripts/context-persistence.sh validate "$context_id" 2>/dev/null; then
                echo "Warning: Context validation failed, attempting recovery" >&2
                ./scripts/context-persistence.sh recover "$context_id"
            fi
        fi
        
        echo "$result"
    fi
}

# Process message and update context
process_with_context() {
    local agent="$1"
    local message="$2"
    local processing_result="$3"
    
    # Extract context_id
    local context_id=$(echo "$message" | jq -r '.body.payload.context_id // empty')
    
    if [ -n "$context_id" ]; then
        # Get current state
        local current_state=$(get_context_state "$context_id")
        
        # Merge with processing result
        local updated_state=$(jq -s '.[0] * .[1]' \
            <(echo "$current_state") \
            <(echo "$processing_result"))
        
        # Update context
        update_context "$context_id" "$updated_state"
        
        # Log processing
        log_context_event "$context_id" "processed" "$agent" \
            "{\"result_size\": $(echo "$processing_result" | wc -c)}"
        
        # Version if significant change
        local state_change=$(echo "$current_state $updated_state" | \
            jq -s 'if .[0] == .[1] then 0 else 1 end')
        
        if [ "$state_change" -eq 1 ]; then
            ./scripts/context-persistence.sh version "$context_id" "Processed by $agent"
        fi
    fi
}

# Context-aware broadcast
broadcast_with_context() {
    local from="$1"
    local type="$2"
    local data="$3"
    local context_id="$4"
    shift 4
    local recipients=("$@")
    
    # Create checkpoint before broadcast
    local checkpoint_id=$(create_checkpoint "$context_id" "Before broadcast")
    
    # Send to all recipients
    for recipient in "${recipients[@]}"; do
        send_enhanced_message "$from" "$recipient" "$type" "$data" "priority"
    done
    
    # Log broadcast event
    log_context_event "$context_id" "broadcast" "$from" \
        "{\"recipients\": $(printf '%s\n' "${recipients[@]}" | jq -R . | jq -s .)}"
}

# Context handoff between agents
handoff_context() {
    local from_agent="$1"
    local to_agent="$2"
    local context_id="$3"
    local handoff_data="${4:-{}}"
    
    # Create handoff checkpoint
    create_checkpoint "$context_id" "Handoff from $from_agent to $to_agent"
    
    # Log handoff
    log_context_event "$context_id" "handoff" "$from_agent" \
        "{\"to\": \"$to_agent\", \"data\": $handoff_data}"
    
    # Send handoff message
    send_enhanced_message "$from_agent" "$to_agent" "context_handoff" \
        "{\"context_id\": \"$context_id\", \"handoff_data\": $handoff_data}" \
        "priority"
}

# Main command handler
case "${1:-help}" in
    send)
        send_enhanced_message "$2" "$3" "$4" "$5" "${6:-normal}"
        ;;
    receive)
        receive_enhanced_message "$2"
        ;;
    process)
        process_with_context "$2" "$3" "$4"
        ;;
    broadcast)
        broadcast_with_context "$2" "$3" "$4" "$5" "${@:6}"
        ;;
    handoff)
        handoff_context "$2" "$3" "$4" "$5"
        ;;
    help|*)
        echo "Enhanced Message Queue with Context Integration"
        echo "Usage: $0 <command> [args...]"
        echo ""
        echo "Commands:"
        echo "  send <from> <to> <type> <data> [priority]"
        echo "  receive <agent>"
        echo "  process <agent> <message> <result>"
        echo "  broadcast <from> <type> <data> <context_id> <recipients...>"
        echo "  handoff <from> <to> <context_id> [data]"
        ;;
esac