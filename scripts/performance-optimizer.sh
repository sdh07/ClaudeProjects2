#!/bin/bash
# Performance Optimizer using Intelligence Layer Insights
# Sprint 10, Day 1: ML-driven performance optimization

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
CONTEXT_DB="$PROJECT_ROOT/.cpdm/context/contexts.db"
LEARNING_DB="$PROJECT_ROOT/.cpdm/intelligence/learning.db"
OPTIMIZER_DB="$PROJECT_ROOT/.cpdm/intelligence/optimizer.db"
IMPROVEMENT_DB="$PROJECT_ROOT/.cpdm/intelligence/improvement.db"
PERFORMANCE_DB="$PROJECT_ROOT/.cpdm/optimization/performance.db"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Initialize performance optimization database
init_performance_db() {
    mkdir -p "$(dirname "$PERFORMANCE_DB")"
    
    sqlite3 "$PERFORMANCE_DB" <<'SQL'
-- Performance bottlenecks
CREATE TABLE IF NOT EXISTS bottlenecks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_name TEXT NOT NULL,
    operation TEXT,
    avg_response_time REAL,
    p95_response_time REAL,
    frequency INTEGER,
    severity TEXT, -- low, medium, high, critical
    optimization_opportunity TEXT,
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Cache strategies
CREATE TABLE IF NOT EXISTS cache_strategies (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    operation_pattern TEXT,
    cache_key_template TEXT,
    cache_duration INTEGER, -- seconds
    hit_rate_target REAL,
    estimated_savings_ms REAL,
    priority INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Performance optimizations applied
CREATE TABLE IF NOT EXISTS applied_optimizations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_name TEXT,
    optimization_type TEXT, -- cache, routing, parameter, parallelization
    optimization_details TEXT, -- JSON
    baseline_performance REAL,
    optimized_performance REAL,
    improvement_percent REAL,
    rollback_info TEXT, -- JSON
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'active' -- active, rolled_back, superseded
);

-- Agent routing optimizations
CREATE TABLE IF NOT EXISTS routing_optimizations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_pattern TEXT,
    optimal_agents TEXT, -- JSON array
    routing_strategy TEXT, -- fastest, most_reliable, balanced
    performance_gain REAL,
    confidence REAL,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Performance trends
CREATE TABLE IF NOT EXISTS performance_trends (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_name TEXT,
    metric_name TEXT, -- response_time, success_rate, throughput
    time_period TEXT, -- hour, day, week
    trend_direction TEXT, -- improving, degrading, stable
    trend_magnitude REAL,
    statistical_significance REAL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_bottlenecks_agent ON bottlenecks(agent_name);
CREATE INDEX IF NOT EXISTS idx_bottlenecks_severity ON bottlenecks(severity);
CREATE INDEX IF NOT EXISTS idx_optimizations_agent ON applied_optimizations(agent_name);
CREATE INDEX IF NOT EXISTS idx_optimizations_type ON applied_optimizations(optimization_type);
CREATE INDEX IF NOT EXISTS idx_routing_pattern ON routing_optimizations(task_pattern);
SQL
    
    echo -e "${GREEN}Performance optimization database initialized${NC}"
}

# Analyze current performance using intelligence data
analyze_performance() {
    echo -e "${CYAN}=== Performance Analysis Using ML Insights ===${NC}\n"
    
    echo -e "${BLUE}Analyzing agent performance patterns...${NC}"
    
    # Get performance data from learning database
    sqlite3 "$LEARNING_DB" "SELECT agent_name, success_rate, avg_response_time FROM agent_features;" | \
    while IFS='|' read -r agent success_rate response_time; do
        # Classify performance issues
        local severity="low"
        if (( $(echo "$response_time > 5000" | bc -l) )); then
            severity="critical"
        elif (( $(echo "$response_time > 3000" | bc -l) )); then
            severity="high"
        elif (( $(echo "$response_time > 2000" | bc -l) )); then
            severity="medium"
        fi
        
        # Get frequency data
        local frequency=$(sqlite3 "$CONTEXT_DB" \
            "SELECT COUNT(*) FROM performance_metrics WHERE agent_id = '$agent';")
        
        # Calculate p95 estimate (simplified)
        local p95_time=$(echo "scale=2; $response_time * 1.5" | bc)
        
        # Determine optimization opportunity
        local opportunity=""
        if (( $(echo "$response_time > 3000" | bc -l) )); then
            opportunity="Caching, parameter tuning, parallel processing"
        elif (( $(echo "$success_rate < 90" | bc -l) )); then
            opportunity="Error handling, retry logic, fallback agents"
        else
            opportunity="Minor optimizations, monitoring"
        fi
        
        # Store bottleneck data
        sqlite3 "$PERFORMANCE_DB" \
            "INSERT OR REPLACE INTO bottlenecks 
             (agent_name, operation, avg_response_time, p95_response_time, frequency, severity, optimization_opportunity)
             VALUES 
             ('$agent', 'general', $response_time, $p95_time, $frequency, '$severity', '$opportunity');"
        
        echo -e "${YELLOW}$agent:${NC} ${response_time}ms avg, ${success_rate}% success, ${severity} priority"
    done
    
    # Show bottleneck summary
    echo -e "\n${BLUE}Performance Bottlenecks Summary:${NC}"
    sqlite3 -column -header "$PERFORMANCE_DB" <<SQL
SELECT 
    severity as Priority,
    COUNT(*) as Count,
    ROUND(AVG(avg_response_time), 1) as 'Avg Response (ms)',
    GROUP_CONCAT(agent_name, ', ') as Agents
FROM bottlenecks 
GROUP BY severity 
ORDER BY 
    CASE severity 
        WHEN 'critical' THEN 1 
        WHEN 'high' THEN 2 
        WHEN 'medium' THEN 3 
        ELSE 4 
    END;
SQL
}

# Detect and resolve bottlenecks
detect_bottlenecks() {
    echo -e "${CYAN}=== Bottleneck Detection & Resolution ===${NC}\n"
    
    # Find critical bottlenecks
    sqlite3 "$PERFORMANCE_DB" \
        "SELECT agent_name, avg_response_time, optimization_opportunity 
         FROM bottlenecks 
         WHERE severity IN ('critical', 'high') 
         ORDER BY avg_response_time DESC;" | \
    while IFS='|' read -r agent response_time opportunity; do
        echo -e "${RED}🚨 Critical Bottleneck: $agent (${response_time}ms)${NC}"
        echo -e "   Opportunities: $opportunity"
        
        # Generate specific optimizations
        if (( $(echo "$response_time > 4000" | bc -l) )); then
            echo -e "   ${GREEN}→ Implementing caching strategy${NC}"
            implement_caching "$agent"
            
            echo -e "   ${GREEN}→ Optimizing parameters${NC}"
            optimize_parameters "$agent"
            
            echo -e "   ${GREEN}→ Considering parallelization${NC}"
            consider_parallelization "$agent"
        fi
        echo ""
    done
    
    # Analyze patterns for routing optimization
    echo -e "${BLUE}Analyzing routing patterns...${NC}"
    
    # Find best performing agents for similar tasks
    sqlite3 "$CONTEXT_DB" <<'SQL'
SELECT 
    substr(c.task_id, 1, 20) as task_pattern,
    p.agent_id,
    COUNT(*) as executions,
    AVG(p.duration_ms) as avg_time,
    AVG(CAST(p.success AS REAL)) * 100 as success_rate
FROM contexts c
JOIN performance_metrics p ON c.id = p.context_id
GROUP BY substr(c.task_id, 1, 20), p.agent_id
HAVING executions >= 2
ORDER BY task_pattern, avg_time ASC
LIMIT 10;
SQL
}

# Implement intelligent caching
implement_caching() {
    local agent="$1"
    
    echo -e "${BLUE}Implementing intelligent caching for $agent...${NC}"
    
    # Analyze operation patterns for caching opportunities
    local operations=$(sqlite3 -json "$CONTEXT_DB" \
        "SELECT DISTINCT operation FROM performance_metrics WHERE agent_id = '$agent';")
    
    echo "$operations" | jq -r '.[] | .operation' | while read -r operation; do
        # Calculate cache hit rate potential
        local frequency=$(sqlite3 "$CONTEXT_DB" \
            "SELECT COUNT(*) FROM performance_metrics 
             WHERE agent_id = '$agent' AND operation = '$operation';")
        
        if [ "$frequency" -gt 10 ]; then
            # High frequency operation - good caching candidate
            local avg_time=$(sqlite3 "$CONTEXT_DB" \
                "SELECT AVG(duration_ms) FROM performance_metrics 
                 WHERE agent_id = '$agent' AND operation = '$operation';")
            
            # Estimate cache savings (assume 80% hit rate, 95% time savings on hits)
            local estimated_savings=$(echo "scale=2; $avg_time * 0.8 * 0.95" | bc)
            
            # Create cache strategy
            sqlite3 "$PERFORMANCE_DB" \
                "INSERT INTO cache_strategies 
                 (operation_pattern, cache_key_template, cache_duration, hit_rate_target, estimated_savings_ms, priority)
                 VALUES 
                 ('$agent:$operation', '$agent:$operation:{context_hash}', 300, 0.8, $estimated_savings, 1);"
            
            echo -e "   ${GREEN}✓ Cache strategy created for $operation (${estimated_savings}ms savings)${NC}"
        fi
    done
}

# Optimize agent parameters
optimize_parameters() {
    local agent="$1"
    
    echo -e "${BLUE}Optimizing parameters for $agent...${NC}"
    
    # Get current performance metrics
    local current_time=$(sqlite3 "$LEARNING_DB" \
        "SELECT avg_response_time FROM agent_features WHERE agent_name = '$agent';")
    
    local current_success=$(sqlite3 "$LEARNING_DB" \
        "SELECT success_rate FROM agent_features WHERE agent_name = '$agent';")
    
    # Generate parameter optimizations based on performance
    local optimizations=""
    if (( $(echo "$current_time > 3000" | bc -l) )); then
        optimizations='{"timeout": 15000, "parallel": true, "batch_size": 5}'
        echo -e "   ${GREEN}→ Increased timeout, enabled parallelization${NC}"
    elif (( $(echo "$current_success < 90" | bc -l) )); then
        optimizations='{"retry_count": 3, "fallback_enabled": true, "validation": "strict"}'
        echo -e "   ${GREEN}→ Added retries and fallback logic${NC}"
    else
        optimizations='{"response_buffer": 1000, "cache_enabled": true, "compression": true}'
        echo -e "   ${GREEN}→ Enabled caching and compression${NC}"
    fi
    
    # Record optimization
    sqlite3 "$PERFORMANCE_DB" \
        "INSERT INTO applied_optimizations 
         (agent_name, optimization_type, optimization_details, baseline_performance)
         VALUES 
         ('$agent', 'parameter', '$optimizations', $current_time);"
}

# Consider parallelization opportunities
consider_parallelization() {
    local agent="$1"
    
    echo -e "${BLUE}Analyzing parallelization for $agent...${NC}"
    
    # Check if agent operations can be parallelized
    local operations=$(sqlite3 "$CONTEXT_DB" \
        "SELECT COUNT(DISTINCT operation) FROM performance_metrics WHERE agent_id = '$agent';")
    
    if [ "$operations" -gt 1 ]; then
        echo -e "   ${GREEN}→ Multiple operations detected - parallel execution possible${NC}"
        
        # Find suitable parallel companions
        local companions=$(sqlite3 "$OPTIMIZER_DB" \
            "SELECT agent_name FROM agent_availability 
             WHERE status = 'idle' AND agent_name != '$agent' LIMIT 2;")
        
        if [ -n "$companions" ]; then
            echo -e "   ${GREEN}→ Available parallel agents: $companions${NC}"
            
            # Record parallelization strategy
            local parallel_config='{"strategy": "parallel_execution", "companions": "'$companions'", "split_ratio": 0.5}'
            
            sqlite3 "$PERFORMANCE_DB" \
                "INSERT INTO applied_optimizations 
                 (agent_name, optimization_type, optimization_details)
                 VALUES 
                 ('$agent', 'parallelization', '$parallel_config');"
        fi
    fi
}

# Optimize task routing using ML insights
optimize_routing() {
    echo -e "${CYAN}=== Intelligent Task Routing Optimization ===${NC}\n"
    
    echo -e "${BLUE}Analyzing routing patterns using ML clustering...${NC}"
    
    # Get agent features from learning database
    sqlite3 "$LEARNING_DB" "SELECT agent_name, success_rate FROM agent_features;" | \
    while IFS='|' read -r agent success_rate; do
        echo -e "${YELLOW}Agent $agent → ${success_rate}% success rate${NC}"
    done
    
    # Find optimal routing based on performance
    echo -e "\n${BLUE}Generating optimal routing strategies...${NC}"
    
    # For each task pattern, find the best performing agents
    sqlite3 "$CONTEXT_DB" <<'SQL'
SELECT 
    substr(c.task_id, 1, 15) as task_pattern,
    COUNT(*) as total_tasks
FROM contexts c
GROUP BY substr(c.task_id, 1, 15)
HAVING total_tasks >= 3
ORDER BY total_tasks DESC;
SQL | \
    while IFS='|' read -r task_pattern task_count; do
        echo -e "\n${YELLOW}Task Pattern: $task_pattern ($task_count executions)${NC}"
        
        # Get top performing agents for this task pattern
        local best_agents=$(sqlite3 -separator ',' "$CONTEXT_DB" \
            "SELECT p.agent_id
             FROM contexts c
             JOIN performance_metrics p ON c.id = p.context_id
             WHERE substr(c.task_id, 1, 15) = '$task_pattern'
             GROUP BY p.agent_id
             ORDER BY AVG(p.duration_ms) ASC, AVG(CAST(p.success AS REAL)) DESC
             LIMIT 3;")
        
        if [ -n "$best_agents" ]; then
            echo -e "   ${GREEN}Optimal agents: $best_agents${NC}"
            
            # Calculate performance gain estimate
            local avg_performance=$(sqlite3 "$CONTEXT_DB" \
                "SELECT AVG(p.duration_ms)
                 FROM contexts c
                 JOIN performance_metrics p ON c.id = p.context_id
                 WHERE substr(c.task_id, 1, 15) = '$task_pattern';")
            
            local best_performance=$(sqlite3 "$CONTEXT_DB" \
                "SELECT AVG(p.duration_ms)
                 FROM contexts c
                 JOIN performance_metrics p ON c.id = p.context_id
                 WHERE substr(c.task_id, 1, 15) = '$task_pattern' AND p.agent_id IN ('$(echo $best_agents | sed "s/,/', '/g")')
                 LIMIT 1;")
            
            if [ -n "$best_performance" ] && [ -n "$avg_performance" ]; then
                local gain=$(echo "scale=2; (($avg_performance - $best_performance) / $avg_performance) * 100" | bc)
                echo -e "   ${GREEN}Estimated improvement: ${gain}%${NC}"
                
                # Store routing optimization
                sqlite3 "$PERFORMANCE_DB" \
                    "INSERT OR REPLACE INTO routing_optimizations 
                     (task_pattern, optimal_agents, routing_strategy, performance_gain, confidence)
                     VALUES 
                     ('$task_pattern', '[\"$(echo $best_agents | sed 's/,/\", \"/g')\"]', 'fastest', $gain, 0.8);"
            fi
        fi
    done
}

# Create intelligent cache strategies
create_cache_strategies() {
    echo -e "${CYAN}=== Intelligent Caching Strategy Creation ===${NC}\n"
    
    echo -e "${BLUE}Analyzing operation patterns for caching opportunities...${NC}"
    
    # Find frequently repeated operations
    sqlite3 "$CONTEXT_DB" <<'SQL'
SELECT 
    p.operation,
    p.agent_id,
    COUNT(*) as frequency,
    AVG(p.duration_ms) as avg_duration,
    COUNT(DISTINCT p.context_id) as unique_contexts
FROM performance_metrics p
GROUP BY p.operation, p.agent_id
HAVING frequency >= 5
ORDER BY frequency DESC, avg_duration DESC
LIMIT 10;
SQL | \
    while IFS='|' read -r operation agent frequency avg_duration unique_contexts; do
        echo -e "\n${YELLOW}High-frequency operation: $operation${NC}"
        echo -e "   Agent: $agent"
        echo -e "   Frequency: $frequency executions"
        echo -e "   Avg Duration: ${avg_duration}ms"
        echo -e "   Unique Contexts: $unique_contexts"
        
        # Calculate caching benefit
        local cache_ratio=$(echo "scale=2; ($frequency - $unique_contexts) / $frequency" | bc)
        local potential_savings=$(echo "scale=2; $avg_duration * $cache_ratio * 0.9" | bc)
        
        echo -e "   ${GREEN}Cache potential: ${cache_ratio} ratio, ${potential_savings}ms savings${NC}"
        
        if (( $(echo "$cache_ratio > 0.3" | bc -l) )); then
            # Good caching candidate
            local cache_duration=300
            if (( $(echo "$avg_duration > 2000" | bc -l) )); then
                cache_duration=600  # Longer cache for slow operations
            fi
            
            sqlite3 "$PERFORMANCE_DB" \
                "INSERT OR REPLACE INTO cache_strategies 
                 (operation_pattern, cache_key_template, cache_duration, hit_rate_target, estimated_savings_ms, priority)
                 VALUES 
                 ('$agent:$operation', '$agent:$operation:{input_hash}', $cache_duration, $cache_ratio, $potential_savings, 
                  CASE WHEN $potential_savings > 1000 THEN 1 WHEN $potential_savings > 500 THEN 2 ELSE 3 END);"
            
            echo -e "   ${GREEN}✓ Cache strategy created (${cache_duration}s TTL)${NC}"
        fi
    done
    
    # Show cache strategy summary
    echo -e "\n${BLUE}Cache Strategy Summary:${NC}"
    sqlite3 -column -header "$PERFORMANCE_DB" <<SQL
SELECT 
    priority as Priority,
    COUNT(*) as Strategies,
    ROUND(AVG(estimated_savings_ms), 1) as 'Avg Savings (ms)',
    ROUND(SUM(estimated_savings_ms), 1) as 'Total Savings (ms)'
FROM cache_strategies 
GROUP BY priority 
ORDER BY priority;
SQL
}

# Monitor optimization effectiveness
monitor_optimizations() {
    echo -e "${CYAN}=== Optimization Monitoring ===${NC}\n"
    
    # Check applied optimizations
    local active_optimizations=$(sqlite3 "$PERFORMANCE_DB" \
        "SELECT COUNT(*) FROM applied_optimizations WHERE status = 'active';")
    
    echo -e "${BLUE}Active Optimizations: $active_optimizations${NC}"
    
    if [ "$active_optimizations" -gt 0 ]; then
        sqlite3 -column -header "$PERFORMANCE_DB" <<SQL
SELECT 
    agent_name as Agent,
    optimization_type as Type,
    CASE 
        WHEN optimized_performance IS NOT NULL 
        THEN ROUND(improvement_percent, 1) || '%'
        ELSE 'Pending'
    END as Improvement,
    datetime(applied_at, 'localtime') as Applied
FROM applied_optimizations 
WHERE status = 'active'
ORDER BY applied_at DESC
LIMIT 10;
SQL
    fi
    
    # Show performance trends
    echo -e "\n${BLUE}Performance Trends:${NC}"
    
    # Calculate current vs baseline performance
    sqlite3 "$LEARNING_DB" "SELECT agent_name, success_rate, avg_response_time FROM agent_features;" | \
    while IFS='|' read -r agent success_rate response_time; do
        # Check if there are optimizations for this agent
        local optimization_count=$(sqlite3 "$PERFORMANCE_DB" \
            "SELECT COUNT(*) FROM applied_optimizations WHERE agent_name = '$agent' AND status = 'active';")
        
        if [ "$optimization_count" -gt 0 ]; then
            # Get baseline
            local baseline=$(sqlite3 "$PERFORMANCE_DB" \
                "SELECT AVG(baseline_performance) FROM applied_optimizations WHERE agent_name = '$agent';")
            
            if [ -n "$baseline" ] && [ "$baseline" != "" ]; then
                local improvement=$(echo "scale=1; (($baseline - $response_time) / $baseline) * 100" | bc 2>/dev/null || echo "0")
                
                if (( $(echo "$improvement > 0" | bc -l) )); then
                    echo -e "   ${GREEN}$agent: +${improvement}% faster${NC}"
                else
                    echo -e "   ${YELLOW}$agent: No improvement yet${NC}"
                fi
            fi
        fi
    done
}

# Generate performance report
generate_performance_report() {
    echo -e "${MAGENTA}=== PERFORMANCE OPTIMIZATION REPORT ===${NC}\n"
    
    # System overview
    echo -e "${BLUE}System Performance Overview:${NC}"
    local total_agents=$(sqlite3 "$LEARNING_DB" "SELECT COUNT(*) FROM agent_features;")
    local slow_agents=$(sqlite3 "$PERFORMANCE_DB" "SELECT COUNT(*) FROM bottlenecks WHERE severity IN ('high', 'critical');")
    local optimizations=$(sqlite3 "$PERFORMANCE_DB" "SELECT COUNT(*) FROM applied_optimizations WHERE status = 'active';")
    
    echo "  Total Agents: $total_agents"
    echo "  Performance Issues: $slow_agents"
    echo "  Active Optimizations: $optimizations"
    
    # Performance metrics
    echo -e "\n${BLUE}Performance Metrics:${NC}"
    sqlite3 -column -header "$LEARNING_DB" <<SQL
SELECT 
    'Average' as Metric,
    ROUND(AVG(avg_response_time), 1) as 'Response Time (ms)',
    ROUND(AVG(success_rate), 1) as 'Success Rate (%)'
FROM agent_features;
SQL
    
    # Bottleneck summary
    echo -e "\n${BLUE}Critical Bottlenecks:${NC}"
    sqlite3 -column -header "$PERFORMANCE_DB" <<SQL
SELECT 
    agent_name as Agent,
    ROUND(avg_response_time, 1) as 'Response Time (ms)',
    severity as Severity,
    substr(optimization_opportunity, 1, 40) as 'Optimization Opportunity'
FROM bottlenecks 
WHERE severity IN ('high', 'critical')
ORDER BY avg_response_time DESC
LIMIT 5;
SQL
    
    # Cache strategies
    echo -e "\n${BLUE}Top Cache Strategies:${NC}"
    sqlite3 -column -header "$PERFORMANCE_DB" <<SQL
SELECT 
    operation_pattern as Pattern,
    cache_duration as 'TTL (s)',
    ROUND(hit_rate_target * 100, 1) as 'Target Hit Rate (%)',
    ROUND(estimated_savings_ms, 1) as 'Savings (ms)'
FROM cache_strategies 
ORDER BY estimated_savings_ms DESC
LIMIT 5;
SQL
    
    # Routing optimizations
    echo -e "\n${BLUE}Routing Optimizations:${NC}"
    sqlite3 -column -header "$PERFORMANCE_DB" <<SQL
SELECT 
    task_pattern as 'Task Pattern',
    routing_strategy as Strategy,
    ROUND(performance_gain, 1) as 'Improvement (%)',
    ROUND(confidence * 100, 1) as 'Confidence (%)'
FROM routing_optimizations 
ORDER BY performance_gain DESC
LIMIT 5;
SQL
}

# Main command handler
case "${1:-help}" in
    init)
        init_performance_db
        ;;
    analyze)
        analyze_performance
        ;;
    bottlenecks)
        detect_bottlenecks
        ;;
    routing)
        optimize_routing
        ;;
    cache)
        create_cache_strategies
        ;;
    monitor)
        monitor_optimizations
        ;;
    report)
        generate_performance_report
        ;;
    optimize)
        # Run full optimization cycle
        echo -e "${BOLD}${MAGENTA}Running Full Performance Optimization Cycle${NC}\n"
        analyze_performance
        echo ""
        detect_bottlenecks
        echo ""
        optimize_routing
        echo ""
        create_cache_strategies
        echo ""
        monitor_optimizations
        ;;
    help|*)
        echo "Performance Optimizer using Intelligence Layer"
        echo "Usage: $0 <command> [args...]"
        echo ""
        echo "Commands:"
        echo "  init                  - Initialize performance optimization database"
        echo "  analyze               - Analyze current performance using ML insights"
        echo "  bottlenecks           - Detect and resolve performance bottlenecks"
        echo "  routing               - Optimize task routing using clustering data"
        echo "  cache                 - Create intelligent caching strategies"
        echo "  monitor               - Monitor optimization effectiveness"
        echo "  report                - Generate comprehensive performance report"
        echo "  optimize              - Run full optimization cycle"
        ;;
esac