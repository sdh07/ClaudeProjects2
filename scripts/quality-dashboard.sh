#!/bin/bash

# Quality Metrics Dashboard for CPDM
# Displays real-time quality metrics and compliance status

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CPDM_STATE="$HOME/.claudeprojects/state/cpdm-workflow.json"
QUALITY_LOG="$PROJECT_ROOT/.cpdm/quality.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Clear screen and show header
show_header() {
    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}           CPDM QUALITY METRICS DASHBOARD${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Updated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
}

# Calculate velocity metrics
calculate_velocity() {
    if [ -f "$CPDM_STATE" ]; then
        local total_transitions=$(jq -r '.metrics.total_transitions // 0' "$CPDM_STATE")
        local successful=$(jq -r '.metrics.successful_transitions // 0' "$CPDM_STATE")
        local failed=$(jq -r '.metrics.failed_gates // 0' "$CPDM_STATE")
        
        if [ "$total_transitions" -gt 0 ]; then
            local success_rate=$((successful * 100 / total_transitions))
            echo -e "${BLUE}📊 VELOCITY METRICS${NC}"
            echo "├─ Total Transitions: $total_transitions"
            echo "├─ Successful: ${GREEN}$successful${NC}"
            echo "├─ Failed Gates: ${RED}$failed${NC}"
            echo "└─ Success Rate: $(color_percentage $success_rate)%"
        else
            echo -e "${BLUE}📊 VELOCITY METRICS${NC}"
            echo "└─ No transitions recorded yet"
        fi
    else
        echo -e "${BLUE}📊 VELOCITY METRICS${NC}"
        echo "└─ No data available"
    fi
}

# Color code percentages
color_percentage() {
    local value=$1
    if [ "$value" -ge 90 ]; then
        echo -e "${GREEN}$value${NC}"
    elif [ "$value" -ge 70 ]; then
        echo -e "${YELLOW}$value${NC}"
    else
        echo -e "${RED}$value${NC}"
    fi
}

# Show active features
show_active_features() {
    echo ""
    echo -e "${MAGENTA}🚀 ACTIVE FEATURES${NC}"
    
    if [ -f "$CPDM_STATE" ]; then
        local features=$(jq -r '.active_features | to_entries[] | "\(.key)|\(.value.current_phase)|\(.value.status)"' "$CPDM_STATE" 2>/dev/null)
        
        if [ -n "$features" ]; then
            echo "$features" | while IFS='|' read -r name phase status; do
                local phase_icon=""
                case "$phase" in
                    vision) phase_icon="👁️ " ;;
                    design) phase_icon="📐" ;;
                    decision) phase_icon="🎯" ;;
                    implementation) phase_icon="⚙️ " ;;
                    quality) phase_icon="✅" ;;
                    delivery) phase_icon="🚀" ;;
                    feedback) phase_icon="📝" ;;
                esac
                
                local status_color="${GREEN}"
                [ "$status" != "active" ] && status_color="${YELLOW}"
                
                echo "├─ $name: $phase_icon $phase ${status_color}[$status]${NC}"
            done | sed '$d'
            echo "$features" | tail -1 | while IFS='|' read -r name phase status; do
                local phase_icon=""
                case "$phase" in
                    vision) phase_icon="👁️ " ;;
                    design) phase_icon="📐" ;;
                    decision) phase_icon="🎯" ;;
                    implementation) phase_icon="⚙️ " ;;
                    quality) phase_icon="✅" ;;
                    delivery) phase_icon="🚀" ;;
                    feedback) phase_icon="📝" ;;
                esac
                echo "└─ $name: $phase_icon $phase [$status]"
            done
        else
            echo "└─ No active features"
        fi
    else
        echo "└─ No features tracked"
    fi
}

# Quality gate compliance
show_gate_compliance() {
    echo ""
    echo -e "${YELLOW}🔒 QUALITY GATE COMPLIANCE${NC}"
    
    if [ -f "$QUALITY_LOG" ]; then
        local passed=$(grep -c "PASSED:" "$QUALITY_LOG" 2>/dev/null)
        passed=${passed:-0}
        local failed=$(grep -c "FAILED:" "$QUALITY_LOG" 2>/dev/null)
        failed=${failed:-0}
        local overrides=$(grep -c "OVERRIDE:" "$QUALITY_LOG" 2>/dev/null)
        overrides=${overrides:-0}
        
        local total=$((passed + failed))
        if [ "$total" -gt 0 ]; then
            local compliance=$((passed * 100 / total))
            echo "├─ Gates Passed: ${GREEN}$passed${NC}"
            echo "├─ Gates Failed: ${RED}$failed${NC}"
            echo "├─ Overrides Used: ${YELLOW}$overrides${NC}"
            echo "└─ Compliance Rate: $(color_percentage $compliance)%"
        else
            echo "└─ No gate checks performed"
        fi
    else
        echo "└─ No compliance data"
    fi
}

# Code quality metrics
show_code_quality() {
    echo ""
    echo -e "${CYAN}💻 CODE QUALITY${NC}"
    
    # Check if package.json exists
    if [ -f "$PROJECT_ROOT/package.json" ]; then
        # Test coverage (if available)
        if [ -f "$PROJECT_ROOT/coverage/coverage-summary.json" ]; then
            local coverage=$(jq -r '.total.lines.pct' "$PROJECT_ROOT/coverage/coverage-summary.json" 2>/dev/null || echo "0")
            echo "├─ Test Coverage: $(color_percentage ${coverage%.*})%"
        else
            echo "├─ Test Coverage: Not measured"
        fi
        
        # Count TODOs
        local todos=$(grep -r "TODO" "$PROJECT_ROOT" --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l)
        echo "├─ TODOs: $todos"
        
        # Count FIXMEs
        local fixmes=$(grep -r "FIXME" "$PROJECT_ROOT" --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l)
        echo "└─ FIXMEs: $fixmes"
    else
        echo "└─ No code metrics available"
    fi
}

