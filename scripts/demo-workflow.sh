#!/bin/bash
# Demonstration of agent workflow for Sprint 3

echo "=== ClaudeProjects2 Agent Workflow Demo ==="
echo "Demonstrating: Create Sprint 4 Planning Structure"
echo

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Step 1: Send request to orchestrator
echo "Step 1: User request to orchestrator-agent"
echo "---------------------------------------"
echo "User: 'Create Sprint 4 planning structure'"
./scripts/message-queue.sh send "user" "orchestrator-agent" "create_sprint_planning" '{
  "sprint_number": 4,
  "goals": ["Add innovation methodologies", "Sales methodologies"],
  "duration": "10 days"
}' "high"
echo

# Step 2: Orchestrator routes to project-agent
echo "Step 2: Orchestrator routes to project-agent"
echo "------------------------------------------"
./scripts/message-queue.sh send "orchestrator-agent" "project-agent" "create_sprint" '{
  "sprint_number": 4,
  "goals": ["Add innovation methodologies", "Sales methodologies"],
  "duration": "10 days",
  "start_date": "2025-02-10"
}' "high"
echo

# Step 3: Project agent creates structure
echo "Step 3: Project-agent creates sprint structure"
echo "--------------------------------------------"
mkdir -p sprints/sprint-4/{planning,daily,review,retrospective}

# Create sprint planning file
cat > sprints/sprint-4/planning/sprint-goals.md <<EOF
# Sprint 4 Goals

**Sprint Number**: 4
**Duration**: 10 days (Feb 10-21, 2025)
**Theme**: Methodology Expansion

## Primary Goals
1. Add innovation methodologies
2. Implement sales methodologies
3. Enhance agent capabilities
4. Improve user experience

## Success Criteria
- [ ] Innovation methodology agents implemented
- [ ] Sales workflow automation ready
- [ ] Integration with existing agents
- [ ] Documentation updated
- [ ] Demo prepared

## Capacity
- Team members: 3
- Story points: 50
- Focus: New methodologies
EOF

echo "Created: sprints/sprint-4/planning/sprint-goals.md"
echo

# Step 4: Project agent requests issue creation
echo "Step 4: Project-agent requests issue creation"
echo "-------------------------------------------"
./scripts/message-queue.sh send "project-agent" "issue-agent" "create_issue" '{
  "title": "Sprint 4: Methodology Expansion",
  "template": "task",
  "body": "Implement innovation and sales methodologies",
  "labels": ["feature", "sprint-4"],
  "milestone": "Sprint 4"
}' "normal"
echo

# Step 5: Issue agent would create GitHub issue
echo "Step 5: Issue-agent creates GitHub issue"
echo "--------------------------------------"
echo "(Simulated) Created issue #40: Sprint 4: Methodology Expansion"
echo

# Step 6: Version agent commits changes
echo "Step 6: Version-agent commits planning files"
echo "-----------------------------------------"
./scripts/message-queue.sh send "project-agent" "version-agent" "git_commit" '{
  "message": "feat: Add Sprint 4 planning structure",
  "files": ["sprints/sprint-4/planning/sprint-goals.md"],
  "branch": "sprint-4/planning"
}' "normal"
echo

# Step 7: Context agent saves state
echo "Step 7: Context-agent saves project state"
echo "---------------------------------------"
./scripts/message-queue.sh send "orchestrator-agent" "context-agent" "save_context" '{
  "project": "ClaudeProjects2",
  "trigger": "sprint_planning",
  "sprint": 4
}' "normal"
echo

# Show message queue status
echo "Message Queue Status"
echo "-------------------"
echo "Pending messages:"
for agent in orchestrator-agent project-agent issue-agent version-agent context-agent; do
    count=$(./scripts/message-queue.sh list $agent)
    echo "  $agent: $count messages"
done
echo

# Show created structure
echo "Created Sprint Structure"
echo "-----------------------"
ls -la sprints/sprint-4/planning/
echo

echo "=== Workflow Demo Complete ==="
echo
echo "This demonstrates how agents work together:"
echo "1. User → Orchestrator (routing)"
echo "2. Orchestrator → Project (sprint management)"
echo "3. Project → Issue (GitHub integration)"
echo "4. Project → Version (git operations)"
echo "5. Orchestrator → Context (state persistence)"
echo
echo "In production, each agent would:"
echo "- Process messages from the queue"
echo "- Execute their specific tasks"
echo "- Send responses back through the queue"
echo "- Update CLAUDE.md with progress"