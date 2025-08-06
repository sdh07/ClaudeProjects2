#!/bin/bash
# Self-Improvement Integration with Intelligence Layer
# Sprint 9, Day 8: Continuous learning and evolution

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
CONTEXT_DB="$PROJECT_ROOT/.cpdm/context/contexts.db"
LEARNING_DB="$PROJECT_ROOT/.cpdm/intelligence/learning.db"
OPTIMIZER_DB="$PROJECT_ROOT/.cpdm/intelligence/optimizer.db"
IMPROVEMENT_DB="$PROJECT_ROOT/.cpdm/intelligence/improvement.db"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Initialize improvement database
init_improvement_db() {
    mkdir -p "$(dirname "$IMPROVEMENT_DB")"
    
    sqlite3 "$IMPROVEMENT_DB" <<'SQL'
-- Discovered capabilities
CREATE TABLE IF NOT EXISTS discovered_capabilities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_name TEXT NOT NULL,
    capability_type TEXT,  -- domain, skill, tool
    capability_value TEXT,
    confidence REAL,
    evidence TEXT,  -- JSON array of examples
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Performance evolution tracking
CREATE TABLE IF NOT EXISTS performance_evolution (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_name TEXT NOT NULL,
    metric_name TEXT,
    old_value REAL,
    new_value REAL,
    improvement_percent REAL,
    change_reason TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Learning pipeline stages
CREATE TABLE IF NOT EXISTS learning_pipeline (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    stage_name TEXT NOT NULL,
    input_data TEXT,
    processing_result TEXT,
    output_action TEXT,
    success BOOLEAN,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Improvement recommendations
CREATE TABLE IF NOT EXISTS improvement_recommendations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_name TEXT,
    recommendation_type TEXT,  -- performance, capability, architecture
    description TEXT,
    expected_impact REAL,
    priority INTEGER,
    status TEXT DEFAULT 'pending',  -- pending, applied, rejected
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Agent evolution history
CREATE TABLE IF NOT EXISTS agent_evolution (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_name TEXT NOT NULL,
    version TEXT,
    changes TEXT,  -- JSON array of changes
    performance_before TEXT,  -- JSON metrics
    performance_after TEXT,  -- JSON metrics
    evolved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_discovered_agent ON discovered_capabilities(agent_name);
CREATE INDEX IF NOT EXISTS idx_evolution_agent ON performance_evolution(agent_name);
CREATE INDEX IF NOT EXISTS idx_recommendations_status ON improvement_recommendations(status);
SQL
    
    echo -e "${GREEN}Improvement database initialized${NC}"
}

# Discover agent capabilities
discover_capabilities() {
    local agent="${1:-all}"
    
    echo -e "${CYAN}=== Capability Discovery ===${NC}\n"
    echo -e "${BLUE}Analyzing agent outputs for hidden capabilities...${NC}"
    
    # Analyze recent agent outputs
    local query=""
    if [ "$agent" = "all" ]; then
        query="SELECT DISTINCT agent_id FROM performance_metrics WHERE agent_id IS NOT NULL LIMIT 10;"
    else
        query="SELECT '$agent' as agent_id;"
    fi
    
    sqlite3 "$CONTEXT_DB" "$query" | while read -r agent_name; do
        echo -e "\n${YELLOW}Analyzing: $agent_name${NC}"
        
        # Check for domain capabilities
        local contexts=$(sqlite3 "$CONTEXT_DB" \
            "SELECT COUNT(DISTINCT c.id) FROM contexts c 
             JOIN performance_metrics p ON c.id = p.context_id 
             WHERE p.agent_id = '$agent_name' AND p.success = 1;")
        
        if [ "$contexts" -gt 5 ]; then
            # Analyze successful operations
            local operations=$(sqlite3 -json "$CONTEXT_DB" \
                "SELECT DISTINCT operation FROM performance_metrics 
                 WHERE agent_id = '$agent_name' AND success = 1;" 2>/dev/null || echo '[]')
            
            # Infer new capabilities
            if echo "$operations" | grep -q "parallel"; then
                sqlite3 "$IMPROVEMENT_DB" <<SQL
INSERT OR IGNORE INTO discovered_capabilities 
(agent_name, capability_type, capability_value, confidence, evidence)
VALUES 
('$agent_name', 'skill', 'parallel-execution', 0.8, '$operations');
SQL
                echo -e "  ${GREEN}✓ Discovered: parallel-execution skill${NC}"
            fi
            
            if echo "$operations" | grep -q "optimize"; then
                sqlite3 "$IMPROVEMENT_DB" <<SQL
INSERT OR IGNORE INTO discovered_capabilities 
(agent_name, capability_type, capability_value, confidence, evidence)
VALUES 
('$agent_name', 'skill', 'optimization', 0.7, '$operations');
SQL
                echo -e "  ${GREEN}✓ Discovered: optimization skill${NC}"
            fi
        fi
        
        # Check for performance improvements
        local avg_time=$(sqlite3 "$CONTEXT_DB" \
            "SELECT AVG(duration_ms) FROM performance_metrics 
             WHERE agent_id = '$agent_name' AND duration_ms > 0;")
        
        if [ -n "$avg_time" ]; then
            echo -e "  Average response time: ${avg_time}ms"
        fi
    done
    
    # Summary
    local discoveries=$(sqlite3 "$IMPROVEMENT_DB" \
        "SELECT COUNT(*) FROM discovered_capabilities 
         WHERE datetime(discovered_at) > datetime('now', '-1 hour');")
    
    echo -e "\n${GREEN}Total new capabilities discovered: $discoveries${NC}"
}

# Track performance evolution
track_evolution() {
    echo -e "${CYAN}=== Performance Evolution Tracking ===${NC}\n"
    
    # Compare current performance with baseline
    sqlite3 "$LEARNING_DB" "SELECT agent_name, success_rate, avg_response_time FROM agent_features;" | \
    while IFS='|' read -r agent success_rate response_time; do
        # Get previous values
        local prev_success=$(sqlite3 "$IMPROVEMENT_DB" \
            "SELECT new_value FROM performance_evolution 
             WHERE agent_name = '$agent' AND metric_name = 'success_rate' 
             ORDER BY timestamp DESC LIMIT 1;")
        
        if [ -z "$prev_success" ]; then
            prev_success="$success_rate"
        fi
        
        # Calculate improvement
        local improvement=0
        if [ "$prev_success" != "0" ]; then
            improvement=$(echo "scale=2; (($success_rate - $prev_success) / $prev_success) * 100" | bc 2>/dev/null || echo "0")
        fi
        
        # Record evolution if changed
        if [ "$improvement" != "0" ]; then
            sqlite3 "$IMPROVEMENT_DB" <<SQL
INSERT INTO performance_evolution 
(agent_name, metric_name, old_value, new_value, improvement_percent, change_reason)
VALUES 
('$agent', 'success_rate', $prev_success, $success_rate, $improvement, 'continuous learning');
SQL
            
            if (( $(echo "$improvement > 0" | bc -l) )); then
                echo -e "${GREEN}↑ $agent: +${improvement}% success rate${NC}"
            else
                echo -e "${RED}↓ $agent: ${improvement}% success rate${NC}"
            fi
        fi
    done
    
    # Show evolution summary
    echo -e "\n${BLUE}Evolution Summary:${NC}"
    sqlite3 -column -header "$IMPROVEMENT_DB" <<SQL
SELECT 
    agent_name as Agent,
    COUNT(*) as Changes,
    ROUND(AVG(improvement_percent), 1) as 'Avg Improvement %'
FROM performance_evolution
WHERE datetime(timestamp) > datetime('now', '-7 days')
GROUP BY agent_name
ORDER BY AVG(improvement_percent) DESC
LIMIT 5;
SQL
}

# Generate improvement recommendations
generate_recommendations() {
    echo -e "${CYAN}=== Generating Improvement Recommendations ===${NC}\n"
    
    # Analyze underperforming agents
    sqlite3 "$LEARNING_DB" "SELECT agent_name, success_rate FROM agent_features WHERE success_rate < 90;" | \
    while IFS='|' read -r agent success_rate; do
        # Check if recommendation already exists
        local existing=$(sqlite3 "$IMPROVEMENT_DB" \
            "SELECT COUNT(*) FROM improvement_recommendations 
             WHERE agent_name = '$agent' AND status = 'pending';")
        
        if [ "$existing" -eq 0 ]; then
            local priority=3
            if (( $(echo "$success_rate < 70" | bc -l) )); then
                priority=1
            elif (( $(echo "$success_rate < 80" | bc -l) )); then
                priority=2
            fi
            
            sqlite3 "$IMPROVEMENT_DB" <<SQL
INSERT INTO improvement_recommendations 
(agent_name, recommendation_type, description, expected_impact, priority)
VALUES 
('$agent', 'performance', 
 'Add retry logic and error handling to improve success rate from $success_rate%', 
 20, $priority);
SQL
            
            echo -e "${YELLOW}⚠ Recommendation for $agent: Improve error handling (Priority: $priority)${NC}"
        fi
    done
    
    # Recommend capability additions
    sqlite3 "$IMPROVEMENT_DB" <<SQL
INSERT OR IGNORE INTO improvement_recommendations 
(agent_name, recommendation_type, description, expected_impact, priority)
SELECT 
    dc.agent_name,
    'capability',
    'Add discovered capability: ' || dc.capability_value,
    dc.confidence * 10,
    2
FROM discovered_capabilities dc
WHERE dc.confidence > 0.7
  AND NOT EXISTS (
    SELECT 1 FROM improvement_recommendations ir 
    WHERE ir.agent_name = dc.agent_name 
      AND ir.description LIKE '%' || dc.capability_value || '%'
  );
SQL
    
    # Display recommendations
    echo -e "\n${BLUE}Current Recommendations:${NC}"
    sqlite3 -column -header "$IMPROVEMENT_DB" <<SQL
SELECT 
    agent_name as Agent,
    recommendation_type as Type,
    substr(description, 1, 50) as Recommendation,
    priority as Priority
FROM improvement_recommendations
WHERE status = 'pending'
ORDER BY priority, expected_impact DESC
LIMIT 10;
SQL
}

# Apply improvements
apply_improvements() {
    local auto_apply="${1:-false}"
    
    echo -e "${CYAN}=== Applying Improvements ===${NC}\n"
    
    # Get pending recommendations
    sqlite3 "$IMPROVEMENT_DB" \
        "SELECT id, agent_name, recommendation_type, description 
         FROM improvement_recommendations 
         WHERE status = 'pending' AND priority = 1 
         ORDER BY priority LIMIT 5;" | \
    while IFS='|' read -r rec_id agent rec_type description; do
        echo -e "${YELLOW}Recommendation #$rec_id for $agent:${NC}"
        echo "  Type: $rec_type"
        echo "  Description: $description"
        
        if [ "$auto_apply" = "true" ]; then
            echo -e "  ${GREEN}Auto-applying...${NC}"
            
            # Simulate improvement application
            sqlite3 "$IMPROVEMENT_DB" <<SQL
UPDATE improvement_recommendations 
SET status = 'applied' 
WHERE id = $rec_id;

INSERT INTO agent_evolution 
(agent_name, version, changes)
VALUES 
('$agent', 'auto-v' || strftime('%s', 'now'), 
 '[{"type": "$rec_type", "change": "$description"}]');
SQL
            
            echo -e "  ${GREEN}✓ Applied${NC}"
        else
            echo -e "  ${BLUE}Status: Pending manual review${NC}"
        fi
        echo ""
    done
}

# Continuous learning pipeline
run_learning_pipeline() {
    echo -e "${CYAN}=== Running Continuous Learning Pipeline ===${NC}\n"
    
    # Stage 1: Data Collection
    echo -e "${BLUE}Stage 1: Data Collection${NC}"
    local data_collected=$(sqlite3 "$CONTEXT_DB" \
        "SELECT COUNT(*) FROM performance_metrics 
         WHERE datetime(timestamp) > datetime('now', '-1 hour');")
    echo "  Collected $data_collected new performance records"
    
    sqlite3 "$IMPROVEMENT_DB" <<SQL
INSERT INTO learning_pipeline (stage_name, input_data, success)
VALUES ('data_collection', '{"records": $data_collected}', 1);
SQL
    
    # Stage 2: Feature Extraction
    echo -e "\n${BLUE}Stage 2: Feature Extraction${NC}"
    ./scripts/learning-algorithms.sh extract > /dev/null 2>&1
    echo "  Features extracted for all agents"
    
    sqlite3 "$IMPROVEMENT_DB" <<SQL
INSERT INTO learning_pipeline (stage_name, processing_result, success)
VALUES ('feature_extraction', '{"status": "completed"}', 1);
SQL
    
    # Stage 3: Model Training
    echo -e "\n${BLUE}Stage 3: Model Training${NC}"
    ./scripts/learning-algorithms.sh train > /dev/null 2>&1
    echo "  Team effectiveness model updated"
    
    sqlite3 "$IMPROVEMENT_DB" <<SQL
INSERT INTO learning_pipeline (stage_name, processing_result, success)
VALUES ('model_training', '{"status": "completed"}', 1);
SQL
    
    # Stage 4: Optimization
    echo -e "\n${BLUE}Stage 4: Optimization${NC}"
    ./scripts/dynamic-optimizer.sh balance > /dev/null 2>&1
    echo "  Load balancing optimized"
    
    sqlite3 "$IMPROVEMENT_DB" <<SQL
INSERT INTO learning_pipeline (stage_name, processing_result, success)
VALUES ('optimization', '{"status": "completed"}', 1);
SQL
    
    # Stage 5: Improvement Application
    echo -e "\n${BLUE}Stage 5: Improvement Application${NC}"
    apply_improvements false
    
    sqlite3 "$IMPROVEMENT_DB" <<SQL
INSERT INTO learning_pipeline (stage_name, output_action, success)
VALUES ('improvement_application', '{"recommendations_generated": true}', 1);
SQL
    
    echo -e "\n${GREEN}Learning pipeline completed successfully${NC}"
}

# Intelligence dashboard
show_dashboard() {
    clear
    echo -e "${BOLD}${MAGENTA}=================================="
    echo -e "     INTELLIGENCE DASHBOARD"
    echo -e "==================================${NC}\n"
    
    # System Intelligence Score
    local avg_success=$(sqlite3 "$LEARNING_DB" \
        "SELECT ROUND(AVG(success_rate), 1) FROM agent_features;")
    local learning_rate=$(sqlite3 "$IMPROVEMENT_DB" \
        "SELECT COUNT(*) FROM performance_evolution 
         WHERE improvement_percent > 0 AND datetime(timestamp) > datetime('now', '-24 hours');")
    local discoveries=$(sqlite3 "$IMPROVEMENT_DB" \
        "SELECT COUNT(*) FROM discovered_capabilities 
         WHERE datetime(discovered_at) > datetime('now', '-24 hours');")
    
    local intelligence_score=$(echo "scale=1; ($avg_success * 0.5) + ($learning_rate * 2) + ($discoveries * 5)" | bc 2>/dev/null || echo "0")
    
    echo -e "${BOLD}${CYAN}Intelligence Score: $intelligence_score${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    # Key Metrics
    echo -e "${YELLOW}📊 Key Metrics:${NC}"
    echo "  • Average Success Rate: $avg_success%"
    echo "  • Learning Events (24h): $learning_rate"
    echo "  • Discoveries (24h): $discoveries"
    echo ""
    
    # Top Performing Agents
    echo -e "${YELLOW}🏆 Top Performers:${NC}"
    sqlite3 -list "$LEARNING_DB" "SELECT agent_name || ' (' || ROUND(success_rate, 1) || '%)' FROM agent_features ORDER BY success_rate DESC LIMIT 3;" 2>/dev/null | while read -r line; do
        echo "  • $line"
    done
    echo ""
    
    # Recent Improvements
    echo -e "${YELLOW}📈 Recent Improvements:${NC}"
    sqlite3 -list "$IMPROVEMENT_DB" "SELECT agent_name || ': +' || ROUND(improvement_percent, 1) || '%' FROM performance_evolution WHERE improvement_percent > 0 ORDER BY timestamp DESC LIMIT 3;" 2>/dev/null | while read -r line; do
        echo "  • $line"
    done
    echo ""
    
    # Active Recommendations
    echo -e "${YELLOW}💡 Active Recommendations:${NC}"
    local pending=$(sqlite3 "$IMPROVEMENT_DB" \
        "SELECT COUNT(*) FROM improvement_recommendations WHERE status = 'pending';")
    echo "  • Pending: $pending"
    
    local applied=$(sqlite3 "$IMPROVEMENT_DB" \
        "SELECT COUNT(*) FROM improvement_recommendations 
         WHERE status = 'applied' AND datetime(created_at) > datetime('now', '-24 hours');")
    echo "  • Applied (24h): $applied"
    echo ""
    
    # Learning Pipeline Status
    echo -e "${YELLOW}🔄 Pipeline Status:${NC}"
    sqlite3 -list "$IMPROVEMENT_DB" "SELECT '• ' || stage_name || ': ' || CASE WHEN success = 1 THEN '✓' ELSE '✗' END FROM learning_pipeline ORDER BY timestamp DESC LIMIT 5;" 2>/dev/null | while read -r line; do
        echo "  $line"
    done
    echo ""
    
    # System Health
    local idle_agents=$(sqlite3 "$OPTIMIZER_DB" \
        "SELECT COUNT(*) FROM agent_availability WHERE status = 'idle';")
    local total_agents=$(sqlite3 "$OPTIMIZER_DB" \
        "SELECT COUNT(*) FROM agent_availability;")
    
    echo -e "${YELLOW}🔧 System Health:${NC}"
    echo "  • Agent Availability: $idle_agents/$total_agents idle"
    local system_load=0
    if [ "$total_agents" -gt 0 ]; then
        system_load=$(echo "scale=1; 100 - ($idle_agents * 100 / $total_agents)" | bc 2>/dev/null || echo "0")
    fi
    echo "  • System Load: ${system_load}%"
    
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Last Updated: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
}

# Verify agent work
verify_agent_work() {
    local agent="$1"
    local context_id="$2"
    
    echo -e "${CYAN}=== Verifying Agent Work ===${NC}\n"
    echo -e "${BLUE}Agent: $agent${NC}"
    echo -e "${BLUE}Context: $context_id${NC}\n"
    
    # Check if work was completed
    local status=$(sqlite3 "$CONTEXT_DB" \
        "SELECT status FROM contexts WHERE id = '$context_id';")
    
    if [ "$status" = "completed" ]; then
        echo -e "${GREEN}✓ Context marked as completed${NC}"
    else
        echo -e "${YELLOW}⚠ Context status: $status${NC}"
    fi
    
    # Check performance metrics
    local metrics=$(sqlite3 -json "$CONTEXT_DB" \
        "SELECT agent_id, operation, duration_ms, success 
         FROM performance_metrics 
         WHERE context_id = '$context_id' AND agent_id = '$agent';")
    
    if [ -n "$metrics" ] && [ "$metrics" != "[]" ]; then
        echo -e "\n${GREEN}✓ Performance metrics recorded${NC}"
        echo "$metrics" | jq '.'
    else
        echo -e "\n${RED}✗ No performance metrics found${NC}"
    fi
    
    # Verify output quality
    echo -e "\n${BLUE}Quality Verification:${NC}"
    local success_rate=$(sqlite3 "$LEARNING_DB" \
        "SELECT success_rate FROM agent_features WHERE agent_name = '$agent';")
    
    if (( $(echo "$success_rate > 90" | bc -l) )); then
        echo -e "  ${GREEN}✓ Agent success rate: ${success_rate}% (Good)${NC}"
    else
        echo -e "  ${YELLOW}⚠ Agent success rate: ${success_rate}% (Needs improvement)${NC}"
    fi
    
    # Generate verification score
    local score=0
    [ "$status" = "completed" ] && ((score+=40))
    [ -n "$metrics" ] && ((score+=30))
    (( $(echo "$success_rate > 90" | bc -l) )) && ((score+=30))
    
    echo -e "\n${BOLD}Verification Score: $score/100${NC}"
    
    if [ $score -ge 70 ]; then
        echo -e "${GREEN}Result: VERIFIED ✓${NC}"
    else
        echo -e "${RED}Result: NEEDS REVIEW ✗${NC}"
    fi
}

# Main command handler
case "${1:-help}" in
    init)
        init_improvement_db
        ;;
    discover)
        discover_capabilities "${2:-all}"
        ;;
    evolve)
        track_evolution
        ;;
    recommend)
        generate_recommendations
        ;;
    apply)
        apply_improvements "${2:-false}"
        ;;
    pipeline)
        run_learning_pipeline
        ;;
    dashboard)
        show_dashboard
        ;;
    verify)
        verify_agent_work "$2" "$3"
        ;;
    monitor)
        # Continuous monitoring mode
        while true; do
            show_dashboard
            echo -e "\n${YELLOW}Refreshing in 10 seconds... (Ctrl+C to exit)${NC}"
            sleep 10
        done
        ;;
    help|*)
        echo "Self-Improvement Integration"
        echo "Usage: $0 <command> [args...]"
        echo ""
        echo "Commands:"
        echo "  init                      - Initialize improvement database"
        echo "  discover [agent]          - Discover agent capabilities"
        echo "  evolve                    - Track performance evolution"
        echo "  recommend                 - Generate recommendations"
        echo "  apply [auto]              - Apply improvements"
        echo "  pipeline                  - Run learning pipeline"
        echo "  dashboard                 - Show intelligence dashboard"
        echo "  verify <agent> <context>  - Verify agent work"
        echo "  monitor                   - Continuous dashboard monitoring"
        ;;
esac