# Architecture compliance
show_architecture_compliance() {
    echo ""
    echo -e "${BLUE}🏗️  ARCHITECTURE COMPLIANCE${NC}"
    
    local vision_docs=$(ls "$PROJECT_ROOT/docs/architecture/01-product-vision/"*.md 2>/dev/null | wc -l)
    local logical_docs=$(ls "$PROJECT_ROOT/docs/architecture/02-logical-architecture/"*.md 2>/dev/null | wc -l)
    local physical_docs=$(ls "$PROJECT_ROOT/docs/architecture/03-physical-architecture/"*.md 2>/dev/null | wc -l)
    local adrs=$(ls "$PROJECT_ROOT/docs/architecture/ADRs/"*.md 2>/dev/null | wc -l)
    
    echo "├─ Vision Documents: $vision_docs"
    echo "├─ Logical Architecture: $logical_docs"
    echo "├─ Physical Architecture: $physical_docs"
    echo "└─ ADRs: $adrs"
}

# Recent quality events
show_recent_events() {
    echo ""
    echo -e "${MAGENTA}📅 RECENT QUALITY EVENTS${NC}"
    
    if [ -f "$QUALITY_LOG" ]; then
        tail -5 "$QUALITY_LOG" 2>/dev/null | while IFS= read -r line; do
            if [[ $line == *"PASSED"* ]]; then
                echo "├─ ${GREEN}✓${NC} ${line#*]}"
            elif [[ $line == *"FAILED"* ]]; then
                echo "├─ ${RED}✗${NC} ${line#*]}"
            elif [[ $line == *"OVERRIDE"* ]]; then
                echo "├─ ${YELLOW}⚠${NC} ${line#*]}"
            else
                echo "├─ ${line#*]}"
            fi
        done | sed '$d'
        
        tail -1 "$QUALITY_LOG" 2>/dev/null | while IFS= read -r line; do
            if [[ $line == *"PASSED"* ]]; then
                echo "└─ ${GREEN}✓${NC} ${line#*]}"
            elif [[ $line == *"FAILED"* ]]; then
                echo "└─ ${RED}✗${NC} ${line#*]}"
            elif [[ $line == *"OVERRIDE"* ]]; then
                echo "└─ ${YELLOW}⚠${NC} ${line#*]}"
            else
                echo "└─ ${line#*]}"
            fi
        done
    else
        echo "└─ No events logged"
    fi
}

# Health indicators
show_health_indicators() {
    echo ""
    echo -e "${GREEN}🏥 HEALTH INDICATORS${NC}"
    
    # Calculate overall health score
    local health_score=100
    local indicators=""
    
    # Check for failed gates
    if [ -f "$QUALITY_LOG" ]; then
        local recent_failures=$(tail -20 "$QUALITY_LOG" 2>/dev/null | grep -c "FAILED:" || echo "0")
        if [ "$recent_failures" -gt 2 ]; then
            health_score=$((health_score - 20))
            indicators="${indicators}├─ ${RED}⚠ High failure rate detected${NC}\n"
        fi
    fi
    
    # Check for TODOs
    local todos=$(grep -r "TODO" "$PROJECT_ROOT" --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l)
    if [ "$todos" -gt 20 ]; then
        health_score=$((health_score - 10))
        indicators="${indicators}├─ ${YELLOW}⚠ High TODO count ($todos)${NC}\n"
    fi
    
    # Check for recent commits  
    local days_since_commit=$(git log -1 --format=%cr 2>/dev/null | grep -o '^[0-9]*' | head -1)
    days_since_commit=${days_since_commit:-0}
    if [ "$days_since_commit" -gt 3 ]; then
        health_score=$((health_score - 15))
        indicators="${indicators}├─ ${YELLOW}⚠ No commits in $days_since_commit days${NC}\n"
    fi
    
    # Display health score
    if [ "$health_score" -ge 80 ]; then
        echo "├─ Overall Health: ${GREEN}●●●●●${NC} Excellent ($health_score%)"
    elif [ "$health_score" -ge 60 ]; then
        echo "├─ Overall Health: ${YELLOW}●●●○○${NC} Good ($health_score%)"
    else
        echo "├─ Overall Health: ${RED}●●○○○${NC} Needs Attention ($health_score%)"
    fi
    
    if [ -n "$indicators" ]; then
        echo -e "$indicators" | sed '$d'
    fi
    
    echo "└─ Last Check: $(date '+%H:%M:%S')"
}

# Main dashboard display
main() {
    case "$1" in
        "--watch"|"-w")
            # Continuous monitoring mode
            while true; do
                show_header
                calculate_velocity
                show_active_features
                show_gate_compliance
                show_code_quality
                show_architecture_compliance
                show_recent_events
                show_health_indicators
                
                echo ""
                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo "Press Ctrl+C to exit | Refreshing in 10 seconds..."
                sleep 10
            done
            ;;
        *)
            # Single display
            show_header
            calculate_velocity
            show_active_features
            show_gate_compliance
            show_code_quality
            show_architecture_compliance
            show_recent_events
            show_health_indicators
            
            echo ""
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo "Tip: Use '$0 --watch' for continuous monitoring"
            ;;
    esac
}

main "$@"