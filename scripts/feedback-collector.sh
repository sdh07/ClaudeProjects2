#!/bin/bash

# Feedback Collection System for CPDM
# Captures, categorizes, and routes feedback for improvement

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FEEDBACK_DIR="$PROJECT_ROOT/.cpdm/feedback"
FEEDBACK_LOG="$FEEDBACK_DIR/feedback.log"
FEEDBACK_QUEUE="$HOME/.claudeprojects/messages/feedback/input"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Initialize feedback system
init_feedback() {
    mkdir -p "$FEEDBACK_DIR"
    mkdir -p "$FEEDBACK_DIR/processed"
    mkdir -p "$FEEDBACK_DIR/pending"
    mkdir -p "$FEEDBACK_DIR/insights"
    mkdir -p "$FEEDBACK_QUEUE"
    
    if [ ! -f "$FEEDBACK_LOG" ]; then
        echo "[$(date)] Feedback system initialized" > "$FEEDBACK_LOG"
    fi
}

# Collect feedback
collect_feedback() {
    local type=$1
    local category=$2
    local source=$3
    local message=$4
    local severity=${5:-"medium"}
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}COLLECTING FEEDBACK${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Generate feedback ID
    local feedback_id="fb-$(date +%s)-$$"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Create feedback record
    local feedback_file="$FEEDBACK_DIR/pending/$feedback_id.json"
    cat > "$feedback_file" << EOF
{
    "id": "$feedback_id",
    "timestamp": "$timestamp",
    "type": "$type",
    "category": "$category",
    "source": "$source",
    "message": "$message",
    "severity": "$severity",
    "status": "pending",
    "phase": "$(get_current_phase)",
    "sprint": "$(get_current_sprint)",
    "tags": []
}
EOF
    
    echo "Feedback ID: $feedback_id"
    echo "Type: $type"
    echo "Category: $category"
    echo "Severity: $severity"
    echo ""
    
    # Log feedback
    echo "[$(date)] COLLECTED: $feedback_id - $type - $category - $severity" >> "$FEEDBACK_LOG"
    
    # Route based on type
    route_feedback "$feedback_id" "$type" "$category" "$severity"
    
    echo -e "${GREEN}✅ Feedback collected successfully${NC}"
    echo "ID: $feedback_id"
    
    return 0
}

# Get current phase from CPDM state
get_current_phase() {
    local state_file="$HOME/.claudeprojects/state/cpdm-workflow.json"
    if [ -f "$state_file" ]; then
        # Get the most recent active feature's phase
        jq -r '.active_features | to_entries | .[0].value.current_phase // "unknown"' "$state_file" 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

# Get current sprint
get_current_sprint() {
    # Parse from git branch or CLAUDE.md
    grep -o "Sprint [0-9]*" "$PROJECT_ROOT/CLAUDE.md" 2>/dev/null | tail -1 | grep -o "[0-9]*" || echo "unknown"
}

# Route feedback to appropriate handlers
route_feedback() {
    local feedback_id=$1
    local type=$2
    local category=$3
    local severity=$4
    
    echo "Routing feedback..."
    
    case "$type" in
        "bug")
            route_to_issue_agent "$feedback_id" "$severity"
            ;;
        "feature")
            route_to_vision_agent "$feedback_id"
            ;;
        "quality")
            route_to_quality_agent "$feedback_id"
            ;;
        "performance")
            route_to_self_improvement "$feedback_id"
            ;;
        "documentation")
            route_to_knowledge_agent "$feedback_id"
            ;;
        *)
            echo -e "${YELLOW}⚠️  Unknown feedback type: $type${NC}"
            ;;
    esac
    
    # For high severity, notify immediately
    if [ "$severity" = "critical" ] || [ "$severity" = "high" ]; then
        echo -e "${RED}🚨 High priority feedback - immediate action required${NC}"
        notify_pm "$feedback_id" "$type" "$severity"
    fi
}

# Route to issue agent for bug tracking
route_to_issue_agent() {
    local feedback_id=$1
    local severity=$2
    
    echo "  → Routing to issue-agent for GitHub issue creation"
    
    mkdir -p "$FEEDBACK_QUEUE"
    cat > "$FEEDBACK_QUEUE/bug-$feedback_id.json" << EOF
{
    "type": "create_issue",
    "feedback_id": "$feedback_id",
    "severity": "$severity",
    "auto_create": true
}
EOF
}

# Route to vision agent for feature requests
route_to_vision_agent() {
    local feedback_id=$1
    
    echo "  → Routing to vision-agent for feature evaluation"
    
    mkdir -p "$FEEDBACK_QUEUE"
    cat > "$FEEDBACK_QUEUE/feature-$feedback_id.json" << EOF
{
    "type": "evaluate_feature",
    "feedback_id": "$feedback_id",
    "triple_helix": true
}
EOF
}

