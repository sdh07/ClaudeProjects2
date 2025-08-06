#!/bin/bash
# Test context integration with message queue
# Sprint 8, Day 3: Verification

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
cd "$PROJECT_ROOT"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Context Integration Test ===${NC}"
echo -e "${YELLOW}Testing enhanced message queue with context persistence${NC}\n"

# Test 1: Send message with auto-context creation
echo -e "${BLUE}Test 1: Auto-context creation${NC}"
./scripts/enhanced-message-queue.sh send "test-sender" "code-review-agent" "review_pr" \
    '{"pr_number": 99, "task_id": "test-review-99"}' "high"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Message sent with context${NC}"
else
    echo -e "${RED}✗ Failed to send message${NC}"
    exit 1
fi

# Test 2: Context handoff between agents
echo -e "\n${BLUE}Test 2: Context handoff${NC}"
./scripts/enhanced-message-queue.sh handoff "code-review-agent" "test-agent" \
    "ctx-test-$(date +%s)" '{"review_status": "completed"}'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Context handoff successful${NC}"
else
    echo -e "${RED}✗ Context handoff failed${NC}"
    exit 1
fi

# Test 3: Context versioning
echo -e "\n${BLUE}Test 3: Context versioning${NC}"
CONTEXT_ID="ctx-test-$(date +%s)"
./scripts/init-context-db.sh create "$CONTEXT_ID" "test-task" "" '{"test": true}'
./scripts/context-persistence.sh version "$CONTEXT_ID" "Test version"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Context versioning works${NC}"
else
    echo -e "${RED}✗ Context versioning failed${NC}"
    exit 1
fi

# Test 4: Context validation and recovery
echo -e "\n${BLUE}Test 4: Context validation${NC}"
./scripts/context-persistence.sh validate "$CONTEXT_ID"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Context validation passed${NC}"
else
    echo -e "${RED}✗ Context validation failed${NC}"
fi

# Test 5: Context inspection
echo -e "\n${BLUE}Test 5: Context inspection${NC}"
./scripts/context-persistence.sh inspect "$CONTEXT_ID"

# Test 6: Check message queue integration
echo -e "\n${BLUE}Test 6: Message queue backward compatibility${NC}"
./scripts/message-queue-v2.sh send "test" "orchestrator-agent" "test" '{"data": "test"}' "normal"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Backward compatibility maintained${NC}"
else
    echo -e "${RED}✗ Backward compatibility broken${NC}"
    exit 1
fi

# Test 7: Context trace
echo -e "\n${BLUE}Test 7: Context event trace${NC}"
./scripts/context-persistence.sh trace "$CONTEXT_ID"

echo -e "\n${GREEN}=== All Context Integration Tests Passed ===${NC}"
echo -e "${YELLOW}Context persistence layer is fully integrated with message queue${NC}"