#!/bin/bash
# Dynamic Optimizer for Agent Intelligence
# Sprint 9, Day 7: Real-time team adjustment and optimization

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
CONTEXT_DB="$PROJECT_ROOT/.cpdm/context/contexts.db"
LEARNING_DB="$PROJECT_ROOT/.cpdm/intelligence/learning.db"
OPTIMIZER_DB="$PROJECT_ROOT/.cpdm/intelligence/optimizer.db"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Initialize optimizer database
init_optimizer_db() {
    mkdir -p "$(dirname "$OPTIMIZER_DB")"
    
    sqlite3 "$OPTIMIZER_DB" <<'SQL'
-- Agent availability tracking
CREATE TABLE IF NOT EXISTS agent_availability (
    agent_name TEXT PRIMARY KEY,
    status TEXT DEFAULT 'idle',  -- idle, busy, overloaded, offline
    current_load INTEGER DEFAULT 0,
    max_capacity INTEGER DEFAULT 3,
    current_tasks TEXT,  -- JSON array of task IDs
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dynamic team adjustments
CREATE TABLE IF NOT EXISTS team_adjustments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    context_id TEXT,
    original_team TEXT,
    adjusted_team TEXT,
    reason TEXT,
    performance_delta REAL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Resource predictions
CREATE TABLE IF NOT EXISTS resource_predictions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    next_hour_load INTEGER,
    predicted_agents_needed TEXT,
    confidence REAL,
    actual_load INTEGER,
    accuracy REAL
);

-- Adaptive strategies
CREATE TABLE IF NOT EXISTS adaptive_strategies (
    strategy_name TEXT PRIMARY KEY,
    conditions TEXT,  -- JSON conditions
    actions TEXT,     -- JSON actions
    success_count INTEGER DEFAULT 0,
    failure_count INTEGER DEFAULT 0,
    effectiveness REAL DEFAULT 0.5,
    last_applied TIMESTAMP
);

-- Load distribution history
CREATE TABLE IF NOT EXISTS load_distribution (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    agent_loads TEXT,  -- JSON object
    balance_score REAL,
    total_capacity INTEGER,
    total_load INTEGER
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_availability_status ON agent_availability(status);
CREATE INDEX IF NOT EXISTS idx_adjustments_context ON team_adjustments(context_id);
CREATE INDEX IF NOT EXISTS idx_predictions_time ON resource_predictions(timestamp);
SQL
    
    # Initialize agent availability from existing agents
    sqlite3 "$CONTEXT_DB" "SELECT DISTINCT name FROM agents;" | while read -r agent; do
        sqlite3 "$OPTIMIZER_DB" <<SQL
INSERT OR IGNORE INTO agent_availability (agent_name) VALUES ('$agent');
SQL
    done
    
    echo -e "${GREEN}Optimizer database initialized${NC}"
}

# Monitor running operations
monitor_operations() {
    echo -e "${CYAN}=== Real-Time Operation Monitor ===${NC}\n"
    
    # Update agent availability based on current operations
    while IFS='|' read -r agent task_count avg_time; do
        local status="idle"
        if [ "$task_count" -ge 3 ]; then
            status="overloaded"
        elif [ "$task_count" -ge 1 ]; then
            status="busy"
        fi
        
        sqlite3 "$OPTIMIZER_DB" <<UPDATE
UPDATE agent_availability 
SET status = '$status',
    current_load = $task_count,
    last_updated = CURRENT_TIMESTAMP
WHERE agent_name = '$agent';
UPDATE
    done < <(sqlite3 "$CONTEXT_DB" <<'SQL'
SELECT 
    p.agent_id,
    COUNT(*) as active_tasks,
    AVG(p.duration_ms) as avg_duration
FROM performance_metrics p
JOIN contexts c ON p.context_id = c.id
WHERE c.status = 'active'
GROUP BY p.agent_id;
SQL
    )
    
    # Display current status
    echo -e "${BLUE}Agent Availability:${NC}"
    sqlite3 -column -header "$OPTIMIZER_DB" <<SQL
SELECT 
    agent_name as Agent,
    status as Status,
    current_load || '/' || max_capacity as Load,
    CASE status
        WHEN 'idle' THEN '🟢'
        WHEN 'busy' THEN '🟡'
        WHEN 'overloaded' THEN '🔴'
        ELSE '⚫'
    END as Indicator
FROM agent_availability
ORDER BY current_load DESC;
SQL
}

# Adjust team in real-time
adjust_team() {
    local context_id="$1"
    local current_team="$2"
    
    echo -e "${BLUE}Analyzing team for adjustment...${NC}"
    
    # Check if any agents are overloaded
    local overloaded_agents=$(sqlite3 -separator ',' "$OPTIMIZER_DB" <<SQL
SELECT agent_name 
FROM agent_availability 
WHERE status = 'overloaded' 
  AND agent_name IN ($(echo "$current_team" | sed "s/,/','/g" | sed "s/^/'/" | sed "s/$/'/"));
SQL
    )
    
    if [ -n "$overloaded_agents" ]; then
        echo -e "${YELLOW}Overloaded agents detected: $overloaded_agents${NC}"
        
        # Find replacement agents
        local adjusted_team="$current_team"
        
        echo "$overloaded_agents" | tr ',' '\n' | while read -r overloaded; do
            # Find similar idle agent
            local replacement=$(sqlite3 "$OPTIMIZER_DB" <<SQL
SELECT agent_name
FROM agent_availability
WHERE status = 'idle'
  AND agent_name != '$overloaded'
LIMIT 1;
SQL
            )
            
            if [ -n "$replacement" ]; then
                adjusted_team=$(echo "$adjusted_team" | sed "s/$overloaded/$replacement/g")
                echo -e "${GREEN}Replacing $overloaded with $replacement${NC}"
                
                # Record adjustment
                sqlite3 "$OPTIMIZER_DB" <<SQL
INSERT INTO team_adjustments 
(context_id, original_team, adjusted_team, reason)
VALUES 
('$context_id', '$current_team', '$adjusted_team', 'Agent $overloaded overloaded');
SQL
            fi
        done
        
        echo -e "${GREEN}Adjusted team: $adjusted_team${NC}"
        echo "$adjusted_team"
    else
        echo -e "${GREEN}Team is optimal, no adjustment needed${NC}"
        echo "$current_team"
    fi
}

# Load balancer
balance_load() {
    echo -e "${BLUE}Balancing load across agents...${NC}"
    
    # Calculate current load distribution
    local total_load=$(sqlite3 "$OPTIMIZER_DB" \
        "SELECT SUM(current_load) FROM agent_availability;")
    local total_capacity=$(sqlite3 "$OPTIMIZER_DB" \
        "SELECT SUM(max_capacity) FROM agent_availability;")
    
    local utilization=$(echo "scale=2; $total_load * 100 / $total_capacity" | bc)
    
    echo -e "${YELLOW}System Utilization: ${utilization}%${NC}"
    
    # Identify imbalances
    sqlite3 -column -header "$OPTIMIZER_DB" <<SQL
SELECT 
    agent_name as Agent,
    current_load as Load,
    max_capacity as Capacity,
    ROUND(100.0 * current_load / max_capacity, 1) as 'Utilization %'
FROM agent_availability
WHERE current_load > 0
ORDER BY current_load / CAST(max_capacity AS REAL) DESC;
SQL
    
    # Suggest rebalancing if needed
    local max_util=$(sqlite3 "$OPTIMIZER_DB" \
        "SELECT MAX(100.0 * current_load / max_capacity) FROM agent_availability;")
    local min_util=$(sqlite3 "$OPTIMIZER_DB" \
        "SELECT MIN(100.0 * current_load / max_capacity) FROM agent_availability WHERE current_load > 0;")
    
    local imbalance=$(echo "$max_util - $min_util" | bc)
    
    if (( $(echo "$imbalance > 50" | bc -l) )); then
        echo -e "\n${YELLOW}⚠️  High imbalance detected: ${imbalance}%${NC}"
        echo -e "${YELLOW}Recommendation: Redistribute tasks from overloaded to idle agents${NC}"
        
        # Suggest specific redistributions
        echo -e "\n${BLUE}Suggested Redistributions:${NC}"
        sqlite3 "$OPTIMIZER_DB" <<SQL
SELECT 
    'Move tasks from ' || o.agent_name || ' to ' || i.agent_name as Suggestion
FROM 
    (SELECT agent_name FROM agent_availability WHERE status = 'overloaded') o,
    (SELECT agent_name FROM agent_availability WHERE status = 'idle' LIMIT 1) i
LIMIT 3;
SQL
    else
        echo -e "\n${GREEN}✓ Load is well balanced${NC}"
    fi
    
    # Record distribution
    local agent_loads=$(sqlite3 -json "$OPTIMIZER_DB" \
        "SELECT agent_name, current_load FROM agent_availability;")
    
    sqlite3 "$OPTIMIZER_DB" <<SQL
INSERT INTO load_distribution 
(agent_loads, balance_score, total_capacity, total_load)
VALUES 
('$agent_loads', ${imbalance:-0}, $total_capacity, $total_load);
SQL
}

# Predict resource needs
predict_resources() {
    local hours_ahead="${1:-1}"
    
    echo -e "${BLUE}Predicting resource needs for next $hours_ahead hour(s)...${NC}"
    
    # Analyze historical patterns
    local current_hour=$(date +%H)
    local next_hour=$(( (current_hour + hours_ahead) % 24 ))
    
    # Get historical load for this time
    local avg_load=$(sqlite3 "$CONTEXT_DB" <<SQL
SELECT COALESCE(AVG(task_count), 5) as avg_load
FROM (
    SELECT COUNT(*) as task_count
    FROM performance_metrics
    WHERE CAST(strftime('%H', timestamp) AS INTEGER) = $next_hour
    GROUP BY date(timestamp)
) t;
SQL
    )
    
    avg_load=$(printf "%.0f" "$avg_load")
    
    # Calculate agents needed
    local avg_capacity=3
    local agents_needed=$(( (avg_load + avg_capacity - 1) / avg_capacity ))
    
    echo -e "${YELLOW}Predicted load: $avg_load tasks${NC}"
    echo -e "${YELLOW}Agents needed: $agents_needed${NC}"
    
    # Identify which agents to pre-allocate
    local recommended_agents=$(sqlite3 -separator ',' "$LEARNING_DB" <<SQL
SELECT agent_name
FROM agent_features
WHERE success_rate > 90
ORDER BY avg_response_time ASC
LIMIT $agents_needed;
SQL
    )
    
    echo -e "\n${GREEN}Recommended agent allocation:${NC}"
    echo "$recommended_agents" | tr ',' '\n' | while read -r agent; do
        echo "  • $agent"
    done
    
    # Store prediction
    sqlite3 "$OPTIMIZER_DB" <<SQL
INSERT INTO resource_predictions 
(next_hour_load, predicted_agents_needed, confidence)
VALUES 
($avg_load, '$recommended_agents', 0.75);
SQL
    
    # Check accuracy of past predictions
    echo -e "\n${BLUE}Past Prediction Accuracy:${NC}"
    sqlite3 -column -header "$OPTIMIZER_DB" <<SQL
SELECT 
    datetime(timestamp, 'localtime') as Time,
    next_hour_load as Predicted,
    COALESCE(actual_load, '-') as Actual,
    CASE 
        WHEN accuracy IS NOT NULL THEN ROUND(accuracy, 1) || '%'
        ELSE 'Pending'
    END as Accuracy
FROM resource_predictions
ORDER BY timestamp DESC
LIMIT 5;
SQL
}

# Adaptive strategy engine
apply_adaptive_strategy() {
    local context_id="$1"
    local task_type="$2"
    
    echo -e "${BLUE}Applying adaptive strategies...${NC}"
    
    # Check current conditions
    local system_load=$(sqlite3 "$OPTIMIZER_DB" \
        "SELECT ROUND(100.0 * SUM(current_load) / SUM(max_capacity), 1) 
         FROM agent_availability;")
    
    local strategy=""
    local actions=""
    
    # Select strategy based on conditions
    if (( $(echo "$system_load > 80" | bc -l) )); then
        strategy="high-load"
        actions='{"parallel": false, "timeout": 10000, "retry": 1}'
        echo -e "${YELLOW}High load strategy: Sequential execution, extended timeout${NC}"
    elif (( $(echo "$system_load < 30" | bc -l) )); then
        strategy="low-load"
        actions='{"parallel": true, "timeout": 5000, "retry": 3}'
        echo -e "${GREEN}Low load strategy: Parallel execution, aggressive retry${NC}"
    else
        strategy="balanced"
        actions='{"parallel": true, "timeout": 7500, "retry": 2}'
        echo -e "${BLUE}Balanced strategy: Standard execution${NC}"
    fi
    
    # Record strategy application
    sqlite3 "$OPTIMIZER_DB" <<SQL
INSERT OR REPLACE INTO adaptive_strategies 
(strategy_name, conditions, actions, last_applied)
VALUES 
('$strategy', '{"system_load": $system_load}', '$actions', CURRENT_TIMESTAMP);
SQL
    
    # Return strategy actions
    echo "$actions"
}

# Optimize running tasks
optimize_running() {
    echo -e "${CYAN}=== Optimizing Running Tasks ===${NC}\n"
    
    # Find slow-running tasks
    while IFS='|' read -r context_id agent duration; do
        echo -e "${YELLOW}Slow task detected:${NC}"
        echo "  Context: $context_id"
        echo "  Agent: $agent"
        echo "  Duration: ${duration}ms"
        
        # Check if we can parallelize
        if [ "$duration" -gt 5000 ]; then
            echo -e "  ${GREEN}→ Recommendation: Add parallel agent${NC}"
            
            # Find helper agent
            local helper=$(sqlite3 "$OPTIMIZER_DB" \
                "SELECT agent_name FROM agent_availability 
                 WHERE status = 'idle' AND agent_name != '$agent' LIMIT 1;")
            
            if [ -n "$helper" ]; then
                echo -e "  ${GREEN}→ Available helper: $helper${NC}"
            fi
        fi
        echo ""
    done < <(sqlite3 "$CONTEXT_DB" <<'SQL'
SELECT 
    c.id,
    p.agent_id,
    p.duration_ms
FROM contexts c
JOIN performance_metrics p ON c.id = p.context_id
WHERE c.status = 'active'
  AND p.duration_ms > 3000
ORDER BY p.duration_ms DESC
LIMIT 5;
SQL
    )
}

# Generate optimization report
generate_report() {
    echo -e "${MAGENTA}=== DYNAMIC OPTIMIZATION REPORT ===${NC}\n"
    
    # System overview
    echo -e "${BLUE}System Status:${NC}"
    local total_agents=$(sqlite3 "$OPTIMIZER_DB" "SELECT COUNT(*) FROM agent_availability;")
    local idle=$(sqlite3 "$OPTIMIZER_DB" "SELECT COUNT(*) FROM agent_availability WHERE status='idle';")
    local busy=$(sqlite3 "$OPTIMIZER_DB" "SELECT COUNT(*) FROM agent_availability WHERE status='busy';")
    local overloaded=$(sqlite3 "$OPTIMIZER_DB" "SELECT COUNT(*) FROM agent_availability WHERE status='overloaded';")
    
    echo "  Total Agents: $total_agents"
    echo "  🟢 Idle: $idle"
    echo "  🟡 Busy: $busy"
    echo "  🔴 Overloaded: $overloaded"
    
    # Recent adjustments
    echo -e "\n${BLUE}Recent Team Adjustments:${NC}"
    sqlite3 -column -header "$OPTIMIZER_DB" <<SQL
SELECT 
    datetime(timestamp, 'localtime') as Time,
    substr(original_team, 1, 20) as Original,
    substr(adjusted_team, 1, 20) as Adjusted,
    substr(reason, 1, 30) as Reason
FROM team_adjustments
ORDER BY timestamp DESC
LIMIT 5;
SQL
    
    # Load balance history
    echo -e "\n${BLUE}Load Balance Trend:${NC}"
    sqlite3 -column -header "$OPTIMIZER_DB" <<SQL
SELECT 
    datetime(timestamp, 'localtime') as Time,
    total_load || '/' || total_capacity as 'Load/Capacity',
    ROUND(100.0 * total_load / total_capacity, 1) || '%' as Utilization,
    ROUND(balance_score, 1) as 'Imbalance %'
FROM load_distribution
ORDER BY timestamp DESC
LIMIT 5;
SQL
    
    # Strategy effectiveness
    echo -e "\n${BLUE}Strategy Effectiveness:${NC}"
    sqlite3 -column -header "$OPTIMIZER_DB" <<SQL
SELECT 
    strategy_name as Strategy,
    success_count as Successes,
    failure_count as Failures,
    ROUND(100.0 * success_count / NULLIF(success_count + failure_count, 0), 1) || '%' as 'Success Rate'
FROM adaptive_strategies
ORDER BY success_count + failure_count DESC;
SQL
}

# Main command handler
case "${1:-help}" in
    init)
        init_optimizer_db
        ;;
    monitor)
        monitor_operations
        ;;
    adjust)
        adjust_team "$2" "$3"
        ;;
    balance)
        balance_load
        ;;
    predict)
        predict_resources "${2:-1}"
        ;;
    strategy)
        apply_adaptive_strategy "$2" "$3"
        ;;
    optimize)
        optimize_running
        ;;
    report)
        generate_report
        ;;
    watch)
        # Continuous monitoring
        while true; do
            clear
            monitor_operations
            echo -e "\n${YELLOW}Refreshing every 5 seconds... (Ctrl+C to exit)${NC}"
            sleep 5
        done
        ;;
    help|*)
        echo "Dynamic Optimizer for Agent Intelligence"
        echo "Usage: $0 <command> [args...]"
        echo ""
        echo "Commands:"
        echo "  init                      - Initialize optimizer database"
        echo "  monitor                   - Monitor current operations"
        echo "  adjust <ctx> <team>       - Adjust team in real-time"
        echo "  balance                   - Balance load across agents"
        echo "  predict [hours]           - Predict resource needs"
        echo "  strategy <ctx> <type>     - Apply adaptive strategy"
        echo "  optimize                  - Optimize running tasks"
        echo "  report                    - Generate optimization report"
        echo "  watch                     - Continuous monitoring mode"
        ;;
esac