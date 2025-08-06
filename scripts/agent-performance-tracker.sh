#!/bin/bash

# Agent Performance Tracker
# Monitors and records agent execution metrics to SQLite database

set -e

# Configuration
DB_PATH="${AGENT_EXCELLENCE_DB:-$HOME/GitHub/ClaudeProjects2/.cpdm/agent-excellence/database/agent-excellence.db}"
METRICS_DIR="${METRICS_DIR:-$HOME/GitHub/ClaudeProjects2/.cpdm/agent-excellence/metrics}"
LOG_FILE="${METRICS_DIR}/performance.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure directories exist
mkdir -p "$METRICS_DIR"

# Function to log messages
log_message() {
    local level=$1
    shift
    echo -e "${!level}[$level]${NC} $*" | tee -a "$LOG_FILE"
}

# Function to record agent execution
record_execution() {
    local agent_name=$1
    local task_id=$2
    local execution_time=$3
    local success=$4
    local error_message=${5:-""}
    local task_context=${6:-"{}"}
    local tools_used=${7:-"[]"}
    
    # Calculate memory usage (simplified)
    local memory_usage=$(ps aux | grep -E "(claude|agent)" | awk '{sum+=$6} END {print sum/1024}')
    
    # Insert into database
    sqlite3 "$DB_PATH" <<EOF
INSERT INTO agent_metrics (
    agent_name,
    task_id,
    execution_time_ms,
    memory_usage_mb,
    success,
    error_message,
    task_context,
    tools_used
) VALUES (
    '$agent_name',
    '$task_id',
    $execution_time,
    ${memory_usage:-0},
    $success,
    '$error_message',
    '$task_context',
    '$tools_used'
);
EOF
    
    log_message GREEN "Recorded execution for $agent_name (task: $task_id, time: ${execution_time}ms, success: $success)"
}

# Function to track agent failure
track_failure() {
    local agent_name=$1
    local error_message=$2
    local context=${3:-"{}"}
    local task_id=${4:-""}
    
    # Check if similar failure exists
    local existing=$(sqlite3 "$DB_PATH" "SELECT id, frequency FROM agent_failures WHERE agent_name='$agent_name' AND error_message='$error_message' AND resolved=0 LIMIT 1;")
    
    if [ -n "$existing" ]; then
        local failure_id=$(echo "$existing" | cut -d'|' -f1)
        local frequency=$(echo "$existing" | cut -d'|' -f2)
        frequency=$((frequency + 1))
        
        sqlite3 "$DB_PATH" <<EOF
UPDATE agent_failures 
SET frequency = $frequency,
    last_occurrence = CURRENT_TIMESTAMP
WHERE id = $failure_id;
EOF
        log_message YELLOW "Updated failure frequency for $agent_name (count: $frequency)"
    else
        sqlite3 "$DB_PATH" <<EOF
INSERT INTO agent_failures (
    agent_name,
    task_id,
    error_message,
    context
) VALUES (
    '$agent_name',
    '$task_id',
    '$error_message',
    '$context'
);
EOF
        log_message RED "Tracked new failure for $agent_name: $error_message"
    fi
}

# Function to calculate agent metrics summary
calculate_summary() {
    local agent_name=${1:-""}
    local period=${2:-"1 day"}
    
    local where_clause=""
    if [ -n "$agent_name" ]; then
        where_clause="AND agent_name='$agent_name'"
    fi
    
    sqlite3 "$DB_PATH" <<EOF
INSERT OR REPLACE INTO metrics_summary (
    agent_name,
    period_start,
    period_end,
    total_executions,
    successful_executions,
    failed_executions,
    avg_execution_time_ms,
    avg_memory_usage_mb,
    success_rate,
    unique_errors
)
SELECT 
    agent_name,
    datetime('now', '-$period') as period_start,
    datetime('now') as period_end,
    COUNT(*) as total_executions,
    SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) as successful_executions,
    SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) as failed_executions,
    AVG(execution_time_ms) as avg_execution_time_ms,
    AVG(memory_usage_mb) as avg_memory_usage_mb,
    (SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) as success_rate,
    COUNT(DISTINCT CASE WHEN success = 0 THEN error_message END) as unique_errors
FROM agent_metrics
WHERE timestamp > datetime('now', '-$period')
$where_clause
GROUP BY agent_name;
EOF
    
    log_message BLUE "Calculated metrics summary for period: $period"
}

