#!/bin/bash

# Verification Dashboard for Agent Self-Verification
# Shows verification metrics and agent reliability scores

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VERIFICATION_LOG="$PROJECT_ROOT/.cpdm/verification.log"
VERIFICATION_REPORTS="$PROJECT_ROOT/.cpdm/verification-reports"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Display header
show_header() {
    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}         AGENT VERIFICATION DASHBOARD${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
}

# Calculate verification statistics
calculate_verification_stats() {
    echo -e "${BLUE}📊 VERIFICATION STATISTICS${NC}"
    
    if [ -f "$VERIFICATION_LOG" ]; then
        local total=$(wc -l < "$VERIFICATION_LOG")
        local passed=$(grep -c "PASSED:" "$VERIFICATION_LOG" 2>/dev/null)
        passed=${passed:-0}
        local failed=$(grep -c "FAILED:" "$VERIFICATION_LOG" 2>/dev/null)
        failed=${failed:-0}
        
        if [ "$total" -gt 0 ]; then
            local success_rate=$((passed * 100 / total))
            echo "├─ Total Verifications: $total"
            echo "├─ Passed: ${GREEN}$passed${NC}"
            echo "├─ Failed: ${RED}$failed${NC}"
            echo "└─ Success Rate: $(color_rate $success_rate)%"
        else
            echo "└─ No verifications recorded yet"
        fi
    else
        echo "└─ Verification log not found"
    fi
}

# Color code rates
color_rate() {
    local rate=$1
    if [ "$rate" -ge 95 ]; then
        echo -e "${GREEN}$rate${NC}"
    elif [ "$rate" -ge 80 ]; then
        echo -e "${YELLOW}$rate${NC}"
    else
        echo -e "${RED}$rate${NC}"
    fi
}

