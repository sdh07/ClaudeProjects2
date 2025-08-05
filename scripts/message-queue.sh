#!/bin/bash
# Simple file-based message queue operations for ClaudeProjects2

QUEUE_DIR=".claudeprojects/messages"
PENDING_DIR="$QUEUE_DIR/pending"
PROCESSING_DIR="$QUEUE_DIR/processing"
COMPLETED_DIR="$QUEUE_DIR/completed"
FAILED_DIR="$QUEUE_DIR/failed"

# Function to generate unique message ID
generate_id() {
    echo "$(date +%s%N)-$(uuidgen | tr '[:upper:]' '[:lower:]' | cut -d'-' -f1)"
}

# Function to create ISO 8601 timestamp
timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%S.%3NZ"
}

# Function to send a message
send_message() {
    local from="$1"
    local to="$2"
    local type="$3"
    local data="$4"
    local priority="${5:-normal}"
    
    local id=$(generate_id)
    local ts=$(timestamp)
    local filename="${ts}_${from}_${to}_${id}.json"
    local tempfile="$PENDING_DIR/.${filename}.tmp"
    local finalfile="$PENDING_DIR/${filename}"
    
    # Create message JSON
    cat > "$tempfile" <<EOF
{
  "id": "$id",
  "timestamp": "$ts",
  "from": "$from",
  "to": "$to",
  "type": "$type",
  "priority": "$priority",
  "data": $data,
  "status": "pending",
  "metadata": {
    "version": "1.0.0",
    "retry_count": 0
  }
}
EOF
    
    # Atomic move to final location
    mv "$tempfile" "$finalfile"
    echo "Message sent: $finalfile"
}

# Function to receive next message for an agent
receive_message() {
    local agent="$1"
    
    # Find oldest pending message for this agent
    for file in $(ls -1 "$PENDING_DIR"/*_${agent}_*.json 2>/dev/null | sort | head -1); do
        if [ -f "$file" ]; then
            local basename=$(basename "$file")
            local processing_file="$PROCESSING_DIR/$basename"
            
            # Atomic move to processing
            if mv "$file" "$processing_file" 2>/dev/null; then
                cat "$processing_file"
                echo "$processing_file"
                return 0
            fi
        fi
    done
    
    return 1
}

# Function to mark message as completed
complete_message() {
    local processing_file="$1"
    local response_data="${2:-{}}"
    
    if [ -f "$processing_file" ]; then
        local basename=$(basename "$processing_file")
        local completed_file="$COMPLETED_DIR/$basename"
        
        # Update status in message
        local temp_file="${processing_file}.tmp"
        jq --arg response "$response_data" '.status = "completed" | .response = ($response | fromjson)' "$processing_file" > "$temp_file"
        
        # Move to completed
        mv "$temp_file" "$completed_file"
        rm -f "$processing_file"
        echo "Message completed: $completed_file"
    fi
}

# Function to mark message as failed
fail_message() {
    local processing_file="$1"
    local error="$2"
    
    if [ -f "$processing_file" ]; then
        local basename=$(basename "$processing_file")
        local failed_file="$FAILED_DIR/$basename"
        
        # Update status in message
        local temp_file="${processing_file}.tmp"
        jq --arg error "$error" '.status = "failed" | .error = $error' "$processing_file" > "$temp_file"
        
        # Move to failed
        mv "$temp_file" "$failed_file"
        rm -f "$processing_file"
        echo "Message failed: $failed_file"
    fi
}

# Function to list pending messages
list_pending() {
    local agent="$1"
    
    if [ -z "$agent" ]; then
        ls -1 "$PENDING_DIR"/*.json 2>/dev/null | wc -l
    else
        ls -1 "$PENDING_DIR"/*_${agent}_*.json 2>/dev/null | wc -l
    fi
}

# Main command processing
case "$1" in
    send)
        send_message "$2" "$3" "$4" "$5" "$6"
        ;;
    receive)
        receive_message "$2"
        ;;
    complete)
        complete_message "$2" "$3"
        ;;
    fail)
        fail_message "$2" "$3"
        ;;
    list)
        list_pending "$2"
        ;;
    *)
        echo "Usage: $0 {send|receive|complete|fail|list} [args...]"
        echo ""
        echo "Commands:"
        echo "  send <from> <to> <type> <json-data> [priority]"
        echo "  receive <agent-name>"
        echo "  complete <processing-file> [response-json]"
        echo "  fail <processing-file> <error-message>"
        echo "  list [agent-name]"
        exit 1
        ;;
esac