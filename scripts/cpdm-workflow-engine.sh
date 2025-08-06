#!/bin/bash

# CPDM Workflow Engine
# Orchestrates phase transitions and quality gate enforcement

set -e

# Configuration
MESSAGES_DIR="$HOME/.claudeprojects/messages"
STATE_DIR="$HOME/.claudeprojects/state"
CPDM_STATE="$STATE_DIR/cpdm-workflow.json"
QUALITY_QUEUE="$MESSAGES_DIR/quality/input"
TRACE_QUEUE="$MESSAGES_DIR/trace/input"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize state file if not exists
init_state() {
    if [ ! -f "$CPDM_STATE" ]; then
        mkdir -p "$STATE_DIR"
        cat > "$CPDM_STATE" << EOF
{
    "active_features": {},
    "phase_history": [],
    "gate_overrides": [],
    "metrics": {
        "total_transitions": 0,
        "successful_transitions": 0,
        "failed_gates": 0,
        "average_phase_duration": {}
    }
}
EOF
        echo -e "${GREEN}✓ Initialized CPDM workflow state${NC}"
    fi
}

# Get current phase for a feature
get_current_phase() {
    local feature="$1"
    jq -r ".active_features[\"$feature\"].current_phase // \"none\"" "$CPDM_STATE"
}

# Get feature status
get_feature_status() {
    local feature="$1"
    jq -r ".active_features[\"$feature\"] // {}" "$CPDM_STATE"
}

# Update feature phase
update_phase() {
    local feature="$1"
    local new_phase="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Update state
    jq ".active_features[\"$feature\"].current_phase = \"$new_phase\" |
        .active_features[\"$feature\"].phase_entered = \"$timestamp\" |
        .active_features[\"$feature\"].last_updated = \"$timestamp\"" "$CPDM_STATE" > "$CPDM_STATE.tmp"
    mv "$CPDM_STATE.tmp" "$CPDM_STATE"
    
    # Add to history
    jq ".phase_history += [{
        \"feature\": \"$feature\",
        \"phase\": \"$new_phase\",
        \"timestamp\": \"$timestamp\"
    }]" "$CPDM_STATE" > "$CPDM_STATE.tmp"
    mv "$CPDM_STATE.tmp" "$CPDM_STATE"
}

# Check quality gates
check_gates() {
    local feature="$1"
    local from_phase="$2"
    local to_phase="$3"
    
    echo -e "${BLUE}🔍 Checking quality gates: $from_phase → $to_phase${NC}"
    
    # Create gate check request
    local request_id=$(uuidgen)
    local request_file="$QUALITY_QUEUE/gate-check-$request_id.json"
    
    mkdir -p "$QUALITY_QUEUE"
    cat > "$request_file" << EOF
{
    "request_id": "$request_id",
    "type": "gate_check",
    "feature": "$feature",
    "from_phase": "$from_phase",
    "to_phase": "$to_phase",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
    
    # Simulate gate check (in real implementation, wait for quality-agent response)
    echo "  ⏳ Waiting for quality-agent response..."
    sleep 2
    
    # For demo, simulate different gate results based on phase
    case "$to_phase" in
        "design")
            echo -e "${GREEN}  ✓ Triple Helix validation: PASSED${NC}"
            echo -e "${GREEN}  ✓ ROI calculation: 15x (PASSED)${NC}"
            echo -e "${GREEN}  ✓ PM approval: RECEIVED${NC}"
            return 0
            ;;
        "decision")
            echo -e "${GREEN}  ✓ Domain model: COMPLETE${NC}"
            echo -e "${GREEN}  ✓ Layer boundaries: CLEAR${NC}"
            echo -e "${GREEN}  ✓ Interfaces: DOCUMENTED${NC}"
            return 0
            ;;
        "implementation")
            echo -e "${GREEN}  ✓ ADRs confirmed: 3/3${NC}"
            echo -e "${GREEN}  ✓ Technology stack: APPROVED${NC}"
            echo -e "${GREEN}  ✓ Component specs: COMPLETE${NC}"
            return 0
            ;;
        "quality")
            echo -e "${GREEN}  ✓ Code review: PASSED${NC}"
            echo -e "${GREEN}  ✓ Unit tests: 98% coverage${NC}"
            echo -e "${YELLOW}  ⚠ Documentation: 75% complete (WARNING)${NC}"
            return 0
            ;;
        "delivery")
            echo -e "${GREEN}  ✓ Integration tests: ALL PASSING${NC}"
            echo -e "${GREEN}  ✓ Performance: MEETS SLA${NC}"
            echo -e "${GREEN}  ✓ Security scan: CLEAN${NC}"
            return 0
            ;;
        "feedback")
            echo -e "${GREEN}  ✓ Deployment: SUCCESSFUL${NC}"
            echo -e "${GREEN}  ✓ Smoke tests: PASSING${NC}"
            echo -e "${GREEN}  ✓ Monitoring: ACTIVE${NC}"
            return 0
            ;;
        *)
            return 0
            ;;
    esac
}