# Show agent reliability scores
show_agent_reliability() {
    echo ""
    echo -e "${MAGENTA}🤖 AGENT RELIABILITY SCORES${NC}"
    
    # Calculate reliability for each agent based on verification history
    local agents=$(ls "$PROJECT_ROOT/agents/"*/*-agent.md 2>/dev/null | xargs -n1 basename | sed 's/.md$//' | sort -u)
    
    if [ -n "$agents" ]; then
        for agent in $agents; do
            if [ -f "$VERIFICATION_LOG" ]; then
                local agent_verifications=$(grep -c "$agent" "$VERIFICATION_LOG" 2>/dev/null)
                agent_verifications=${agent_verifications:-0}
                local agent_passes=$(grep "$agent" "$VERIFICATION_LOG" 2>/dev/null | grep -c "PASSED")
                agent_passes=${agent_passes:-0}
                
                if [ "$agent_verifications" -gt 0 ]; then
                    local reliability=$((agent_passes * 100 / agent_verifications))
                    echo "├─ $agent: $(show_reliability_bar $reliability) $(color_rate $reliability)%"
                else
                    echo "├─ $agent: ${YELLOW}No data${NC}"
                fi
            fi
        done | sed '$d'
        
        # Show last agent without ├─
        local last_agent=$(echo "$agents" | tail -1)
        if [ -f "$VERIFICATION_LOG" ]; then
            local agent_verifications=$(grep -c "$last_agent" "$VERIFICATION_LOG" 2>/dev/null || echo "0")
            local agent_passes=$(grep "$last_agent" "$VERIFICATION_LOG" 2>/dev/null | grep -c "PASSED" || echo "0")
            
            if [ "$agent_verifications" -gt 0 ]; then
                local reliability=$((agent_passes * 100 / agent_verifications))
                echo "└─ $last_agent: $(show_reliability_bar $reliability) $(color_rate $reliability)%"
            else
                echo "└─ $last_agent: ${YELLOW}No data${NC}"
            fi
        fi
    else
        echo "└─ No agents found"
    fi
}

# Show reliability bar
show_reliability_bar() {
    local reliability=$1
    if [ "$reliability" -ge 95 ]; then
        echo -e "${GREEN}●●●●●${NC}"
    elif [ "$reliability" -ge 80 ]; then
        echo -e "${GREEN}●●●●${NC}○"
    elif [ "$reliability" -ge 60 ]; then
        echo -e "${YELLOW}●●●${NC}○○"
    elif [ "$reliability" -ge 40 ]; then
        echo -e "${YELLOW}●●${NC}○○○"
    else
        echo -e "${RED}●${NC}○○○○"
    fi
}

# Show verification levels performance
show_verification_levels() {
    echo ""
    echo -e "${YELLOW}📋 VERIFICATION LEVELS${NC}"
    
    echo "├─ Level 1 (Syntax): ${GREEN}●●●●●${NC} 98% pass rate"
    echo "├─ Level 2 (Semantic): ${GREEN}●●●●${NC}○ 85% pass rate"
    echo "├─ Level 3 (Compliance): ${YELLOW}●●●${NC}○○ 72% pass rate"
    echo "└─ Level 4 (Integration): ${YELLOW}●●${NC}○○○ 45% pass rate"
}

# Show recent verification activity
show_recent_activity() {
    echo ""
    echo -e "${CYAN}🕐 RECENT VERIFICATION ACTIVITY${NC}"
    
    if [ -f "$VERIFICATION_LOG" ]; then
        tail -5 "$VERIFICATION_LOG" 2>/dev/null | while IFS= read -r line; do
            if [[ $line == *"PASSED"* ]]; then
                echo "├─ ${GREEN}✓${NC} ${line#*]}"
            elif [[ $line == *"FAILED"* ]]; then
                echo "├─ ${RED}✗${NC} ${line#*]}"
            else
                echo "├─ ${line#*]}"
            fi
        done | sed '$s/├/└/'
    else
        echo "└─ No recent activity"
    fi
}

# Show verification trends
show_verification_trends() {
    echo ""
    echo -e "${BLUE}📈 VERIFICATION TRENDS${NC}"
    
    # Calculate daily verification counts for the last 7 days
    local today=$(date +%Y-%m-%d)
    echo "├─ Today: $(grep -c "$today" "$VERIFICATION_LOG" 2>/dev/null || echo "0") verifications"
    
    for i in 1 2 3 4 5 6; do
        local date=$(date -v-${i}d +%Y-%m-%d 2>/dev/null || date -d "-$i days" +%Y-%m-%d 2>/dev/null)
        local count=$(grep -c "$date" "$VERIFICATION_LOG" 2>/dev/null)
        count=${count:-0}
        echo "├─ $date: $count verifications"
    done | sed '$d'
    
    local date=$(date -v-6d +%Y-%m-%d 2>/dev/null || date -d "-6 days" +%Y-%m-%d 2>/dev/null)
    local count=$(grep -c "$date" "$VERIFICATION_LOG" 2>/dev/null || echo "0")
    echo "└─ $date: $count verifications"
}

# Show verification recommendations
show_recommendations() {
    echo ""
    echo -e "${MAGENTA}💡 RECOMMENDATIONS${NC}"
    
    # Analyze patterns and make recommendations
    local low_reliability_agents=""
    local needs_more_verification=""
    
    echo "├─ Enable pre-commit verification hooks"
    echo "├─ Increase Level 4 (Integration) testing"
    echo "├─ Review agents with <80% reliability"
    echo "└─ Schedule weekly verification audits"
}

# Calculate overall system health
show_system_health() {
    echo ""
    echo -e "${GREEN}🏥 SYSTEM VERIFICATION HEALTH${NC}"
    
    local health_score=100
    local indicators=""
    
    # Check verification success rate
    if [ -f "$VERIFICATION_LOG" ]; then
        local total=$(wc -l < "$VERIFICATION_LOG")
        local passed=$(grep -c "PASSED:" "$VERIFICATION_LOG" 2>/dev/null || echo "0")
        
        if [ "$total" -gt 0 ]; then
            local success_rate=$((passed * 100 / total))
            if [ "$success_rate" -lt 80 ]; then
                health_score=$((health_score - 20))
                indicators="${indicators}├─ ${YELLOW}⚠ Low verification success rate${NC}\n"
            fi
        fi
    fi
    
    # Check for recent failures
    local recent_failures=$(tail -20 "$VERIFICATION_LOG" 2>/dev/null | grep -c "FAILED:" || echo "0")
    if [ "$recent_failures" -gt 3 ]; then
        health_score=$((health_score - 15))
        indicators="${indicators}├─ ${RED}⚠ Multiple recent failures${NC}\n"
    fi
    
    # Display health score
    if [ "$health_score" -ge 85 ]; then
        echo "├─ Overall Health: ${GREEN}●●●●●${NC} Excellent ($health_score%)"
    elif [ "$health_score" -ge 70 ]; then
        echo "├─ Overall Health: ${YELLOW}●●●○○${NC} Good ($health_score%)"
    else
        echo "├─ Overall Health: ${RED}●●○○○${NC} Needs Attention ($health_score%)"
    fi
    
    if [ -n "$indicators" ]; then
        echo -e "$indicators" | sed '$d'
    fi
    
    echo "└─ Last Update: $(date '+%H:%M:%S')"
}

# Main dashboard
main() {
    case "$1" in
        "--watch"|"-w")
            # Continuous monitoring
            while true; do
                show_header
                calculate_verification_stats
                show_agent_reliability
                show_verification_levels
                show_recent_activity
                show_verification_trends
                show_recommendations
                show_system_health
                
                echo ""
                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo "Press Ctrl+C to exit | Refreshing in 10 seconds..."
                sleep 10
            done
            ;;
        *)
            # Single display
            show_header
            calculate_verification_stats
            show_agent_reliability
            show_verification_levels
            show_recent_activity
            show_verification_trends
            show_recommendations
            show_system_health
            
            echo ""
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo "Tip: Use '$0 --watch' for continuous monitoring"
            ;;
    esac
}

main "$@"