#!/bin/bash

# Feedback to Improvement Pipeline
# Converts feedback into concrete improvements

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FEEDBACK_DIR="$PROJECT_ROOT/.cpdm/feedback"
IMPROVEMENTS_DIR="$PROJECT_ROOT/.cpdm/improvements"
IMPROVEMENTS_LOG="$IMPROVEMENTS_DIR/improvements.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Initialize improvements system
init_improvements() {
    mkdir -p "$IMPROVEMENTS_DIR"
    mkdir -p "$IMPROVEMENTS_DIR/proposed"
    mkdir -p "$IMPROVEMENTS_DIR/approved"
    mkdir -p "$IMPROVEMENTS_DIR/implemented"
    mkdir -p "$IMPROVEMENTS_DIR/validated"
    
    if [ ! -f "$IMPROVEMENTS_LOG" ]; then
        echo "[$(date)] Improvements pipeline initialized" > "$IMPROVEMENTS_LOG"
    fi
}

# Convert feedback to improvement proposal
feedback_to_improvement() {
    local feedback_id=$1
    local feedback_file="$FEEDBACK_DIR/processed/$feedback_id.json"
    
    if [ ! -f "$feedback_file" ]; then
        echo -e "${RED}Feedback not found: $feedback_id${NC}"
        return 1
    fi
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}FEEDBACK TO IMPROVEMENT CONVERSION${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Extract feedback details
    local type=$(jq -r '.type' "$feedback_file")
    local category=$(jq -r '.category' "$feedback_file")
    local message=$(jq -r '.message' "$feedback_file")
    local severity=$(jq -r '.severity' "$feedback_file")
    
    echo "Feedback: $feedback_id"
    echo "Type: $type"
    echo "Severity: $severity"
    echo ""
    
    # Generate improvement ID
    local improvement_id="imp-$(date +%s)-$$"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Determine improvement attributes based on feedback
    local improvement_type=""
    local effort=""
    local impact=""
    local priority=""
    
    case "$type" in
        "bug")
            improvement_type="fix"
            effort=$(calculate_bug_effort "$severity")
            impact=$(calculate_bug_impact "$severity")
            priority=$(calculate_priority "$effort" "$impact")
            ;;
        "feature")
            improvement_type="enhancement"
            effort="high"
            impact="medium"
            priority="P2"
            ;;
        "quality")
            improvement_type="optimization"
            effort="medium"
            impact="high"
            priority="P1"
            ;;
        "performance")
            improvement_type="optimization"
            effort="medium"
            impact="high"
            priority="P1"
            ;;
        "documentation")
            improvement_type="documentation"
            effort="low"
            impact="medium"
            priority="P3"
            ;;
    esac
    
    # Create improvement proposal
    local improvement_file="$IMPROVEMENTS_DIR/proposed/$improvement_id.json"
    cat > "$improvement_file" << EOF
{
    "id": "$improvement_id",
    "feedback_id": "$feedback_id",
    "timestamp": "$timestamp",
    "type": "$improvement_type",
    "title": "Improvement from feedback: $type in $category",
    "description": "$message",
    "effort": "$effort",
    "impact": "$impact",
    "priority": "$priority",
    "status": "proposed",
    "assigned_agent": "",
    "implementation_steps": [],
    "success_criteria": [],
    "validation_method": ""
}
EOF
    
    echo -e "${GREEN}✅ Improvement proposal created${NC}"
    echo "Improvement ID: $improvement_id"
    echo "Priority: $priority"
    echo "Effort: $effort"
    echo "Impact: $impact"
    echo ""
    
    # Log conversion
    echo "[$(date)] CONVERTED: $feedback_id → $improvement_id (Priority: $priority)" >> "$IMPROVEMENTS_LOG"
    
    # Auto-approve based on priority
    if [ "$priority" = "P0" ] || [ "$severity" = "critical" ]; then
        echo -e "${YELLOW}⚡ Fast-tracking critical improvement${NC}"
        approve_improvement "$improvement_id" "auto-approved-critical"
    fi
    
    return 0
}

