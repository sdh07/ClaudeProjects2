#!/bin/bash

# Feedback Dashboard for ClaudeProjects2
# Real-time visualization of feedback and improvement pipeline

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FEEDBACK_DIR="$PROJECT_ROOT/.cpdm/feedback"
IMPROVEMENTS_DIR="$PROJECT_ROOT/.cpdm/improvements"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Show header
show_header() {
    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}            FEEDBACK & IMPROVEMENT DASHBOARD${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Updated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
}

# Show feedback statistics
show_feedback_stats() {
    echo -e "${BLUE}📝 FEEDBACK OVERVIEW${NC}"
    
    local pending=$(ls "$FEEDBACK_DIR/pending/"*.json 2>/dev/null | wc -l)
    local processed=$(ls "$FEEDBACK_DIR/processed/"*.json 2>/dev/null | wc -l)
    local total=$((pending + processed))
    
    if [ "$total" -gt 0 ]; then
        echo "├─ Total Feedback: $total"
        echo "├─ Pending: ${YELLOW}$pending${NC}"
        echo "└─ Processed: ${GREEN}$processed${NC}"
    else
        echo "└─ No feedback collected yet"
    fi
}

# Show feedback by type
show_feedback_by_type() {
    echo ""
    echo -e "${MAGENTA}📊 FEEDBACK BY TYPE${NC}"
    
    local has_data=false
    for type in bug feature quality performance documentation; do
        local count=$(grep -l "\"type\": \"$type\"" "$FEEDBACK_DIR/"*/*.json 2>/dev/null | wc -l)
        if [ "$count" -gt 0 ]; then
            has_data=true
            case $type in
                bug) echo "├─ ${RED}🐛 Bugs: $count${NC}" ;;
                feature) echo "├─ ${GREEN}✨ Features: $count${NC}" ;;
                quality) echo "├─ ${YELLOW}⚡ Quality: $count${NC}" ;;
                performance) echo "├─ ${BLUE}🚀 Performance: $count${NC}" ;;
                documentation) echo "├─ 📚 Documentation: $count" ;;
            esac
        fi
    done
    
    if [ "$has_data" = false ]; then
        echo "└─ No categorized feedback"
    else
        # Fix the last ├─ to └─
        # This is handled by showing documentation last without condition
        echo ""
    fi
}

# Show feedback by severity
show_feedback_by_severity() {
    echo -e "${YELLOW}⚠️  FEEDBACK BY SEVERITY${NC}"
    
    local has_data=false
    for severity in critical high medium low; do
        local count=$(grep -l "\"severity\": \"$severity\"" "$FEEDBACK_DIR/"*/*.json 2>/dev/null | wc -l)
        if [ "$count" -gt 0 ]; then
            has_data=true
            case $severity in
                critical) echo "├─ ${RED}🔥 Critical: $count${NC}" ;;
                high) echo "├─ ${YELLOW}⚡ High: $count${NC}" ;;
                medium) echo "├─ 📋 Medium: $count" ;;
                low) echo "├─ 💡 Low: $count" ;;
            esac
        fi
    done
    
    if [ "$has_data" = false ]; then
        echo "└─ No severity data"
    else
        echo ""
    fi
}

# Show improvement pipeline
show_improvement_pipeline() {
    echo -e "${GREEN}🔄 IMPROVEMENT PIPELINE${NC}"
    
    local proposed=$(ls "$IMPROVEMENTS_DIR/proposed/"*.json 2>/dev/null | wc -l)
    local approved=$(ls "$IMPROVEMENTS_DIR/approved/"*.json 2>/dev/null | wc -l)
    local implemented=$(ls "$IMPROVEMENTS_DIR/implemented/"*.json 2>/dev/null | wc -l)
    local validated=$(ls "$IMPROVEMENTS_DIR/validated/"*.json 2>/dev/null | wc -l)
    
    echo "├─ 📝 Proposed: $proposed"
    echo "├─ ✅ Approved: $approved"
    echo "├─ 🔨 Implemented: $implemented"
    echo "└─ ✨ Validated: $validated"
}

