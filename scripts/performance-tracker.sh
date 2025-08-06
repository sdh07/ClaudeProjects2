#!/bin/bash
# Performance Tracking for Agent Invocations
# Sprint 8, Day 4: Track and optimize agent performance

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
CONTEXT_DB="$PROJECT_ROOT/.cpdm/context/contexts.db"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Track agent invocation start
track_start() {
    local agent="$1"
    local task_type="$2"
    local context_id="$3"
    
    local invocation_id="inv-$(date +%s)-$(uuidgen | tr '[:upper:]' '[:lower:]' | cut -c1-8)"
    
    # Record in performance_metrics
    sqlite3 "$CONTEXT_DB" <<SQL
INSERT INTO performance_metrics (
    agent_id, context_id, task_type, 
    start_time, status
) VALUES (
    '$agent', '$context_id', '$task_type',
    CURRENT_TIMESTAMP, 'running'
);
SQL
    
    echo "$invocation_id"
}

# Track agent invocation end
track_end() {
    local agent="$1"
    local context_id="$2"
    local status="$3"  # success, failure, timeout
    local response_size="${4:-0}"
    
    # Update performance_metrics
    sqlite3 "$CONTEXT_DB" <<SQL
UPDATE performance_metrics 
SET 
    end_time = CURRENT_TIMESTAMP,
    response_time = CAST((julianday(CURRENT_TIMESTAMP) - julianday(start_time)) * 86400000 AS INTEGER),
    status = '$status',
    response_size = $response_size
WHERE agent_id = '$agent' 
    AND context_id = '$context_id'
    AND status = 'running';
SQL
    
    # Calculate and update agent statistics
    update_agent_stats "$agent"
}

# Update agent performance statistics
update_agent_stats() {
    local agent="$1"
    
    # Calculate statistics
    local stats=$(sqlite3 -json "$CONTEXT_DB" <<SQL
SELECT 
    AVG(response_time) as avg_response_time,
    MIN(response_time) as min_response_time,
    MAX(response_time) as max_response_time,
    COUNT(*) as total_invocations,
    SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) as successful,
    ROUND(100.0 * SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) / COUNT(*), 2) as success_rate,
    AVG(response_size) as avg_response_size
FROM performance_metrics
WHERE agent_id = '$agent'
    AND end_time IS NOT NULL
    AND response_time > 0;
SQL
    )
    
    # Update agent record
    if [ -n "$stats" ] && [ "$stats" != "[]" ]; then
        local performance_json=$(echo "$stats" | jq '.[0]')
        
        sqlite3 "$CONTEXT_DB" <<SQL
UPDATE agents 
SET 
    performance = '$performance_json',
    last_active = CURRENT_TIMESTAMP
WHERE name = '$agent';
SQL
    fi
}

# Get agent performance report
get_performance_report() {
    local agent="${1:-all}"
    local days="${2:-7}"
    
    echo -e "${YELLOW}=== Agent Performance Report ===${NC}"
    echo -e "${BLUE}Period: Last $days days${NC}\n"
    
    if [ "$agent" = "all" ]; then
        # Overall statistics
        sqlite3 -column -header "$CONTEXT_DB" <<SQL
SELECT 
    agent_id as Agent,
    COUNT(*) as Invocations,
    ROUND(AVG(response_time), 0) as 'Avg Time (ms)',
    ROUND(100.0 * SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) / COUNT(*), 1) as 'Success %',
    ROUND(AVG(response_size), 0) as 'Avg Size'
FROM performance_metrics
WHERE datetime(start_time) > datetime('now', '-$days days')
    AND end_time IS NOT NULL
GROUP BY agent_id
ORDER BY COUNT(*) DESC;
SQL
    else
        # Specific agent statistics
        sqlite3 -column -header "$CONTEXT_DB" <<SQL