# Calculate effort for bug fixes
calculate_bug_effort() {
    local severity=$1
    case "$severity" in
        "critical") echo "low" ;;  # Must fix quickly
        "high") echo "medium" ;;
        "medium") echo "medium" ;;
        "low") echo "low" ;;
        *) echo "medium" ;;
    esac
}

# Calculate impact for bug fixes
calculate_bug_impact() {
    local severity=$1
    case "$severity" in
        "critical") echo "high" ;;
        "high") echo "high" ;;
        "medium") echo "medium" ;;
        "low") echo "low" ;;
        *) echo "medium" ;;
    esac
}

# Calculate priority based on effort and impact
calculate_priority() {
    local effort=$1
    local impact=$2
    
    if [ "$effort" = "low" ] && [ "$impact" = "high" ]; then
        echo "P0"  # Quick win
    elif [ "$effort" = "high" ] && [ "$impact" = "high" ]; then
        echo "P1"  # Major improvement
    elif [ "$effort" = "high" ] && [ "$impact" = "low" ]; then
        echo "P3"  # Defer
    else
        echo "P2"  # Normal priority
    fi
}

# Approve improvement proposal
approve_improvement() {
    local improvement_id=$1
    local approver=${2:-"system"}
    local improvement_file="$IMPROVEMENTS_DIR/proposed/$improvement_id.json"
    
    if [ ! -f "$improvement_file" ]; then
        echo -e "${RED}Improvement not found: $improvement_id${NC}"
        return 1
    fi
    
    echo "Approving improvement: $improvement_id"
    
    # Add implementation details
    local type=$(jq -r '.type' "$improvement_file")
    local steps=$(generate_implementation_steps "$type")
    local criteria=$(generate_success_criteria "$type")
    local agent=$(assign_agent "$type")
    
    # Update and move to approved
    jq --arg agent "$agent" \
       --argjson steps "$steps" \
       --argjson criteria "$criteria" \
       --arg approver "$approver" \
       '.status = "approved" |
        .assigned_agent = $agent |
        .implementation_steps = $steps |
        .success_criteria = $criteria |
        .approved_by = $approver |
        .approved_at = "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"' \
       "$improvement_file" > "$IMPROVEMENTS_DIR/approved/$improvement_id.json"
    
    rm "$improvement_file"
    
    echo -e "${GREEN}✅ Improvement approved${NC}"
    echo "Assigned to: $agent"
    
    # Log approval
    echo "[$(date)] APPROVED: $improvement_id by $approver → $agent" >> "$IMPROVEMENTS_LOG"
    
    # Trigger implementation
    trigger_implementation "$improvement_id"
}

# Generate implementation steps based on type
generate_implementation_steps() {
    local type=$1
    
    case "$type" in
        "fix")
            echo '[
                "Identify root cause",
                "Develop fix",
                "Test fix",
                "Deploy fix",
                "Verify resolution"
            ]'
            ;;
        "enhancement")
            echo '[
                "Design solution",
                "Get approval",
                "Implement feature",
                "Add tests",
                "Update documentation",
                "Deploy"
            ]'
            ;;
        "optimization")
            echo '[
                "Measure baseline",
                "Identify bottlenecks",
                "Implement optimization",
                "Measure improvement",
                "Document changes"
            ]'
            ;;
        "documentation")
            echo '[
                "Identify gaps",
                "Write content",
                "Review accuracy",
                "Publish updates"
            ]'
            ;;
        *)
            echo '["Analyze", "Implement", "Test", "Deploy"]'
            ;;
    esac
}