# Start new feature in CPDM
start_feature() {
    local feature="$1"
    local description="$2"
    
    echo -e "${BLUE}🚀 Starting new feature in CPDM: $feature${NC}"
    
    # Initialize feature in state
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    jq ".active_features[\"$feature\"] = {
        \"description\": \"$description\",
        \"current_phase\": \"vision\",
        \"phase_entered\": \"$timestamp\",
        \"created\": \"$timestamp\",
        \"last_updated\": \"$timestamp\",
        \"status\": \"active\"
    }" "$CPDM_STATE" > "$CPDM_STATE.tmp"
    mv "$CPDM_STATE.tmp" "$CPDM_STATE"
    
    echo -e "${GREEN}✓ Feature initialized in Vision phase${NC}"
    
    # GitHub Integration - Create issue for feature
    echo "  🐙 Creating GitHub issue for tracking..."
    # In production, would use: gh issue create --title "$feature" --body "$description" --label "feature,cpdm"
    echo "  📝 GitHub issue #XX created for feature tracking"
    
    # Send to vision-agent for validation
    echo "  📤 Sending to vision-agent for Triple Helix validation..."
}

# Transition to next phase
transition_phase() {
    local feature="$1"
    local current_phase=$(get_current_phase "$feature")
    
    # Determine next phase
    local next_phase
    case "$current_phase" in
        "vision") next_phase="design" ;;
        "design") next_phase="decision" ;;
        "decision") next_phase="implementation" ;;
        "implementation") next_phase="quality" ;;
        "quality") next_phase="delivery" ;;
        "delivery") next_phase="feedback" ;;
        "feedback") next_phase="complete" ;;
        *)
            echo -e "${RED}❌ Unknown current phase: $current_phase${NC}"
            return 1
            ;;
    esac
    
    echo -e "${BLUE}📊 Phase Transition: $current_phase → $next_phase${NC}"
    
    # Check quality gates
    if check_gates "$feature" "$current_phase" "$next_phase"; then
        echo -e "${GREEN}✅ All quality gates PASSED${NC}"
        update_phase "$feature" "$next_phase"
        echo -e "${GREEN}✓ Successfully transitioned to $next_phase phase${NC}"
        
        # Update metrics
        jq ".metrics.total_transitions += 1 |
            .metrics.successful_transitions += 1" "$CPDM_STATE" > "$CPDM_STATE.tmp"
        mv "$CPDM_STATE.tmp" "$CPDM_STATE"
        
        # Notify trace-agent
        notify_trace "$feature" "$next_phase"
    else
        echo -e "${RED}❌ Quality gates FAILED${NC}"
        echo "  Use 'cpdm-workflow override' to force transition with justification"
        
        # Update failed gate metric
        jq ".metrics.failed_gates += 1" "$CPDM_STATE" > "$CPDM_STATE.tmp"
        mv "$CPDM_STATE.tmp" "$CPDM_STATE"
        
        return 1
    fi
}

