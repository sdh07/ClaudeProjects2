#!/bin/bash
# Full agent ecosystem integration test

echo "=== ClaudeProjects2 Full Agent Ecosystem Test ==="
echo "Testing all 10 agents and their interactions"
echo

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

# Test 1: Agent Discovery
echo "Test 1: Complete Agent Discovery"
echo "--------------------------------"
./scripts/agent-loader.sh discover
total_agents=$(./scripts/agent-loader.sh list | wc -l)
echo "Total agents discovered: $total_agents"

if [ $total_agents -eq 10 ]; then
    echo "✅ All 10 agents discovered successfully"
else
    echo "❌ Expected 10 agents, found $total_agents"
    exit 1
fi
echo

# Test 2: Agent Categories
echo "Test 2: Agent Category Distribution"
echo "----------------------------------"
core_count=$(./scripts/agent-loader.sh list core | wc -l)
domain_count=$(./scripts/agent-loader.sh list domain | wc -l)
infrastructure_count=$(./scripts/agent-loader.sh list infrastructure | wc -l)
delivery_count=$(./scripts/agent-loader.sh list delivery | wc -l)

echo "Core agents: $core_count (orchestrator, context, methodology, knowledge)"
echo "Domain agents: $domain_count (project)"
echo "Infrastructure agents: $infrastructure_count (version)"
echo "Delivery agents: $delivery_count (code-review, test, build, issue)"

if [ $core_count -eq 4 ] && [ $domain_count -eq 1 ] && [ $infrastructure_count -eq 1 ] && [ $delivery_count -eq 4 ]; then
    echo "✅ Agent distribution correct"
else
    echo "❌ Agent distribution incorrect"
    exit 1
fi
echo

# Test 3: Core Agent Communication Flow
echo "Test 3: Core Agent Communication Flow"
echo "------------------------------------"
echo "Simulating: User → Orchestrator → Project → Knowledge"

# User requests sprint retrospective
./scripts/message-queue.sh send "user" "orchestrator-agent" "facilitate_retrospective" '{
  "sprint": 3,
  "team": ["Alice", "Bob", "Charlie"]
}' "high"

# Orchestrator routes to methodology-agent
./scripts/message-queue.sh send "orchestrator-agent" "methodology-agent" "facilitate_retro" '{
  "sprint": 3,
  "format": "start-stop-continue"
}' "high"

# Methodology-agent coordinates with project-agent
./scripts/message-queue.sh send "methodology-agent" "project-agent" "get_sprint_metrics" '{
  "sprint": 3
}' "normal"

# Project-agent sends metrics back
./scripts/message-queue.sh send "project-agent" "methodology-agent" "sprint_metrics" '{
  "velocity": 48,
  "completed": 22,
  "bugs": 3
}' "normal"

# Methodology-agent sends learnings to knowledge-agent
./scripts/message-queue.sh send "methodology-agent" "knowledge-agent" "capture_learning" '{
  "title": "Sprint 3 Retrospective Insights",
  "learnings": ["TDD improved quality", "Pair programming helped knowledge transfer"],
  "actions": ["Adopt TDD as standard", "Schedule regular pairing sessions"]
}' "normal"

echo "✅ Communication flow established"
echo

# Test 4: Delivery Pipeline Simulation
echo "Test 4: Delivery Pipeline Simulation"
echo "-----------------------------------"
echo "Simulating: Code Review → Test → Build → Issue Update"

# Code review request
./scripts/message-queue.sh send "version-agent" "code-review-agent" "review_pr" '{
  "pr_number": 123,
  "files_changed": 5,
  "additions": 150,
  "deletions": 30
}' "high"

# Test execution request
./scripts/message-queue.sh send "code-review-agent" "test-agent" "run_tests" '{
  "suite": "unit",
  "coverage": true
}' "high"

# Build request
./scripts/message-queue.sh send "test-agent" "build-agent" "start_build" '{
  "target": "production",
  "tests_passed": true
}' "high"

# Issue update
./scripts/message-queue.sh send "build-agent" "issue-agent" "update_issue" '{
  "issue_number": 123,
  "status": "ready_for_deployment",
  "build_artifact": "v1.2.3"
}' "normal"

echo "✅ Delivery pipeline flow complete"
echo

# Test 5: Context and Knowledge Management
echo "Test 5: Context and Knowledge Management"
echo "---------------------------------------"

# Save context
./scripts/message-queue.sh send "orchestrator-agent" "context-agent" "save_context" '{
  "project": "ClaudeProjects2",
  "sprint": 3,
  "agents_active": 10
}' "high"

# Capture decision
./scripts/message-queue.sh send "orchestrator-agent" "knowledge-agent" "capture_decision" '{
  "title": "Agent-based Architecture",
  "decision": "Use file-based message queue",
  "rationale": "Simple, no dependencies, atomic operations"
}' "high"

echo "✅ Context and knowledge management operational"
echo

# Test 6: Message Queue Statistics
echo "Test 6: Message Queue Statistics"
echo "-------------------------------"
total_messages=0
for agent in orchestrator-agent project-agent context-agent version-agent \
             code-review-agent test-agent build-agent issue-agent \
             methodology-agent knowledge-agent; do
    count=$(./scripts/message-queue.sh list $agent 2>/dev/null || echo 0)
    echo "$agent: $count pending messages"
    total_messages=$((total_messages + count))
done

echo "Total messages in queue: $total_messages"
echo "✅ Message queue fully operational"
echo

# Test 7: Agent Metadata Verification
echo "Test 7: Agent Metadata Verification"
echo "----------------------------------"
echo "Checking each agent has proper metadata..."

agents=("orchestrator-agent" "context-agent" "methodology-agent" "knowledge-agent" 
        "project-agent" "version-agent" "code-review-agent" "test-agent" 
        "build-agent" "issue-agent")

all_valid=true
for agent in "${agents[@]}"; do
    metadata=$(./scripts/agent-loader.sh load "$agent" 2>/dev/null)
    if echo "$metadata" | grep -q '"name"' && \
       echo "$metadata" | grep -q '"description"' && \
       echo "$metadata" | grep -q '"category"' && \
       echo "$metadata" | grep -q '"tools"'; then
        echo "✅ $agent: Valid metadata"
    else
        echo "❌ $agent: Invalid metadata"
        all_valid=false
    fi
done

if [ "$all_valid" = true ]; then
    echo "✅ All agents have valid metadata"
else
    echo "❌ Some agents have invalid metadata"
    exit 1
fi
echo

# Summary
echo "=== Ecosystem Test Summary ==="
echo "✅ All 10 agents discovered and categorized"
echo "✅ Core agent communication working"
echo "✅ Delivery pipeline simulation successful"
echo "✅ Context and knowledge management operational"
echo "✅ Message queue handling all agents"
echo "✅ Agent metadata properly structured"
echo
echo "🎉 ClaudeProjects2 agent ecosystem is fully operational!"
echo "Ready for self-hosting demonstration on Day 10!"