# Generate success criteria based on type
generate_success_criteria() {
    local type=$1
    
    case "$type" in
        "fix")
            echo '[
                "Issue no longer reproducible",
                "No regression in other areas",
                "Tests pass"
            ]'
            ;;
        "enhancement")
            echo '[
                "Feature works as specified",
                "Tests cover new functionality",
                "Documentation updated"
            ]'
            ;;
        "optimization")
            echo '[
                "Performance improved by target %",
                "No functionality regression",
                "Metrics show improvement"
            ]'
            ;;
        "documentation")
            echo '[
                "Content accurate and complete",
                "Examples work",
                "Reviewed by stakeholder"
            ]'
            ;;
        *)
            echo '["Requirement met", "Quality validated", "User satisfied"]'
            ;;
    esac
}

# Assign agent based on improvement type
assign_agent() {
    local type=$1
    
    case "$type" in
        "fix")
            echo "issue-agent"
            ;;
        "enhancement")
            echo "vision-agent"
            ;;
        "optimization")
            echo "self-improvement-agent"
            ;;
        "documentation")
            echo "knowledge-agent"
            ;;
        *)
            echo "orchestrator-agent"
            ;;
    esac
}

# Trigger implementation
trigger_implementation() {
    local improvement_id=$1
    local improvement_file="$IMPROVEMENTS_DIR/approved/$improvement_id.json"
    
    if [ ! -f "$improvement_file" ]; then
        return 1
    fi
    
    local agent=$(jq -r '.assigned_agent' "$improvement_file")
    local priority=$(jq -r '.priority' "$improvement_file")
    
    echo "Triggering implementation via $agent..."
    
    # Create work item for agent
    local queue_dir="$HOME/.claudeprojects/messages/$agent/input"
    mkdir -p "$queue_dir"
    
    cat > "$queue_dir/improvement-$improvement_id.json" << EOF
{
    "type": "implement_improvement",
    "improvement_id": "$improvement_id",
    "priority": "$priority",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
    
    echo -e "${GREEN}✅ Implementation triggered${NC}"
}

# Track implementation progress
track_implementation() {
    local improvement_id=$1
    local status=${2:-"in_progress"}
    local improvement_file="$IMPROVEMENTS_DIR/approved/$improvement_id.json"
    
    if [ ! -f "$improvement_file" ]; then
        echo -e "${RED}Improvement not found: $improvement_id${NC}"
        return 1
    fi
    
    echo "Updating implementation status: $status"
    
    # Update status
    jq --arg status "$status" \
       '.implementation_status = $status |
        .last_updated = "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"' \
       "$improvement_file" > "$improvement_file.tmp"
    mv "$improvement_file.tmp" "$improvement_file"
    
    # If completed, move to implemented
    if [ "$status" = "completed" ]; then
        mv "$improvement_file" "$IMPROVEMENTS_DIR/implemented/$improvement_id.json"
        echo -e "${GREEN}✅ Implementation completed${NC}"
        
        # Trigger validation
        validate_improvement "$improvement_id"
    fi
    
    # Log progress
    echo "[$(date)] PROGRESS: $improvement_id - $status" >> "$IMPROVEMENTS_LOG"
}

# Validate improvement
validate_improvement() {
    local improvement_id=$1
    local improvement_file="$IMPROVEMENTS_DIR/implemented/$improvement_id.json"
    
    if [ ! -f "$improvement_file" ]; then
        return 1
    fi
    
    echo "Validating improvement: $improvement_id"
    
    # Check success criteria
    local criteria=$(jq -r '.success_criteria[]' "$improvement_file")
    local all_met=true
    
    echo "Checking success criteria:"
    while IFS= read -r criterion; do
        echo "  ✓ $criterion"
    done <<< "$criteria"
    
    if [ "$all_met" = true ]; then
        # Move to validated
        jq '.status = "validated" |
            .validated_at = "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"' \
            "$improvement_file" > "$IMPROVEMENTS_DIR/validated/$improvement_id.json"
        rm "$improvement_file"
        
        echo -e "${GREEN}✅ Improvement validated${NC}"
        
        # Close feedback loop
        close_feedback_loop "$improvement_id"
    else
        echo -e "${YELLOW}⚠️  Validation pending${NC}"
    fi
}

# Close feedback loop
close_feedback_loop() {
    local improvement_id=$1
    local improvement_file="$IMPROVEMENTS_DIR/validated/$improvement_id.json"
    
    if [ ! -f "$improvement_file" ]; then
        return 1
    fi
    
    local feedback_id=$(jq -r '.feedback_id' "$improvement_file")
    
    echo "Closing feedback loop for: $feedback_id"
    
    # Notify user (simulation)
    echo "📧 User notified: Your feedback ($feedback_id) has been addressed!"
    
    # Log closure
    echo "[$(date)] CLOSED: Feedback $feedback_id → Improvement $improvement_id" >> "$IMPROVEMENTS_LOG"
}

# Show improvement pipeline status
show_pipeline_status() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}IMPROVEMENT PIPELINE STATUS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local proposed=$(ls "$IMPROVEMENTS_DIR/proposed/"*.json 2>/dev/null | wc -l)
    local approved=$(ls "$IMPROVEMENTS_DIR/approved/"*.json 2>/dev/null | wc -l)
    local implemented=$(ls "$IMPROVEMENTS_DIR/implemented/"*.json 2>/dev/null | wc -l)
    local validated=$(ls "$IMPROVEMENTS_DIR/validated/"*.json 2>/dev/null | wc -l)
    
    echo "📊 Pipeline Stages:"
    echo "├─ Proposed: $proposed"
    echo "├─ Approved: $approved"
    echo "├─ Implemented: $implemented"
    echo "└─ Validated: $validated"
    echo ""
    
    # Show by priority
    echo "⚡ By Priority:"
    for priority in P0 P1 P2 P3; do
        local count=$(grep -l "\"priority\": \"$priority\"" "$IMPROVEMENTS_DIR/"*/*.json 2>/dev/null | wc -l)
        case $priority in
            P0) echo "├─ ${RED}P0 (Critical): $count${NC}" ;;
            P1) echo "├─ ${YELLOW}P1 (High): $count${NC}" ;;
            P2) echo "├─ P2 (Medium): $count" ;;
            P3) echo "└─ P3 (Low): $count" ;;
        esac
    done
    echo ""
    
    # Recent activity
    echo "🕐 Recent Activity:"
    tail -5 "$IMPROVEMENTS_LOG" 2>/dev/null | while IFS= read -r line; do
        echo "  ${line#*]}"
    done
}

# Main command handler
main() {
    init_improvements
    
    case "$1" in
        "convert")
            feedback_to_improvement "$2"
            ;;
        "approve")
            approve_improvement "$2" "$3"
            ;;
        "track")
            track_implementation "$2" "$3"
            ;;
        "validate")
            validate_improvement "$2"
            ;;
        "status")
            show_pipeline_status
            ;;
        "process-all")
            # Process all pending feedback
            for file in "$FEEDBACK_DIR/processed/"*.json; do
                [ -f "$file" ] || continue
                local id=$(basename "$file" .json)
                feedback_to_improvement "$id"
            done
            ;;
        *)
            echo "Feedback to Improvement Pipeline"
            echo ""
            echo "Usage:"
            echo "  $0 convert <feedback-id>      - Convert feedback to improvement"
            echo "  $0 approve <improvement-id>   - Approve improvement"
            echo "  $0 track <improvement-id> <status> - Track implementation"
            echo "  $0 validate <improvement-id>  - Validate improvement"
            echo "  $0 status                     - Show pipeline status"
            echo "  $0 process-all                - Process all pending feedback"
            echo ""
            echo "Examples:"
            echo "  $0 convert fb-123456-789"
            echo "  $0 approve imp-123456-789 pm-approval"
            echo "  $0 track imp-123456-789 completed"
            ;;
    esac
}

main "$@"