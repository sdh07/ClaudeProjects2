#!/bin/bash

# Enhance agents with GitHub integration for CPDM
# This script adds GitHub capabilities to agents that need it

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}         Enhancing Agents with GitHub Integration for CPDM${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Vision Agent Enhancement
echo -e "\n${YELLOW}1. Vision Agent - GitHub Integration${NC}"
cat << 'EOF'
Enhancement needed:
- Auto-create GitHub issue when feature approved
- Link features to GitHub milestones
- Update issue labels based on Triple Helix score
- Commands to add:
  gh issue create --title "$feature" --body "$vision_analysis" --label "feature,vision-approved"
  gh issue edit $issue_id --add-label "roi-$score"
EOF

# Logical Architect Agent Enhancement  
echo -e "\n${YELLOW}2. Logical Architect Agent - GitHub Integration${NC}"
cat << 'EOF'
Enhancement needed:
- Update GitHub issue when design complete
- Add architecture diagrams to issue
- Commands to add:
  gh issue comment $issue_id --body "Design complete: $layer_distribution"
  gh issue edit $issue_id --add-label "design-complete"
EOF

# Physical Architect Agent Enhancement
echo -e "\n${YELLOW}3. Physical Architect Agent - GitHub Integration${NC}"
cat << 'EOF'
Enhancement needed:
- Create GitHub issue for ADR confirmation
- Create PR when ADR confirmed
- Commands to add:
  gh issue create --title "ADR-$number: $title" --label "adr,needs-confirmation"
  gh pr create --title "ADR-$number" --body "$adr_content"
EOF

# Quality Agent Enhancement
echo -e "\n${YELLOW}4. Quality Agent - GitHub Integration${NC}"
cat << 'EOF'
Enhancement needed:
- Update PR checks with gate results
- Comment on PR with quality metrics
- Block merge if gates fail
- Commands to add:
  gh pr review $pr_id --comment --body "Quality gates: $results"
  gh pr checks $pr_id --status=$gate_status
EOF

# Trace Agent Enhancement
echo -e "\n${YELLOW}5. Trace Agent - GitHub Integration${NC}"
cat << 'EOF'
Enhancement needed:
- Create feedback issues from user reports
- Link issues to features in traceability matrix
- Generate GitHub insights reports
- Commands to add:
  gh issue create --title "Feedback: $topic" --label "feedback,improvement"
  gh api graphql -f query='repository metrics query'
EOF

# Integration with issue-agent
echo -e "\n${YELLOW}6. Orchestration via Issue Agent${NC}"
cat << 'EOF'
The issue-agent will coordinate all GitHub operations:
- Receive requests from other agents via message queue
- Execute GitHub CLI commands
- Return results to requesting agents
- Maintain issue/PR state consistency
EOF

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}                    GitHub Integration Plan${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${BLUE}Implementation Strategy:${NC}"
echo "1. Each agent sends GitHub requests to issue-agent via message queue"
echo "2. Issue-agent executes all GitHub CLI commands"
echo "3. Results returned via message queue"
echo "4. This maintains separation of concerns"

echo -e "\n${BLUE}Message Queue Example:${NC}"
cat << 'EOF'
{
  "from": "vision-agent",
  "to": "issue-agent",
  "action": "create_issue",
  "data": {
    "title": "Feature: Dark Mode",
    "body": "Triple Helix: 27/30, ROI: 15x",
    "labels": ["feature", "vision-approved", "roi-high"],
    "milestone": "Sprint 6"
  }
}
EOF

echo -e "\n${BLUE}Required GitHub CLI Commands:${NC}"
echo "• gh issue create    - Create new issues"
echo "• gh issue edit      - Update issues"
echo "• gh issue comment   - Add comments"
echo "• gh pr create       - Create pull requests"
echo "• gh pr review       - Review PRs"
echo "• gh pr checks       - Update PR status checks"
echo "• gh project         - Manage GitHub Projects"

echo -e "\n${GREEN}Benefits of GitHub Integration:${NC}"
echo "✅ All features tracked as GitHub issues"
echo "✅ ADRs managed as issues and PRs"
echo "✅ Quality gates integrated with PR checks"
echo "✅ Complete audit trail in Git history"
echo "✅ Single source of truth for all decisions"
echo "✅ Developers stay in familiar workflow"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. Update agent specifications with GitHub integration"
echo "2. Add message handlers for GitHub operations"
echo "3. Configure issue-agent as GitHub coordinator"
echo "4. Test with sample feature flow"
echo "5. Document GitHub workflows in CPDM guide"

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"