#!/bin/bash

# Agent Communication Protocol Implementation
# Central message routing and agent coordination

set -e

# Configuration
AGENTS_DIR="${AGENTS_DIR:-./agents}"
QUEUE_DIR="${QUEUE_DIR:-./.claudeprojects/messages}"
STATE_DIR="${STATE_DIR:-./.claudeprojects/state}"
LOG_DIR="${LOG_DIR:-./.claudeprojects/logs}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Initialize directories
init_protocol() {
    mkdir -p "$QUEUE_DIR"/{inbox,processing,outbox,failed}
    mkdir -p "$STATE_DIR"
    mkdir -p "$LOG_DIR"
    
    # Create protocol state file
    cat > "$STATE_DIR/protocol.json" <<EOF
{
    "version": "1.0.0",
    "status": "active",
    "initialized": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "agents": {},
    "metrics": {
        "messages_processed": 0,
        "messages_failed": 0,
        "avg_response_time": 0
    }
}
EOF
    echo -e "${GREEN}✓${NC} Protocol initialized"
}

# Send message between agents
send_message() {
    local from_agent="$1"
    local to_agent="$2"
    local message_type="$3"
    local action="$4"
    local data="$5"
    
    local msg_id="msg-$(uuidgen 2>/dev/null || echo "$(date +%s)-$$")"
    local timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    
    # Create message
    cat > "$QUEUE_DIR/inbox/$msg_id.json" <<EOF
{
    "id": "$msg_id",
    "type": "$message_type",
    "from": "$from_agent",
    "to": "$to_agent",
    "timestamp": "$timestamp",
    "priority": "normal",
    "data": {
        "action": "$action",
        "parameters": $data
    },
    "metadata": {
        "timeout": 30000,
        "retry_count": 0
    }
}
EOF
    
    echo -e "${BLUE}→${NC} Message $msg_id: ${CYAN}$from_agent${NC} → ${CYAN}$to_agent${NC} [$action]"
    
    # Log message
    echo "$(date '+%Y-%m-%d %H:%M:%S') | SEND | $from_agent → $to_agent | $action" >> "$LOG_DIR/protocol.log"
}

# Process message queue
process_queue() {
    local processed=0
    
    for msg_file in "$QUEUE_DIR/inbox"/*.json; do
        [ -f "$msg_file" ] || continue
        
        local msg_id=$(basename "$msg_file" .json)
        local to_agent=$(jq -r '.to' "$msg_file")
        local action=$(jq -r '.data.action' "$msg_file")
        
        echo -e "${YELLOW}⚡${NC} Processing: $msg_id for ${CYAN}$to_agent${NC}"
        
        # Move to processing
        mv "$msg_file" "$QUEUE_DIR/processing/"
        
        # Simulate agent processing
        sleep 0.5
        
        # Move to outbox (success)
        mv "$QUEUE_DIR/processing/$msg_id.json" "$QUEUE_DIR/outbox/"
        
        ((processed++))
        
        echo -e "${GREEN}✓${NC} Processed: $msg_id"
    done
    
    if [ $processed -gt 0 ]; then
        echo -e "${GREEN}✓${NC} Processed $processed messages"
    fi
}

# Monitor agent health
monitor_agents() {
    echo -e "${BLUE}📊 Agent Health Monitor${NC}"
    echo "========================"
    
    # Check each agent directory
    for agent_type in core domain infrastructure delivery; do
        [ -d "$AGENTS_DIR/$agent_type" ] || continue
        
        echo -e "\n${CYAN}$agent_type agents:${NC}"
        for agent_file in "$AGENTS_DIR/$agent_type"/*.md; do
            [ -f "$agent_file" ] || continue
            
            local agent_name=$(grep '^name:' "$agent_file" | cut -d: -f2 | tr -d ' ')
            local status=$(grep '^status:' "$agent_file" | cut -d: -f2 | tr -d ' ')
            
            if [ "$status" = "active" ]; then
                echo -e "  ${GREEN}●${NC} $agent_name: Active"
            else
                echo -e "  ${YELLOW}●${NC} $agent_name: $status"
            fi
        done
    done
    
    # Queue statistics
    echo -e "\n${CYAN}Queue Statistics:${NC}"
    echo "  Inbox: $(ls -1 "$QUEUE_DIR/inbox" 2>/dev/null | wc -l) messages"
    echo "  Processing: $(ls -1 "$QUEUE_DIR/processing" 2>/dev/null | wc -l) messages"
    echo "  Outbox: $(ls -1 "$QUEUE_DIR/outbox" 2>/dev/null | wc -l) messages"
    echo "  Failed: $(ls -1 "$QUEUE_DIR/failed" 2>/dev/null | wc -l) messages"
}

# Demonstrate agent collaboration
demo_collaboration() {
    echo -e "${BLUE}🎭 Agent Collaboration Demo${NC}"
    echo "============================"
    
    # User request
    echo -e "\n${YELLOW}[USER]${NC} Add authentication to the Notes app"
    sleep 1
    
    # Orchestrator routes to project agent
    send_message "orchestrator" "project-agent" "request" "analyze_feature" '{"feature": "authentication"}'
    sleep 1
    
    # Project agent to architecture designer
    send_message "project-agent" "architecture-designer" "request" "design_auth" '{"type": "JWT", "provider": "NextAuth"}'
    sleep 1
    
    # Architecture designer to code generator
    send_message "architecture-designer" "code-generator" "request" "implement_auth" '{"design": "jwt-nextauth"}'
    sleep 1
    
    # Code generator to review agent
    send_message "code-generator" "code-review" "request" "review_code" '{"files": ["auth.ts", "middleware.ts"]}'
    sleep 1
    
    # Review agent to test agent
    send_message "code-review" "test-agent" "request" "run_tests" '{"suite": "auth"}'
    sleep 1
    
    # Test agent to build agent
    send_message "test-agent" "build-agent" "request" "build_app" '{"profile": "production"}'
    sleep 1
    
    # Build agent to version agent
    send_message "build-agent" "version-agent" "request" "tag_release" '{"version": "1.1.0"}'
    sleep 1
    
    echo -e "\n${GREEN}✓${NC} Feature development complete!"
    
    # Process all messages
    echo -e "\n${BLUE}Processing message queue...${NC}"
    process_queue
}

# Show usage
usage() {
    echo "Agent Communication Protocol"
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  init       Initialize protocol system"
    echo "  send       Send message between agents"
    echo "  process    Process message queue"
    echo "  monitor    Monitor agent health"
    echo "  demo       Run collaboration demo"
    echo "  help       Show this help"
}

# Main command handler
case "${1:-help}" in
    init)
        init_protocol
        ;;
    send)
        shift
        send_message "$@"
        ;;
    process)
        process_queue
        ;;
    monitor)
        monitor_agents
        ;;
    demo)
        demo_collaboration
        ;;
    help|*)
        usage
        ;;
esac