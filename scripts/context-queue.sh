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