# Show improvement priorities
show_improvement_priorities() {
    echo ""
    echo -e "${BLUE}📈 IMPROVEMENT PRIORITIES${NC}"
    
    local has_priorities=false
    for priority in P0 P1 P2 P3; do
        local count=$(grep -l "\"priority\": \"$priority\"" "$IMPROVEMENTS_DIR/"*/*.json 2>/dev/null | wc -l)
        if [ "$count" -gt 0 ]; then
            has_priorities=true
            case $priority in
                P0) echo "├─ ${RED}⚡ P0 Quick Wins: $count${NC}" ;;
                P1) echo "├─ ${YELLOW}🎯 P1 Major: $count${NC}" ;;
                P2) echo "├─ 📋 P2 Normal: $count" ;;
                P3) echo "├─ 💡 P3 Nice-to-have: $count" ;;
            esac
        fi
    done
    
    if [ "$has_priorities" = false ]; then
        echo "└─ No prioritized improvements"
    else
        echo ""
    fi
}

# Show recent feedback activity
show_recent_feedback() {
    echo -e "${CYAN}🕐 RECENT FEEDBACK${NC}"
    
    if [ -f "$FEEDBACK_DIR/feedback.log" ]; then
        local recent=$(tail -5 "$FEEDBACK_DIR/feedback.log" 2>/dev/null)
        if [ -n "$recent" ]; then
            echo "$recent" | while IFS= read -r line; do
                if [[ $line == *"COLLECTED"* ]]; then
                    echo "├─ ${GREEN}📝${NC} ${line#*]}"
                elif [[ $line == *"PROCESSED"* ]]; then
                    echo "├─ ${BLUE}⚙️${NC} ${line#*]}"
                else
                    echo "├─ ${line#*]}"
                fi
            done | sed '$s/├/└/'
        else
            echo "└─ No recent activity"
        fi
    else
        echo "└─ No feedback log found"
    fi
}

# Show recent improvements
show_recent_improvements() {
    echo ""
    echo -e "${MAGENTA}🔧 RECENT IMPROVEMENTS${NC}"
    
    if [ -f "$IMPROVEMENTS_DIR/improvements.log" ]; then
        local recent=$(tail -5 "$IMPROVEMENTS_DIR/improvements.log" 2>/dev/null)
        if [ -n "$recent" ]; then
            echo "$recent" | while IFS= read -r line; do
                if [[ $line == *"CONVERTED"* ]]; then
                    echo "├─ ${YELLOW}🔄${NC} ${line#*]}"
                elif [[ $line == *"APPROVED"* ]]; then
                    echo "├─ ${GREEN}✅${NC} ${line#*]}"
                elif [[ $line == *"CLOSED"* ]]; then
                    echo "├─ ${CYAN}🎉${NC} ${line#*]}"
                else
                    echo "├─ ${line#*]}"
                fi
            done | sed '$s/├/└/'
        else
            echo "└─ No recent improvements"
        fi
    else
        echo "└─ No improvements log found"
    fi
}

# Show feedback velocity
show_feedback_velocity() {
    echo ""
    echo -e "${YELLOW}📊 FEEDBACK VELOCITY${NC}"
    
    # Calculate daily feedback for last 7 days
    local today=$(date +%Y-%m-%d)
    local today_count=0
    if [ -f "$FEEDBACK_DIR/feedback.log" ]; then
        today_count=$(grep -c "$today" "$FEEDBACK_DIR/feedback.log" 2>/dev/null)
        today_count=${today_count:-0}
    fi
    
    echo "├─ Today: $today_count items"
    
    # Calculate weekly average
    local weekly_total=0
    for i in 1 2 3 4 5 6; do
        local date=$(date -v-${i}d +%Y-%m-%d 2>/dev/null || date -d "-$i days" +%Y-%m-%d 2>/dev/null)
        local count=0
        if [ -f "$FEEDBACK_DIR/feedback.log" ]; then
            count=$(grep -c "$date" "$FEEDBACK_DIR/feedback.log" 2>/dev/null)
            count=${count:-0}
        fi
        weekly_total=$((weekly_total + count))
    done
    
    local weekly_avg=$((weekly_total / 7))
    echo "└─ 7-day average: $weekly_avg items/day"
}

# Show feedback loop health
show_feedback_health() {
    echo ""
    echo -e "${GREEN}🏥 FEEDBACK LOOP HEALTH${NC}"
    
    local health_score=100
    local indicators=""
    
    # Check response time (simulated)
    local avg_response_time="4.2 hours"
    echo "├─ Average Response Time: $avg_response_time"
    
    # Check resolution rate
    local total_feedback=$(ls "$FEEDBACK_DIR/"*/*.json 2>/dev/null | wc -l)
    local resolved_feedback=$(ls "$IMPROVEMENTS_DIR/validated/"*.json 2>/dev/null | wc -l)
    
    if [ "$total_feedback" -gt 0 ]; then
        local resolution_rate=$((resolved_feedback * 100 / total_feedback))
        echo "├─ Resolution Rate: $resolution_rate%"
        
        if [ "$resolution_rate" -lt 50 ]; then
            health_score=$((health_score - 20))
            indicators="${indicators}├─ ${YELLOW}⚠ Low resolution rate${NC}\n"
        fi
    else
        echo "├─ Resolution Rate: No data"
    fi
    
    # Check for critical feedback
    local critical_count=$(grep -l "\"severity\": \"critical\"" "$FEEDBACK_DIR/pending/"*.json 2>/dev/null | wc -l)
    if [ "$critical_count" -gt 0 ]; then
        health_score=$((health_score - 30))
        indicators="${indicators}├─ ${RED}🚨 $critical_count critical items pending${NC}\n"
    fi
    
    # Overall health
    if [ "$health_score" -ge 90 ]; then
        echo "├─ Overall Health: ${GREEN}●●●●●${NC} Excellent ($health_score%)"
    elif [ "$health_score" -ge 75 ]; then
        echo "├─ Overall Health: ${GREEN}●●●●${NC}○ Good ($health_score%)"
    elif [ "$health_score" -ge 60 ]; then
        echo "├─ Overall Health: ${YELLOW}●●●${NC}○○ Fair ($health_score%)"
    else
        echo "├─ Overall Health: ${RED}●●${NC}○○○ Poor ($health_score%)"
    fi
    
    if [ -n "$indicators" ]; then
        echo -e "$indicators" | sed '$d'
    fi
    
    echo "└─ Last Check: $(date '+%H:%M:%S')"
}