# Function to get agent performance report
performance_report() {
    local agent_name=${1:-""}
    
    echo -e "${BLUE}=== Agent Performance Report ===${NC}"
    
    if [ -n "$agent_name" ]; then
        sqlite3 -header -column "$DB_PATH" <<EOF
SELECT 
    name as Agent,
    version as Version,
    printf('%.0f', total_executions) as Executions,
    printf('%.2f', avg_execution_time) as 'Avg Time (ms)',
    printf('%.1f%%', success_rate) as 'Success Rate',
    datetime(last_execution, 'localtime') as 'Last Run'
FROM v_agent_performance
WHERE name = '$agent_name';
EOF
    else
        sqlite3 -header -column "$DB_PATH" <<EOF
SELECT 
    name as Agent,
    version as Ver,
    printf('%.0f', total_executions) as Exec,
    printf('%.0f', avg_execution_time) as 'Time(ms)',
    printf('%.1f%%', success_rate) as Success,
    datetime(last_execution, 'localtime') as 'Last Run'
FROM v_agent_performance
ORDER BY success_rate ASC, avg_execution_time DESC
LIMIT 10;
EOF
    fi
}

# Function to identify improvement candidates
identify_candidates() {
    echo -e "${YELLOW}=== Improvement Candidates ===${NC}"
    
    sqlite3 -header -column "$DB_PATH" <<EOF
SELECT 
    a.agent_name as Agent,
    COUNT(*) as Failures,
    printf('%.1f%%', (COUNT(*) * 100.0 / 
        (SELECT COUNT(*) FROM agent_metrics WHERE agent_name = a.agent_name))) as 'Failure Rate',
    a.error_message as 'Common Error'
FROM agent_failures a
WHERE a.resolved = 0
GROUP BY a.agent_name
HAVING COUNT(*) >= 3
ORDER BY COUNT(*) DESC;
EOF
}

# Function to monitor real-time metrics
monitor_realtime() {
    local refresh_interval=${1:-5}
    
    log_message BLUE "Starting real-time monitoring (refresh: ${refresh_interval}s)"
    
    while true; do
        clear
        echo -e "${GREEN}=== Real-Time Agent Metrics ===${NC}"
        echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        
        # Show recent executions
        sqlite3 -header -column "$DB_PATH" <<EOF
SELECT 
    datetime(timestamp, 'localtime') as Time,
    agent_name as Agent,
    printf('%.0f', execution_time_ms) as 'Time(ms)',
    CASE WHEN success = 1 THEN '✓' ELSE '✗' END as Status,
    SUBSTR(error_message, 1, 30) as Error
FROM agent_metrics
ORDER BY timestamp DESC
LIMIT 10;
EOF
        
        echo ""
        performance_report
        
        sleep "$refresh_interval"
    done
}

# Main command processing
case "${1:-help}" in
    record)
        shift
        record_execution "$@"
        ;;
    
    failure)
        shift
        track_failure "$@"
        ;;
    
    summary)
        calculate_summary "$2" "${3:-1 day}"
        ;;
    
    report)
        performance_report "$2"
        ;;
    
    candidates)
        identify_candidates
        ;;
    
    monitor)
        monitor_realtime "${2:-5}"
        ;;
    
    init)
        # Register all existing agents
        for agent_file in ~/GitHub/ClaudeProjects2/agents/**/*.md; do
            if [ -f "$agent_file" ]; then
                agent_name=$(basename "$agent_file" .md)
                sqlite3 "$DB_PATH" "INSERT OR IGNORE INTO agents (name, version, description) VALUES ('$agent_name', '1.0.0', 'Auto-registered agent');"
            fi
        done
        log_message GREEN "Initialized agent registry"
        ;;
    
    *)
        echo "Agent Performance Tracker"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  record <agent> <task_id> <time_ms> <success> [error] [context] [tools]"
        echo "    Record agent execution metrics"
        echo ""
        echo "  failure <agent> <error> [context] [task_id]"
        echo "    Track agent failure for learning"
        echo ""
        echo "  summary [agent] [period]"
        echo "    Calculate metrics summary (period: '1 day', '1 week', etc)"
        echo ""
        echo "  report [agent]"
        echo "    Show performance report"
        echo ""
        echo "  candidates"
        echo "    Identify agents needing improvement"
        echo ""
        echo "  monitor [interval]"
        echo "    Real-time metrics monitoring"
        echo ""
        echo "  init"
        echo "    Initialize agent registry"
        ;;
esac