SELECT 
    task_type as 'Task Type',
    COUNT(*) as Count,
    ROUND(AVG(response_time), 0) as 'Avg Time (ms)',
    MIN(response_time) as 'Min Time',
    MAX(response_time) as 'Max Time',
    ROUND(100.0 * SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) / COUNT(*), 1) as 'Success %'
FROM performance_metrics
WHERE agent_id = '$agent'
    AND datetime(start_time) > datetime('now', '-$days days')
    AND end_time IS NOT NULL
GROUP BY task_type
ORDER BY COUNT(*) DESC;
SQL
    fi
}

# Identify slow operations
identify_bottlenecks() {
    local threshold="${1:-5000}"  # Default 5 seconds
    
    echo -e "${YELLOW}=== Performance Bottlenecks ===${NC}"
    echo -e "${BLUE}Operations slower than ${threshold}ms${NC}\n"
    
    sqlite3 -column -header "$CONTEXT_DB" <<SQL
SELECT 
    agent_id as Agent,
    task_type as Task,
    response_time as 'Time (ms)',
    datetime(start_time) as Started,
    status as Status
FROM performance_metrics
WHERE response_time > $threshold
    AND end_time IS NOT NULL
ORDER BY response_time DESC
LIMIT 20;
SQL
}

# Show currently running operations
show_running() {
    echo -e "${YELLOW}=== Currently Running Operations ===${NC}\n"
    
    sqlite3 -column -header "$CONTEXT_DB" <<SQL
SELECT 
    agent_id as Agent,
    task_type as Task,
    context_id as Context,
    CAST((julianday('now') - julianday(start_time)) * 86400 AS INTEGER) as 'Running (s)',
    datetime(start_time) as Started
FROM performance_metrics
WHERE status = 'running'
ORDER BY start_time;
SQL
}

# Performance comparison
compare_agents() {
    local domain="$1"
    
    echo -e "${YELLOW}=== Agent Performance Comparison ===${NC}"
    if [ -n "$domain" ]; then
        echo -e "${BLUE}Domain: $domain${NC}\n"
    fi
    
    local domain_filter=""
    if [ -n "$domain" ]; then
        domain_filter="AND a.capabilities LIKE '%\"$domain\"%'"
    fi
    
    sqlite3 -column -header "$CONTEXT_DB" <<SQL
SELECT 
    a.name as Agent,
    COALESCE(COUNT(p.agent_id), 0) as Tasks,
    COALESCE(ROUND(AVG(p.response_time), 0), 0) as 'Avg Time',
    COALESCE(ROUND(100.0 * SUM(CASE WHEN p.status = 'success' THEN 1 ELSE 0 END) / NULLIF(COUNT(p.agent_id), 0), 1), 100) as 'Success %',
    CASE 
        WHEN AVG(p.response_time) < 1000 THEN '⚡ Fast'
        WHEN AVG(p.response_time) < 3000 THEN '✓ Good'
        WHEN AVG(p.response_time) < 5000 THEN '⚠ Slow'
        ELSE '❌ Very Slow'
    END as Performance
FROM agents a
LEFT JOIN performance_metrics p ON a.name = p.agent_id
WHERE 1=1 $domain_filter
GROUP BY a.name
ORDER BY COALESCE(AVG(p.response_time), 999999);
SQL
}

# Predict resource needs
predict_resources() {
    local next_hours="${1:-24}"
    
    echo -e "${YELLOW}=== Resource Prediction ===${NC}"
    echo -e "${BLUE}Next $next_hours hours forecast${NC}\n"
    
    # Historical pattern analysis
    sqlite3 -column -header "$CONTEXT_DB" <<SQL
SELECT 
    strftime('%H', start_time) as Hour,
    COUNT(*) as 'Avg Tasks',
    ROUND(AVG(response_time), 0) as 'Avg Time (ms)',
    ROUND(SUM(response_time) / 1000.0, 1) as 'Total Time (s)'
FROM performance_metrics
WHERE datetime(start_time) > datetime('now', '-7 days')
GROUP BY strftime('%H', start_time)
ORDER BY Hour;
SQL
}