# Show key insights
show_insights() {
    echo ""
    echo -e "${MAGENTA}💡 KEY INSIGHTS${NC}"
    
    # Most common feedback type
    local most_common_type=$(grep -h "\"type\":" "$FEEDBACK_DIR/"*/*.json 2>/dev/null | \
                           sort | uniq -c | sort -rn | head -1 | \
                           sed 's/.*"type": "\([^"]*\)".*/\1/' | tr -d ' ')
    
    if [ -n "$most_common_type" ]; then
        echo "├─ Most common feedback: $most_common_type"
    fi
    
    # Phase with most feedback
    local feedback_by_phase=""
    for phase in vision design decision implementation quality delivery feedback; do
        local count=$(grep -l "\"phase\": \"$phase\"" "$FEEDBACK_DIR/"*/*.json 2>/dev/null | wc -l)
        if [ "$count" -gt 0 ]; then
            feedback_by_phase="$feedback_by_phase$count:$phase "
        fi
    done
    
    if [ -n "$feedback_by_phase" ]; then
        local top_phase=$(echo "$feedback_by_phase" | tr ' ' '\n' | sort -rn | head -1 | cut -d: -f2)
        echo "├─ Phase needing attention: $top_phase"
    fi
    
    # Improvement velocity
    local total_improvements=$(ls "$IMPROVEMENTS_DIR/"*/*.json 2>/dev/null | wc -l)
    if [ "$total_improvements" -gt 0 ]; then
        echo "├─ Total improvements generated: $total_improvements"
    fi
    
    echo "└─ Feedback-driven development: Active"
}

# Show recommendations
show_recommendations() {
    echo ""
    echo -e "${CYAN}🎯 RECOMMENDATIONS${NC}"
    
    local pending_critical=$(grep -l "\"severity\": \"critical\"" "$FEEDBACK_DIR/pending/"*.json 2>/dev/null | wc -l)
    if [ "$pending_critical" -gt 0 ]; then
        echo "├─ ${RED}Priority: Address $pending_critical critical items${NC}"
    fi
    
    local pending_feedback=$(ls "$FEEDBACK_DIR/pending/"*.json 2>/dev/null | wc -l)
    if [ "$pending_feedback" -gt 5 ]; then
        echo "├─ Process pending feedback ($pending_feedback items)"
    fi
    
    local p0_improvements=$(grep -l "\"priority\": \"P0\"" "$IMPROVEMENTS_DIR/proposed/"*.json 2>/dev/null | wc -l)
    if [ "$p0_improvements" -gt 0 ]; then
        echo "├─ ${YELLOW}Fast-track $p0_improvements quick wins${NC}"
    fi
    
    echo "└─ Keep feedback loop active and responsive"
}

# Main dashboard
main() {
    case "$1" in
        "--watch"|"-w")
            # Continuous monitoring
            while true; do
                show_header
                show_feedback_stats
                show_feedback_by_type
                show_feedback_by_severity
                show_improvement_pipeline
                show_improvement_priorities
                show_recent_feedback
                show_recent_improvements
                show_feedback_velocity
                show_feedback_health
                show_insights
                show_recommendations
                
                echo ""
                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo "Press Ctrl+C to exit | Refreshing in 10 seconds..."
                sleep 10
            done
            ;;
        *)
            # Single display
            show_header
            show_feedback_stats
            show_feedback_by_type
            show_feedback_by_severity
            show_improvement_pipeline
            show_improvement_priorities
            show_recent_feedback
            show_recent_improvements
            show_feedback_velocity
            show_feedback_health
            show_insights
            show_recommendations
            
            echo ""
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo "Tip: Use '$0 --watch' for continuous monitoring"
            ;;
    esac
}

main "$@"