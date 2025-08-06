#!/bin/bash

# Agent Analyzer Module
# Analyzes agent performance metrics and identifies improvement opportunities

set -e

# Configuration
DB_PATH="${AGENT_EXCELLENCE_DB:-$HOME/GitHub/ClaudeProjects2/.cpdm/agent-excellence/database/agent-excellence.db}"
LEARNING_REPO="${LEARNING_REPO:-$HOME/GitHub/ClaudeProjects2/.cpdm/agent-excellence/learning-repository}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/GitHub/ClaudeProjects2/.cpdm/agent-excellence/improvements}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Function to analyze agent performance
analyze_agent() {
    local agent_name=$1
    local period=${2:-"7 days"}
    
    echo -e "${BLUE}Analyzing agent: $agent_name${NC}"
    
    # Get performance metrics
    local metrics=$(sqlite3 "$DB_PATH" <<EOF
SELECT 
    COUNT(*) as total_executions,
    AVG(execution_time_ms) as avg_time,
    MAX(execution_time_ms) as max_time,
    MIN(execution_time_ms) as min_time,
    SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as success_rate,
    COUNT(DISTINCT error_message) as unique_errors
FROM agent_metrics
WHERE agent_name = '$agent_name'
AND timestamp > datetime('now', '-$period');
EOF
)
    
    # Get failure patterns
    local failures=$(sqlite3 "$DB_PATH" <<EOF
SELECT 
    error_message,
    COUNT(*) as frequency,
    MAX(last_occurrence) as last_seen
FROM agent_failures
WHERE agent_name = '$agent_name'
AND resolved = 0
GROUP BY error_message
ORDER BY frequency DESC
LIMIT 5;
EOF
)
    
    # Generate analysis report
    local report_file="$OUTPUT_DIR/${agent_name}_analysis_$(date +%Y%m%d_%H%M%S).json"
    
    cat > "$report_file" <<EOF
{
    "agent_name": "$agent_name",
    "analysis_date": "$(date -Iseconds)",
    "period": "$period",
    "metrics": {
        $(echo "$metrics" | awk -F'|' '{
            printf "\"total_executions\": %s,\n", $1
            printf "        \"avg_execution_time_ms\": %.2f,\n", $2
            printf "        \"max_execution_time_ms\": %.2f,\n", $3
            printf "        \"min_execution_time_ms\": %.2f,\n", $4
            printf "        \"success_rate\": %.2f,\n", $5
            printf "        \"unique_error_count\": %s", $6
        }')
    },
    "improvement_opportunities": [
EOF
    
    # Identify improvement opportunities
    local opportunities=""
    
    # Check for performance issues
    if [[ $(echo "$metrics" | cut -d'|' -f2) > 5000 ]]; then
        opportunities="${opportunities}        {\"type\": \"performance\", \"issue\": \"High average execution time\", \"priority\": \"high\"},\n"
    fi
    
    # Check for reliability issues
    local success_rate=$(echo "$metrics" | cut -d'|' -f5)
    if (( $(echo "$success_rate < 80" | bc -l) )); then
        opportunities="${opportunities}        {\"type\": \"reliability\", \"issue\": \"Low success rate\", \"priority\": \"critical\"},\n"
    fi
    
    # Check for recurring failures
    if [[ -n "$failures" ]]; then
        opportunities="${opportunities}        {\"type\": \"error_handling\", \"issue\": \"Recurring failures detected\", \"priority\": \"high\"},\n"
    fi
    
    # Remove trailing comma and close JSON
    if [[ -n "$opportunities" ]]; then
        echo -e "${opportunities%,*}" >> "$report_file"
    fi
    
    cat >> "$report_file" <<EOF
    ],
    "recommended_patterns": [
EOF
    
    # Recommend applicable patterns based on issues
    if [[ $(echo "$metrics" | cut -d'|' -f2) > 5000 ]]; then
        echo '        {"pattern": "parallel-execution", "confidence": 0.85},' >> "$report_file"
    fi
    
    if (( $(echo "$success_rate < 80" | bc -l) )); then
        echo '        {"pattern": "retry-with-backoff", "confidence": 0.90}' >> "$report_file"
    else
        echo '        {"pattern": "none", "confidence": 0.0}' >> "$report_file"
    fi
    
    cat >> "$report_file" <<EOF
    ]
}
EOF
    
    echo -e "${GREEN}Analysis complete: $report_file${NC}"
    echo "$report_file"
}

