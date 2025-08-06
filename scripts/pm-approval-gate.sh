#!/bin/bash

# PM Approval Gate for CPDM Workflow
# Ensures PM reviews and approves key deliverables before phase transitions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
APPROVAL_DIR="$PROJECT_ROOT/.cpdm/approvals"
APPROVAL_LOG="$PROJECT_ROOT/.cpdm/approval.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize approval directory
init_approvals() {
    mkdir -p "$APPROVAL_DIR"
    touch "$APPROVAL_LOG"
}

# Check if approval is required for phase transition
requires_approval() {
    local from_phase=$1
    local to_phase=$2
    
    # Define which transitions require PM approval
    case "${from_phase}_${to_phase}" in
        "vision_design")
            echo "true"  # PM must approve vision before design
            ;;
        "decision_implementation")
            echo "true"  # PM must approve ADR before implementation
            ;;
        "delivery_feedback")
            echo "true"  # PM must approve release before feedback
            ;;
        *)
            echo "false"
            ;;
    esac
}

# Check if approval exists
check_approval() {
    local feature=$1
    local phase=$2
    local approval_file="$APPROVAL_DIR/${feature}_${phase}.json"
    
    if [ -f "$approval_file" ]; then
        local approved=$(jq -r '.approved' "$approval_file")
        if [ "$approved" == "true" ]; then
            echo "approved"
        else
            echo "rejected"
        fi
    else
        echo "pending"
    fi
}

# Request PM approval
request_approval() {
    local feature=$1
    local phase=$2
    local deliverable=$3
    
    local approval_file="$APPROVAL_DIR/${feature}_${phase}_request.json"
    
    cat > "$approval_file" << EOF
{
    "feature": "$feature",
    "phase": "$phase",
    "deliverable": "$deliverable",
    "requested_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "status": "pending",
    "approved": false,
    "approver": null,
    "approval_date": null,
    "comments": null
}
EOF
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}PM APPROVAL REQUIRED${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Feature: ${BLUE}$feature${NC}"
    echo -e "Phase: ${BLUE}$phase${NC}"
    echo -e "Deliverable: ${BLUE}$deliverable${NC}"
    echo ""
    echo -e "${YELLOW}Please review the deliverable and approve:${NC}"
    echo ""
    
    # Show deliverable location based on phase
    case $phase in
        "vision")
            echo "  Vision Document: docs/architecture/01-product-vision/features/${feature}.md"
            ;;
        "decision")
            echo "  ADR: docs/architecture/ADRs/*${feature}*.md"
            echo "  Physical Architecture: docs/architecture/03-physical-architecture/${feature}.md"
            ;;
        "delivery")
            echo "  Release Notes: docs/releases/${feature}.md"
            echo "  Test Report: .cpdm/tests/${feature}_report.json"
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}To approve:${NC}"
    echo "  ./scripts/cpdm-workflow-engine.sh approve $feature $phase"
    echo ""
    echo -e "${RED}To reject with feedback:${NC}"
    echo "  ./scripts/cpdm-workflow-engine.sh reject $feature $phase \"feedback message\""
    echo ""
    
    # Log approval request
    echo "[$(date)] Approval requested for $feature $phase" >> "$APPROVAL_LOG"
}

# Grant approval
grant_approval() {
    local feature=$1
    local phase=$2
    local approver=${3:-"PM"}
    local comments=${4:-"Approved"}
    
    local request_file="$APPROVAL_DIR/${feature}_${phase}_request.json"
    local approval_file="$APPROVAL_DIR/${feature}_${phase}.json"
    
    if [ ! -f "$request_file" ]; then
        echo -e "${RED}No approval request found for $feature $phase${NC}"
        return 1
    fi
    
    # Create approval record
    jq --arg approver "$approver" \
       --arg comments "$comments" \
       --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.approved = true |
        .approver = $approver |
        .approval_date = $date |
        .comments = $comments |
        .status = "approved"' "$request_file" > "$approval_file"
    
    echo -e "${GREEN}✅ Approval granted for $feature $phase${NC}"
    echo -e "Approver: $approver"
    echo -e "Comments: $comments"
    
    # Log approval
    echo "[$(date)] Approved: $feature $phase by $approver" >> "$APPROVAL_LOG"
    
    # Trigger automatic transition if approval was blocking
    echo -e "${BLUE}You can now transition to the next phase:${NC}"
    echo "  ./scripts/cpdm-workflow-engine.sh transition $feature"
}

# Reject with feedback
reject_approval() {
    local feature=$1
    local phase=$2
    local feedback=$3
    
    local request_file="$APPROVAL_DIR/${feature}_${phase}_request.json"
    local rejection_file="$APPROVAL_DIR/${feature}_${phase}_rejection.json"
    
    if [ ! -f "$request_file" ]; then
        echo -e "${RED}No approval request found for $feature $phase${NC}"
        return 1
    fi
    
    # Create rejection record
    jq --arg feedback "$feedback" \
       --arg date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.approved = false |
        .status = "rejected" |
        .rejection_date = $date |
        .feedback = $feedback' "$request_file" > "$rejection_file"
    
    echo -e "${RED}❌ Approval rejected for $feature $phase${NC}"
    echo -e "Feedback: $feedback"
    echo ""
    echo -e "${YELLOW}Please address the feedback and resubmit for approval${NC}"
    
    # Log rejection
    echo "[$(date)] Rejected: $feature $phase - $feedback" >> "$APPROVAL_LOG"
}

# List pending approvals
list_pending() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}PENDING PM APPROVALS${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local found=false
    for request in "$APPROVAL_DIR"/*_request.json; do
        if [ -f "$request" ]; then
            local status=$(jq -r '.status' "$request")
            if [ "$status" == "pending" ]; then
                found=true
                local feature=$(jq -r '.feature' "$request")
                local phase=$(jq -r '.phase' "$request")
                local requested=$(jq -r '.requested_at' "$request")
                
                echo -e "Feature: ${BLUE}$feature${NC}"
                echo -e "Phase: $phase"
                echo -e "Requested: $requested"
                echo ""
            fi
        fi
    done
    
    if [ "$found" == "false" ]; then
        echo "No pending approvals"
    fi
}

# Main execution
init_approvals

case "$1" in
    "check")
        check_approval "$2" "$3"
        ;;
    "request")
        request_approval "$2" "$3" "$4"
        ;;
    "approve")
        grant_approval "$2" "$3" "$4" "$5"
        ;;
    "reject")
        reject_approval "$2" "$3" "$4"
        ;;
    "pending")
        list_pending
        ;;
    "requires")
        requires_approval "$2" "$3"
        ;;
    *)
        echo "PM Approval Gate System"
        echo ""
        echo "Commands:"
        echo "  check <feature> <phase>         Check approval status"
        echo "  request <feature> <phase> <deliverable>  Request PM approval"
        echo "  approve <feature> <phase> [approver] [comments]  Grant approval"
        echo "  reject <feature> <phase> <feedback>  Reject with feedback"
        echo "  pending                         List pending approvals"
        echo "  requires <from_phase> <to_phase>  Check if approval required"
        ;;
esac