# Export metrics for analysis
export_metrics() {
    local output_file="${1:-metrics-export.json}"
    
    echo -e "${BLUE}Exporting metrics to $output_file...${NC}"
    
    sqlite3 -json "$CONTEXT_DB" <<SQL > "$output_file"
SELECT 
    agent_id,
    context_id,
    task_type,
    response_time,
    response_size,
    status,
    datetime(start_time) as start_time,
    datetime(end_time) as end_time
FROM performance_metrics
WHERE end_time IS NOT NULL
ORDER BY start_time DESC;
SQL
    
    echo -e "${GREEN}Exported $(wc -l < "$output_file") records${NC}"
}

# Real-time monitoring
monitor() {
    local refresh="${1:-5}"  # Refresh every 5 seconds by default
    
    while true; do
        clear
        echo -e "${YELLOW}=== Real-Time Agent Monitor ===${NC}"
        echo -e "${BLUE}$(date)${NC}\n"
        
        # Running operations
        echo -e "${GREEN}Running Operations:${NC}"
        sqlite3 -column "$CONTEXT_DB" <<SQL
SELECT 
    substr(agent_id, 1, 20) as Agent,
    substr(task_type, 1, 15) as Task,
    CAST((julianday('now') - julianday(start_time)) * 86400 AS INTEGER) || 's' as Time
FROM performance_metrics
WHERE status = 'running'
LIMIT 5;
SQL
        
        # Recent completions
        echo -e "\n${GREEN}Recent Completions:${NC}"
        sqlite3 -column "$CONTEXT_DB" <<SQL
SELECT 
    substr(agent_id, 1, 20) as Agent,
    response_time || 'ms' as Time,
    status as Status
FROM performance_metrics
WHERE end_time IS NOT NULL
ORDER BY end_time DESC
LIMIT 5;
SQL
        
        # Stats
        echo -e "\n${GREEN}Last Hour Stats:${NC}"
        sqlite3 -column "$CONTEXT_DB" <<SQL
SELECT 
    COUNT(*) as Tasks,
    ROUND(AVG(response_time), 0) || 'ms' as 'Avg Time',
    ROUND(100.0 * SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) / COUNT(*), 1) || '%' as Success
FROM performance_metrics
WHERE datetime(start_time) > datetime('now', '-1 hour')
    AND end_time IS NOT NULL;
SQL
        
        echo -e "\n${YELLOW}Refreshing in $refresh seconds... (Ctrl+C to exit)${NC}"
        sleep "$refresh"
    done
}

# Main command handler
case "${1:-help}" in
    start)
        track_start "$2" "$3" "$4"
        ;;
    end)
        track_end "$2" "$3" "$4" "$5"
        ;;
    report)
        get_performance_report "$2" "${3:-7}"
        ;;
    bottlenecks)
        identify_bottlenecks "${2:-5000}"
        ;;
    running)
        show_running
        ;;
    compare)
        compare_agents "$2"
        ;;
    predict)
        predict_resources "${2:-24}"
        ;;
    export)
        export_metrics "$2"
        ;;
    monitor)
        monitor "${2:-5}"
        ;;
    help|*)
        echo "Performance Tracker for Agent Invocations"
        echo "Usage: $0 <command> [args...]"
        echo ""
        echo "Commands:"
        echo "  start <agent> <task> <context>   - Track invocation start"
        echo "  end <agent> <context> <status>   - Track invocation end"
        echo "  report [agent] [days]             - Performance report"
        echo "  bottlenecks [threshold_ms]        - Identify slow operations"
        echo "  running                           - Show running operations"
        echo "  compare [domain]                  - Compare agent performance"
        echo "  predict [hours]                   - Predict resource needs"
        echo "  export [file]                     - Export metrics to JSON"
        echo "  monitor [refresh_sec]             - Real-time monitoring"
        ;;
esac