# Function to analyze all agents
analyze_all() {
    echo -e "${BLUE}Analyzing all registered agents...${NC}"
    
    local agents=$(sqlite3 "$DB_PATH" "SELECT DISTINCT name FROM agents WHERE status='active';")
    
    for agent in $agents; do
        analyze_agent "$agent" "$1"
    done
}

# Function to identify top improvement candidates
identify_candidates() {
    local threshold=${1:-70}
    
    echo -e "${YELLOW}Identifying improvement candidates (success rate < ${threshold}%)${NC}"
    
    sqlite3 -header -column "$DB_PATH" <<EOF
SELECT 
    a.name as Agent,
    a.version as Version,
    printf('%.1f%%', ms.success_rate) as 'Success Rate',
    printf('%.0f', ms.avg_execution_time_ms) as 'Avg Time (ms)',
    ms.unique_errors as 'Unique Errors',
    CASE 
        WHEN ms.success_rate < 50 THEN 'CRITICAL'
        WHEN ms.success_rate < 70 THEN 'HIGH'
        WHEN ms.avg_execution_time_ms > 10000 THEN 'MEDIUM'
        ELSE 'LOW'
    END as Priority
FROM agents a
JOIN metrics_summary ms ON a.name = ms.agent_name
WHERE ms.success_rate < $threshold
   OR ms.avg_execution_time_ms > 10000
ORDER BY ms.success_rate ASC, ms.avg_execution_time_ms DESC;
EOF
}

# Function to generate improvement recommendations
generate_recommendations() {
    local agent_name=$1
    local analysis_file=$2
    
    echo -e "${BLUE}Generating recommendations for $agent_name${NC}"
    
    # Extract issues from analysis
    local issues=$(jq -r '.improvement_opportunities[].type' "$analysis_file" 2>/dev/null)
    
    local recommendations=""
    
    for issue in $issues; do
        case "$issue" in
            performance)
                recommendations="${recommendations}- Implement parallel execution for file operations\n"
                recommendations="${recommendations}- Add caching for frequently accessed data\n"
                recommendations="${recommendations}- Optimize database queries with indexes\n"
                ;;
            reliability)
                recommendations="${recommendations}- Add retry logic with exponential backoff\n"
                recommendations="${recommendations}- Implement proper error handling\n"
                recommendations="${recommendations}- Add input validation\n"
                ;;
            error_handling)
                recommendations="${recommendations}- Analyze and fix recurring error patterns\n"
                recommendations="${recommendations}- Add fallback mechanisms\n"
                recommendations="${recommendations}- Improve error messages for debugging\n"
                ;;
        esac
    done
    
    if [[ -n "$recommendations" ]]; then
        echo -e "${GREEN}Recommendations:${NC}"
        echo -e "$recommendations"
    else
        echo -e "${GREEN}No immediate improvements needed${NC}"
    fi
}

# Main command processing
case "${1:-help}" in
    analyze)
        analyze_agent "$2" "${3:-7 days}"
        ;;
    
    all)
        analyze_all "${2:-7 days}"
        ;;
    
    candidates)
        identify_candidates "${2:-70}"
        ;;
    
    recommend)
        if [[ -f "$3" ]]; then
            generate_recommendations "$2" "$3"
        else
            # Analyze first then recommend
            analysis=$(analyze_agent "$2" "${4:-7 days}")
            generate_recommendations "$2" "$analysis"
        fi
        ;;
    
    *)
        echo "Agent Analyzer Module"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  analyze <agent> [period]"
        echo "    Analyze specific agent performance"
        echo ""
        echo "  all [period]"
        echo "    Analyze all registered agents"
        echo ""
        echo "  candidates [threshold]"
        echo "    Identify improvement candidates (default: 70% success rate)"
        echo ""
        echo "  recommend <agent> [analysis_file] [period]"
        echo "    Generate improvement recommendations"
        echo ""
        echo "Examples:"
        echo "  $0 analyze orchestrator-agent '7 days'"
        echo "  $0 candidates 80"
        echo "  $0 recommend project-agent"
        ;;
esac