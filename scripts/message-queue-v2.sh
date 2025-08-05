#!/bin/bash
# Message queue v2 - Follows architecture specification

QUEUE_DIR=".claudeprojects/messages"

# Function to send a message with priority routing
send_message() {
    local from="$1"
    local to="$2"
    local type="$3"
    local data="$4"
    local priority="${5:-normal}"
    
    local id="$(date +%s%N)-$(uuidgen | tr '[:upper:]' '[:lower:]' | cut -d'-' -f1)"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local filename="${timestamp}_${id}.json"
    local queue_path="$QUEUE_DIR/queues/$to/$priority"
    local temp_file="$queue_path/.tmp-$filename"
    local final_file="$queue_path/$filename"
    
    # Create message
    cat > "$temp_file" <<JSON
{
  "header": {
    "id": "$id",
    "timestamp": "$timestamp",
    "from": "$from",
    "to": "$to",
    "priority": "$priority",
    "ttl": 300000
  },
  "body": {
    "type": "$type",
    "action": "process",
    "payload": $data
  }
}
JSON
    
    # Atomic move
    mv "$temp_file" "$final_file"
    echo "Message sent to $to ($priority): $final_file"
}

# Process messages with priority order
receive_message() {
    local agent="$1"
    
    # Check priority queues in order
    for priority in priority normal low; do
        local queue_path="$QUEUE_DIR/queues/$agent/$priority"
        
        # Get oldest message
        for file in $(ls -1 "$queue_path"/*.json 2>/dev/null | sort | head -1); do
            if [ -f "$file" ]; then
                local basename=$(basename "$file")
                local lock_file="$QUEUE_DIR/processing/$agent/$basename.lock"
                
                # Try to acquire lock
                if mkdir -p "$(dirname "$lock_file")" && \
                   echo $$ > "$lock_file" 2>/dev/null; then
                    # Move to processing
                    local processing_file="$QUEUE_DIR/processing/$agent/$basename"
                    if mv "$file" "$processing_file" 2>/dev/null; then
                        cat "$processing_file"
                        echo "$processing_file"
                        return 0
                    fi
                    rm -f "$lock_file"
                fi
            fi
        done
    done
    
    return 1
}

# Archive completed message
complete_message() {
    local processing_file="$1"
    if [ -f "$processing_file" ]; then
        local basename=$(basename "$processing_file")
        local archive_file="$QUEUE_DIR/archive/$basename"
        mv "$processing_file" "$archive_file"
        rm -f "${processing_file}.lock"
        echo "Message archived: $archive_file"
    fi
}

# Main
case "$1" in
    send)
        send_message "$2" "$3" "$4" "$5" "$6"
        ;;
    receive)
        receive_message "$2"
        ;;
    complete)
        complete_message "$2"
        ;;
    *)
        echo "Usage: $0 {send|receive|complete} [args...]"
        exit 1
        ;;
esac
