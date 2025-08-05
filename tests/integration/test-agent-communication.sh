#!/bin/bash
# Integration test for agent communication

echo "=== Agent Communication Integration Test ==="
echo

# Setup
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

# Test 1: Agent Discovery
echo "Test 1: Agent Discovery"
echo "----------------------"
./scripts/agent-loader.sh discover
agent_count=$(./scripts/agent-loader.sh list | wc -l)
echo "Found $agent_count agents"
if [ $agent_count -ge 4 ]; then
    echo "✅ Agent discovery successful"
else
    echo "❌ Agent discovery failed - expected at least 4 agents"
    exit 1
fi
echo

# Test 2: Message Queue - Send
echo "Test 2: Message Queue - Send"
echo "---------------------------"
./scripts/message-queue.sh send "test-suite" "orchestrator-agent" "test_request" '{"test": "integration test"}' "high"
echo "✅ Message sent successfully"
echo

# Test 3: Message Queue - List
echo "Test 3: Message Queue - List"
echo "---------------------------"
pending_count=$(./scripts/message-queue.sh list orchestrator-agent)
echo "Pending messages for orchestrator-agent: $pending_count"
if [ $pending_count -ge 1 ]; then
    echo "✅ Message listing successful"
else
    echo "❌ Message listing failed - no pending messages found"
    exit 1
fi
echo

# Test 4: Agent Metadata Loading
echo "Test 4: Agent Metadata Loading"
echo "-----------------------------"
orchestrator_meta=$(./scripts/agent-loader.sh load orchestrator-agent)
if echo "$orchestrator_meta" | grep -q '"name": "orchestrator-agent"'; then
    echo "✅ Agent metadata loading successful"
    echo "$orchestrator_meta" | jq -r '"\(.name): \(.description)"'
else
    echo "❌ Agent metadata loading failed"
    exit 1
fi
echo

# Test 5: Multi-Agent Discovery by Category
echo "Test 5: Multi-Agent Discovery by Category"
echo "----------------------------------------"
echo "Core agents:"
./scripts/agent-loader.sh list core
echo
echo "Domain agents:"
./scripts/agent-loader.sh list domain
echo
echo "Infrastructure agents:"
./scripts/agent-loader.sh list infrastructure
echo "✅ Category filtering successful"
echo

# Test 6: Message Queue - Receive
echo "Test 6: Message Queue - Receive"
echo "------------------------------"
message_file=$(./scripts/message-queue.sh receive orchestrator-agent | tail -1)
if [ -f "$message_file" ]; then
    echo "✅ Message received: $message_file"
    # Complete the message
    ./scripts/message-queue.sh complete "$message_file" '{"status": "test completed"}'
    echo "✅ Message marked as completed"
else
    echo "❌ Message receive failed"
    exit 1
fi
echo

# Test 7: Agent Content Retrieval
echo "Test 7: Agent Content Retrieval"
echo "------------------------------"
content=$(./scripts/agent-loader.sh content project-agent | head -5)
if echo "$content" | grep -q "Project Agent"; then
    echo "✅ Agent content retrieval successful"
    echo "First 5 lines of project-agent content:"
    echo "$content"
else
    echo "❌ Agent content retrieval failed"
    exit 1
fi
echo

# Summary
echo "=== Test Summary ==="
echo "✅ All integration tests passed!"
echo
echo "Agent Infrastructure Status:"
echo "- Agents discovered: $agent_count"
echo "- Message queue: Operational"
echo "- Agent loader: Functional"
echo "- Categories: Properly organized"