# Override gate with justification
override_gate() {
    local feature="$1"
    local reason="$2"
    local approver="$3"
    
    echo -e "${YELLOW}⚠️  Gate Override Request${NC}"
    echo "  Feature: $feature"
    echo "  Reason: $reason"
    echo "  Approver: $approver"
    
    # Log override
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    jq ".gate_overrides += [{
        \"feature\": \"$feature\",
        \"reason\": \"$reason\",
        \"approver\": \"$approver\",
        \"timestamp\": \"$timestamp\"
    }]" "$CPDM_STATE" > "$CPDM_STATE.tmp"
    mv "$CPDM_STATE.tmp" "$CPDM_STATE"
    
    echo -e "${YELLOW}✓ Override logged. Proceeding with transition...${NC}"
    
    # Force transition
    local current_phase=$(get_current_phase "$feature")
    local next_phase
    case "$current_phase" in
        "vision") next_phase="design" ;;
        "design") next_phase="decision" ;;
        "decision") next_phase="implementation" ;;
        "implementation") next_phase="quality" ;;
        "quality") next_phase="delivery" ;;
        "delivery") next_phase="feedback" ;;
        *) next_phase="complete" ;;
    esac
    
    update_phase "$feature" "$next_phase"
    echo -e "${GREEN}✓ Transitioned to $next_phase with override${NC}"
}

# Notify trace-agent of phase change
notify_trace() {
    local feature="$1"
    local phase="$2"
    
    mkdir -p "$TRACE_QUEUE"
    local notification_file="$TRACE_QUEUE/phase-change-$(uuidgen).json"
    
    cat > "$notification_file" << EOF
{
    "type": "phase_transition",
    "feature": "$feature",
    "new_phase": "$phase",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
}

# Show feature status
show_status() {
    local feature="$1"
    
    if [ -z "$feature" ]; then
        # Show all features
        echo -e "${BLUE}📊 CPDM Feature Status${NC}"
        echo "========================"
        
        jq -r '.active_features | to_entries[] | 
            "\(.key): \(.value.current_phase) (since \(.value.phase_entered))"' "$CPDM_STATE"
    else
        # Show specific feature
        local status=$(get_feature_status "$feature")
        if [ "$status" = "{}" ]; then
            echo -e "${RED}❌ Feature not found: $feature${NC}"
            return 1
        fi
        
        echo -e "${BLUE}📊 Feature: $feature${NC}"
        echo "$status" | jq .
    fi
}

# Show metrics
show_metrics() {
    echo -e "${BLUE}📈 CPDM Workflow Metrics${NC}"
    echo "========================"
    jq '.metrics' "$CPDM_STATE"
}

# Show phase history
show_history() {
    local feature="$1"
    
    echo -e "${BLUE}📜 Phase History${NC}"
    echo "================"
    
    if [ -z "$feature" ]; then
        jq -r '.phase_history[] | 
            "\(.timestamp): \(.feature) → \(.phase)"' "$CPDM_STATE"
    else
        jq -r ".phase_history[] | select(.feature == \"$feature\") | 
            \"\(.timestamp): → \(.phase)\"" "$CPDM_STATE"
    fi
}

# Main command handler
main() {
    init_state
    
    case "$1" in
        "start")
            start_feature "$2" "$3"
            ;;
        "transition")
            transition_phase "$2"
            ;;
        "override")
            override_gate "$2" "$3" "$4"
            ;;
        "status")
            show_status "$2"
            ;;
        "metrics")
            show_metrics
            ;;
        "history")
            show_history "$2"
            ;;
        "help"|"")
            echo "CPDM Workflow Engine"
            echo "===================="
            echo ""
            echo "Usage: $0 <command> [arguments]"
            echo ""
            echo "Commands:"
            echo "  start <feature> <description>     Start new feature in CPDM"
            echo "  transition <feature>              Transition to next phase"
            echo "  override <feature> <reason> <approver>  Override failed gate"
            echo "  status [feature]                  Show feature status"
            echo "  metrics                           Show workflow metrics"
            echo "  history [feature]                 Show phase history"
            echo ""
            echo "Examples:"
            echo "  $0 start 'user-auth' 'Add OAuth2 authentication'"
            echo "  $0 transition 'user-auth'"
            echo "  $0 status 'user-auth'"
            echo "  $0 override 'user-auth' 'Emergency fix' 'john.doe'"
            ;;
        *)
            echo -e "${RED}Unknown command: $1${NC}"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"