# Route to quality agent
route_to_quality_agent() {
    local feedback_id=$1
    
    echo "  → Routing to quality-agent for quality assessment"
}

# Route to self-improvement agent
route_to_self_improvement() {
    local feedback_id=$1
    
    echo "  → Routing to self-improvement-agent for optimization"
}

# Route to knowledge agent
route_to_knowledge_agent() {
    local feedback_id=$1
    
    echo "  → Routing to knowledge-agent for documentation update"
}

# Notify PM for critical feedback
notify_pm() {
    local feedback_id=$1
    local type=$2
    local severity=$3
    
    echo -e "${MAGENTA}📧 Notifying PM of $severity $type feedback${NC}"
    
    # In production, would send actual notification
    # For now, create a high-priority message
    mkdir -p "$FEEDBACK_QUEUE"
    cat > "$FEEDBACK_QUEUE/urgent-$feedback_id.json" << EOF
{
    "type": "urgent_notification",
    "feedback_id": "$feedback_id",
    "severity": "$severity",
    "requires_action": true
}
EOF
}

# Analyze feedback patterns
analyze_feedback() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}FEEDBACK ANALYSIS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local total=$(ls "$FEEDBACK_DIR/pending/"*.json 2>/dev/null | wc -l)
    local processed=$(ls "$FEEDBACK_DIR/processed/"*.json 2>/dev/null | wc -l)
    
    echo "📊 Feedback Statistics:"
    echo "├─ Pending: $total"
    echo "└─ Processed: $processed"
    echo ""
    
    # Analyze by type
    echo "📈 By Type:"
    for type in bug feature quality performance documentation; do
        local count=$(grep -l "\"type\": \"$type\"" "$FEEDBACK_DIR/"*/*.json 2>/dev/null | wc -l)
        echo "├─ $type: $count"
    done | sed '$s/├/└/'
    echo ""
    
    # Analyze by severity
    echo "⚠️  By Severity:"
    for severity in critical high medium low; do
        local count=$(grep -l "\"severity\": \"$severity\"" "$FEEDBACK_DIR/"*/*.json 2>/dev/null | wc -l)
        case $severity in
            critical) echo "├─ ${RED}Critical: $count${NC}" ;;
            high) echo "├─ ${YELLOW}High: $count${NC}" ;;
            medium) echo "├─ Medium: $count" ;;
            low) echo "└─ Low: $count" ;;
        esac
    done
    echo ""
    
    # Find patterns
    find_feedback_patterns
}

