#!/bin/bash
# Context-aware agent invocation wrapper
# Sprint 8, Day 3: Update agent invocations to use context

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
CONTEXT_DB="$PROJECT_ROOT/.cpdm/context/contexts.db"

# Source functions
source "$PROJECT_ROOT/.cpdm/context/context-functions.sh"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Context-aware agent invocation
invoke_agent_with_context() {
    local agent="$1"
    local task_type="$2"
    local task_data="$3"
    local priority="${4:-normal}"
    
    echo -e "${BLUE}Invoking $agent with context...${NC}"
    
    # Extract or create task ID
    local task_id=$(echo "$task_data" | jq -r '.task_id // "task-'$(date +%s)'"')
    
    # Check for existing context
    local context_id=$(sqlite3 "$CONTEXT_DB" \
        "SELECT id FROM contexts WHERE task_id='$task_id' AND status='active' LIMIT 1;")
    
    if [ -z "$context_id" ]; then
        # Create new context with agent capabilities
        local agent_capabilities=$(sqlite3 "$CONTEXT_DB" \
            "SELECT capabilities FROM agents WHERE name='$agent';" 2>/dev/null || echo '')
        
        if [ -z "$agent_capabilities" ]; then
            agent_capabilities='{}'
        fi
        
        local initial_state=$(jq -n \
            --arg agent "$agent" \
            --arg type "$task_type" \
            --arg started "$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")" \
            '{
                invoked_agent: $agent,
                task_type: $type,
                started_at: $started
            }')
        
        context_id=$(create_context "$task_id" "" "$initial_state")
        echo -e "${GREEN}Created context: $context_id${NC}"
    else
        echo -e "${YELLOW}Using existing context: $context_id${NC}"
    fi
    
    # Create checkpoint before invocation
    local checkpoint_id=$(create_checkpoint "$context_id" "Before $agent invocation")
    echo -e "${BLUE}Checkpoint: $checkpoint_id${NC}"
    
    # Log invocation event
    log_context_event "$context_id" "agent_invoked" "orchestrator" \
        "{\"agent\": \"$agent\", \"task_type\": \"$task_type\"}"
    
    # Enhance task data with context
    local enhanced_data=$(jq -n \
        --arg ctx "$context_id" \
        --arg task "$task_id" \
        --argjson original "$task_data" \
        '{
            context_id: $ctx,
            task_id: $task,
            data: $original
        }')
    
    # Send to agent via enhanced message queue
    ./scripts/enhanced-message-queue.sh send "orchestrator" "$agent" "$task_type" \
        "$enhanced_data" "$priority"
    
    # Return context ID for tracking
    echo "$context_id"
}

# Process agent response with context
process_agent_response() {
    local agent="$1"
    local context_id="$2"
    local response="$3"
    
    echo -e "${BLUE}Processing response from $agent...${NC}"
    
    # Update context with response
    local current_state=$(get_context_state "$context_id")
    
    # Handle empty or invalid current state
    if [ -z "$current_state" ] || ! echo "$current_state" | jq . >/dev/null 2>&1; then
        current_state='{}'
    fi
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local updated_state=$(jq -n \
        --argjson current "$current_state" \
        --argjson response "$response" \
        --arg agent "$agent" \
        --arg ts "$timestamp" \
        '$current + {
            last_response: {
                agent: $agent,
                data: $response,
                timestamp: $ts
            }
        }')
    
    update_context "$context_id" "$updated_state"
    
    # Log response event
    log_context_event "$context_id" "response_received" "$agent" \
        "{\"response_size\": $(echo "$response" | wc -c)}"
    
    # Version if significant
    ./scripts/context-persistence.sh version "$context_id" "Response from $agent"
    
    echo -e "${GREEN}Response processed and context updated${NC}"
}

# Example: Invoke code-review-agent with context
example_code_review() {
    echo -e "${YELLOW}=== Example: Code Review with Context ===${NC}\n"
    
    local task_data='{
        "pr_number": 100,
        "repository": "ClaudeProjects2",
        "focus_areas": ["context-integration", "message-passing"],
        "task_id": "review-pr-100"
    }'
    
    # Invoke agent
    local context_id=$(invoke_agent_with_context "code-review-agent" "review_pr" "$task_data" "high")
    
    echo -e "\n${BLUE}Context ID for tracking: $context_id${NC}"
    
    # Simulate receiving response
    local mock_response='{
        "status": "completed",
        "issues_found": 2,
        "suggestions": 5,
        "approval": "changes_requested"
    }'
    
    process_agent_response "code-review-agent" "$context_id" "$mock_response"
    
    # Show context state
    echo -e "\n${YELLOW}Final context state:${NC}"
    ./scripts/context-persistence.sh inspect "$context_id"
}

# Example: Multi-agent coordination with shared context
example_multi_agent() {
    echo -e "${YELLOW}=== Example: Multi-Agent with Shared Context ===${NC}\n"
    
    local task_id="multi-agent-$(date +%s)"
    local context_id=$(create_context "$task_id" "" \
        '{"workflow": "code-review-and-test", "agents": []}')
    
    echo -e "${GREEN}Created shared context: $context_id${NC}\n"
    
    # Step 1: Code review
    echo -e "${BLUE}Step 1: Invoking code-review-agent${NC}"
    ./scripts/enhanced-message-queue.sh send "orchestrator" "code-review-agent" "review_pr" \
        '{"context_id": "'$context_id'", "pr_number": 101}' "high"
    
    # Step 2: Test execution
    echo -e "\n${BLUE}Step 2: Handing off to test-agent${NC}"
    ./scripts/enhanced-message-queue.sh handoff "code-review-agent" "test-agent" \
        "$context_id" '{"review_complete": true}'
    
    # Step 3: Build verification
    echo -e "\n${BLUE}Step 3: Handing off to build-agent${NC}"
    ./scripts/enhanced-message-queue.sh handoff "test-agent" "build-agent" \
        "$context_id" '{"tests_passed": true}'
    
    echo -e "\n${GREEN}Multi-agent workflow initiated with shared context${NC}"
    
    # Show context trace
    echo -e "\n${YELLOW}Context event trace:${NC}"
    ./scripts/context-persistence.sh trace "$context_id"
}

# Main command handler
case "${1:-help}" in
    invoke)
        invoke_agent_with_context "$2" "$3" "$4" "${5:-normal}"
        ;;
    process)
        process_agent_response "$2" "$3" "$4"
        ;;
    example-review)
        example_code_review
        ;;
    example-multi)
        example_multi_agent
        ;;
    help|*)
        echo "Context-Aware Agent Invocation"
        echo "Usage: $0 <command> [args...]"
        echo ""
        echo "Commands:"
        echo "  invoke <agent> <type> <data> [priority]  - Invoke agent with context"
        echo "  process <agent> <context_id> <response>  - Process agent response"
        echo "  example-review                            - Run code review example"
        echo "  example-multi                             - Run multi-agent example"
        ;;
esac