# Find patterns in feedback
find_feedback_patterns() {
    echo "🔍 Pattern Detection:"
    
    # Check for recurring themes
    local themes=""
    
    # Count word frequency in feedback messages
    if ls "$FEEDBACK_DIR/"*/*.json 1> /dev/null 2>&1; then
        themes=$(jq -r '.message' "$FEEDBACK_DIR/"*/*.json 2>/dev/null | \
                 tr ' ' '\n' | \
                 grep -v '^$' | \
                 sort | uniq -c | \
                 sort -rn | \
                 head -5)
        
        if [ -n "$themes" ]; then
            echo "├─ Top keywords:"
            echo "$themes" | while read count word; do
                echo "│  - $word ($count occurrences)"
            done
        fi
    fi
    
    # Identify hot spots (phases with most feedback)
    echo "└─ Hot spots:"
    for phase in vision design decision implementation quality delivery feedback; do
        local count=$(grep -l "\"phase\": \"$phase\"" "$FEEDBACK_DIR/"*/*.json 2>/dev/null | wc -l)
        if [ "$count" -gt 0 ]; then
            echo "   - $phase phase: $count issues"
        fi
    done
}

# Process pending feedback
process_feedback() {
    local feedback_id=$1
    
    if [ -z "$feedback_id" ]; then
        # Process all pending
        echo "Processing all pending feedback..."
        for file in "$FEEDBACK_DIR/pending/"*.json; do
            [ -f "$file" ] || continue
            local id=$(basename "$file" .json)
            process_single_feedback "$id"
        done
    else
        # Process specific feedback
        process_single_feedback "$feedback_id"
    fi
}

# Process single feedback item
process_single_feedback() {
    local feedback_id=$1
    local feedback_file="$FEEDBACK_DIR/pending/$feedback_id.json"
    
    if [ ! -f "$feedback_file" ]; then
        echo -e "${RED}Feedback not found: $feedback_id${NC}"
        return 1
    fi
    
    echo "Processing feedback: $feedback_id"
    
    # Update status
    jq '.status = "processing"' "$feedback_file" > "$feedback_file.tmp"
    mv "$feedback_file.tmp" "$feedback_file"
    
    # Extract feedback details
    local type=$(jq -r '.type' "$feedback_file")
    local severity=$(jq -r '.severity' "$feedback_file")
    
    # Simulate processing based on type
    case "$type" in
        "bug")
            echo "  Creating GitHub issue..."
            ;;
        "feature")
            echo "  Evaluating with Triple Helix..."
            ;;
        "quality")
            echo "  Running quality checks..."
            ;;
        *)
            echo "  Processing..."
            ;;
    esac
    
    # Mark as processed
    jq '.status = "processed" | .processed_at = "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"' "$feedback_file" > "$feedback_file.tmp"
    mv "$feedback_file.tmp" "$FEEDBACK_DIR/processed/$feedback_id.json"
    rm -f "$feedback_file"
    
    echo -e "${GREEN}✅ Feedback processed${NC}"
    
    # Log processing
    echo "[$(date)] PROCESSED: $feedback_id" >> "$FEEDBACK_LOG"
}

# Generate feedback report
generate_report() {
    local output_file="$FEEDBACK_DIR/reports/feedback-report-$(date +%Y%m%d-%H%M%S).md"
    mkdir -p "$(dirname "$output_file")"
    
    {
        echo "# Feedback Report"
        echo "Generated: $(date)"
        echo ""
        echo "## Summary"
        
        local total=$(ls "$FEEDBACK_DIR/"*/*.json 2>/dev/null | wc -l)
        local pending=$(ls "$FEEDBACK_DIR/pending/"*.json 2>/dev/null | wc -l)
        local processed=$(ls "$FEEDBACK_DIR/processed/"*.json 2>/dev/null | wc -l)
        
        echo "- Total feedback: $total"
        echo "- Pending: $pending"
        echo "- Processed: $processed"
        echo ""
        
        echo "## Recent Feedback"
        echo ""
        
        # List recent feedback items
        ls -t "$FEEDBACK_DIR/"*/*.json 2>/dev/null | head -10 | while read file; do
            if [ -f "$file" ]; then
                local id=$(jq -r '.id' "$file")
                local type=$(jq -r '.type' "$file")
                local severity=$(jq -r '.severity' "$file")
                local message=$(jq -r '.message' "$file")
                echo "### $id"
                echo "- Type: $type"
                echo "- Severity: $severity"
                echo "- Message: $message"
                echo ""
            fi
        done
        
        echo "## Patterns Identified"
        echo ""
        echo "See analysis section for detailed patterns."
        
        echo ""
        echo "## Recommendations"
        echo ""
        echo "1. Address critical/high severity items first"
        echo "2. Look for patterns in recurring feedback"
        echo "3. Update documentation based on confusion points"
        echo "4. Consider automation for frequent issues"
    } > "$output_file"
    
    echo -e "${GREEN}Report generated: $output_file${NC}"
}

# Interactive feedback collection
interactive_feedback() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}INTERACTIVE FEEDBACK COLLECTION${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Get feedback type
    echo "What type of feedback? (bug/feature/quality/performance/documentation)"
    read -r type
    
    # Get category
    echo "Category? (agent/workflow/ui/api/other)"
    read -r category
    
    # Get severity
    echo "Severity? (critical/high/medium/low)"
    read -r severity
    
    # Get message
    echo "Describe the feedback:"
    read -r message
    
    # Collect the feedback
    collect_feedback "$type" "$category" "user-interactive" "$message" "$severity"
}

# Main command handler
main() {
    init_feedback
    
    case "$1" in
        "collect")
            shift
            collect_feedback "$@"
            ;;
        "analyze")
            analyze_feedback
            ;;
        "process")
            process_feedback "$2"
            ;;
        "report")
            generate_report
            ;;
        "interactive")
            interactive_feedback
            ;;
        "status")
            echo "Feedback System Status:"
            echo "Pending: $(ls "$FEEDBACK_DIR/pending/"*.json 2>/dev/null | wc -l)"
            echo "Processed: $(ls "$FEEDBACK_DIR/processed/"*.json 2>/dev/null | wc -l)"
            tail -5 "$FEEDBACK_LOG"
            ;;
        *)
            echo "Feedback Collection System"
            echo ""
            echo "Usage:"
            echo "  $0 collect <type> <category> <source> <message> [severity]"
            echo "  $0 analyze                     - Analyze feedback patterns"
            echo "  $0 process [feedback-id]        - Process pending feedback"
            echo "  $0 report                       - Generate feedback report"
            echo "  $0 interactive                  - Interactive feedback mode"
            echo "  $0 status                       - Show system status"
            echo ""
            echo "Types: bug, feature, quality, performance, documentation"
            echo "Categories: agent, workflow, ui, api, other"
            echo "Severities: critical, high, medium, low"
            echo ""
            echo "Examples:"
            echo "  $0 collect bug agent user 'Code review agent missed an issue' high"
            echo "  $0 analyze"
            echo "  $0 process fb-123456-789"
            ;;
    esac
}

main "$@"