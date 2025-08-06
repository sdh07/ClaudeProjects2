#!/bin/bash

# Agent Excellence Master Controller
# Orchestrates the complete self-improving agent system

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DB_PATH="$PROJECT_ROOT/.cpdm/agent-excellence/database/agent-excellence.db"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to log messages with timestamp
log_message() {
    local level=$1
    shift
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${!level}[$level]${NC} $*"
}

# Function to initialize the Agent Excellence system
initialize_system() {
    log_message BLUE "Initializing Agent Excellence System"
    
    # Initialize database
    if [ ! -f "$DB_PATH" ]; then
        log_message BLUE "Creating Agent Excellence database"
        sqlite3 "$DB_PATH" < "$PROJECT_ROOT/.cpdm/agent-excellence/database/schema.sql"
        log_message GREEN "Database created successfully"
    else
        log_message GREEN "Database already exists"
    fi
    
    # Load patterns into database
    log_message BLUE "Loading learning patterns"
    "$SCRIPT_DIR/pattern-detector.sh" load
    
    # Initialize performance tracking
    log_message BLUE "Initializing performance tracking"
    "$SCRIPT_DIR/agent-performance-tracker.sh" init
    
    # Create base template if missing
    log_message BLUE "Setting up agent templates"
    "$SCRIPT_DIR/agent-generator-enhanced.sh" template
    
    # Create validation configuration
    log_message BLUE "Setting up validation framework"
    "$SCRIPT_DIR/agent-validator.sh" config
    
    log_message GREEN "Agent Excellence System initialized successfully"
}

# Function to run continuous improvement cycle
improvement_cycle() {
    local scan_period=${1:-"24 hours"}
    
    log_message BLUE "Starting Agent Excellence improvement cycle (every $scan_period)"
    
    while true; do
        log_message CYAN "=== Starting Improvement Cycle ==="
        
        # 1. Performance Analysis
        log_message BLUE "Step 1: Analyzing agent performance"
        "$SCRIPT_DIR/agent-performance-tracker.sh" candidates > /tmp/improvement-candidates.txt
        
        # 2. Pattern Detection
        log_message BLUE "Step 2: Detecting applicable patterns"
        "$SCRIPT_DIR/pattern-detector.sh" scan --format json --output /tmp/pattern-analysis.json
        
        # 3. Generate Improvements
        log_message BLUE "Step 3: Generating agent improvements"
        improve_agents_from_analysis
        
        # 4. Validate Improvements
        log_message BLUE "Step 4: Validating generated agents"
        validate_generated_agents
        
        # 5. Deploy Successful Improvements
        log_message BLUE "Step 5: Deploying validated improvements"
        deploy_improvements
        
        # 6. Update Pattern Effectiveness
        log_message BLUE "Step 6: Updating pattern effectiveness metrics"
        "$SCRIPT_DIR/pattern-detector.sh" update
        
        log_message GREEN "=== Improvement Cycle Complete ==="
        
        # Sleep for the specified period
        if [ "$scan_period" != "once" ]; then
            log_message BLUE "Waiting $scan_period before next cycle..."
            if [[ "$scan_period" =~ ^[0-9]+$ ]]; then
                sleep "$scan_period"
            else
                # Convert human-readable time to seconds
                sleep_seconds=$(parse_time_to_seconds "$scan_period")
                sleep "$sleep_seconds"
            fi
        else
            break
        fi
    done
}

# Function to improve agents based on analysis
improve_agents_from_analysis() {
    local candidates_file="/tmp/improvement-candidates.txt"
    
    if [ ! -f "$candidates_file" ]; then
        log_message YELLOW "No improvement candidates found"
        return
    fi
    
    local improvement_count=0
    
    # Parse candidates and generate improvements
    while IFS='|' read -r agent failure_rate error_message; do
        agent=$(echo "$agent" | xargs)
        failure_rate=$(echo "$failure_rate" | xargs)
        
        if [ -n "$agent" ] && [ "$agent" != "Agent" ]; then
            log_message BLUE "Generating improvement for $agent (failure rate: $failure_rate)"
            
            # Determine appropriate patterns based on error message
            local patterns=""
            if echo "$error_message" | grep -q "timeout\|connection"; then
                patterns="retry-with-backoff"
            elif echo "$error_message" | grep -q "memory\|resource"; then
                patterns="memory-optimization"
            elif echo "$error_message" | grep -q "validation\|input"; then
                patterns="input-validation"
            else
                patterns="parallel-execution"  # Default improvement
            fi
            
            # Generate improved agent
            "$SCRIPT_DIR/agent-generator-enhanced.sh" from-failures "$agent" "7 days"
            
            # Also try to improve existing agent with specific patterns
            if "$SCRIPT_DIR/agent-generator-enhanced.sh" improve "$agent" "$patterns" true 2>/dev/null; then
                log_message GREEN "Applied patterns to $agent: $patterns"
                ((improvement_count++))
            else
                log_message YELLOW "Could not improve existing agent: $agent"
            fi
        fi
    done < "$candidates_file"
    
    log_message GREEN "Generated $improvement_count agent improvements"
}

# Function to validate generated agents
validate_generated_agents() {
    local generated_dir="$PROJECT_ROOT/agents/generated"
    local validation_passed=0
    local validation_failed=0
    
    if [ ! -d "$generated_dir" ]; then
        log_message YELLOW "No generated agents directory found"
        return
    fi
    
    log_message BLUE "Validating generated agents in $generated_dir"
    
    for agent_file in "$generated_dir"/*.md; do
        if [ -f "$agent_file" ]; then
            local agent_name=$(basename "$agent_file" .md)
            log_message BLUE "Validating $agent_name"
            
            if "$SCRIPT_DIR/agent-validator.sh" validate "$agent_file" text "syntax,semantics"; then
                case $? in
                    0)
                        log_message GREEN " $agent_name validation: PASSED"
                        ((validation_passed++))
                        
                        # Mark for deployment
                        touch "$generated_dir/$agent_name.validated"
                        ;;
                    1)
                        log_message YELLOW "  $agent_name validation: WARNING"
                        ((validation_passed++))
                        touch "$generated_dir/$agent_name.validated"
                        ;;
                    *)
                        log_message RED " $agent_name validation: FAILED"
                        ((validation_failed++))
                        ;;
                esac
            else
                log_message RED " $agent_name validation: FAILED"
                ((validation_failed++))
            fi
        fi
    done
    
    log_message GREEN "Validation complete: $validation_passed passed, $validation_failed failed"
}

# Function to deploy validated improvements
deploy_improvements() {
    local generated_dir="$PROJECT_ROOT/agents/generated"
    local deployed_count=0
    
    for validated_marker in "$generated_dir"/*.validated; do
        if [ -f "$validated_marker" ]; then
            local agent_name=$(basename "$validated_marker" .validated)
            local agent_file="$generated_dir/$agent_name.md"
            
            if [ -f "$agent_file" ]; then
                log_message BLUE "Deploying $agent_name"
                
                # Backup existing agent if it exists
                local target_dir=""
                for dir in "$PROJECT_ROOT/agents"/*; do
                    if [ -d "$dir" ] && [ -f "$dir/$agent_name.md" ]; then
                        target_dir="$dir"
                        break
                    fi
                done
                
                if [ -n "$target_dir" ]; then
                    # Create backup
                    cp "$target_dir/$agent_name.md" "$target_dir/$agent_name.md.bak.$(date +%Y%m%d_%H%M%S)"
                    log_message GREEN "Created backup of existing $agent_name"
                    
                    # Deploy improved version
                    cp "$agent_file" "$target_dir/$agent_name.md"
                    log_message GREEN "Deployed improved $agent_name to $target_dir"
                else
                    # New agent - place in appropriate directory
                    local agent_type=$(infer_agent_category "$agent_name")
                    local target_dir="$PROJECT_ROOT/agents/$agent_type"
                    
                    mkdir -p "$target_dir"
                    cp "$agent_file" "$target_dir/$agent_name.md"
                    log_message GREEN "Deployed new agent $agent_name to $target_dir"
                fi
                
                # Record successful deployment
                record_deployment "$agent_name" "success"
                
                # Clean up
                rm "$validated_marker"
                mkdir -p "$generated_dir/deployed"
                mv "$agent_file" "$generated_dir/deployed/$agent_name.md" 2>/dev/null || rm "$agent_file"
                
                ((deployed_count++))
            fi
        fi
    done
    
    log_message GREEN "Deployed $deployed_count agent improvements"
}

# Function to infer agent category from name
infer_agent_category() {
    local agent_name=$1
    
    case "$agent_name" in
        *orchestrator*|*context*|*methodology*|*knowledge*)
            echo "core"
            ;;
        *build*|*test*|*deploy*|*review*)
            echo "delivery"
            ;;
        *project*|*vision*|*architect*|*quality*)
            echo "domain"
            ;;
        *version*|*obsidian*|*sync*)
            echo "infrastructure"
            ;;
        *process*|*pm*|*cleanup*)
            echo "process"
            ;;
        *)
            echo "generated"
            ;;
    esac
}

# Function to record deployment
record_deployment() {
    local agent_name=$1
    local status=$2
    
    sqlite3 "$DB_PATH" <<EOF
INSERT INTO improvements (
    agent_name,
    version_before,
    version_after,
    improvement_type,
    trigger_type,
    description,
    status,
    applied_at
) VALUES (
    '$agent_name',
    '1.0.0',
    '1.1.0',
    'automated_improvement',
    'technology',
    'Automated improvement deployed by Agent Excellence System',
    '$status',
    datetime('now')
);
EOF
    
    log_message GREEN "Recorded deployment of $agent_name with status: $status"
}

# Function to generate system report
generate_report() {
    local output_file=${1:-"/tmp/agent-excellence-report.md"}
    
    log_message BLUE "Generating Agent Excellence System Report"
    
    cat > "$output_file" <<EOF
# Agent Excellence System Report
Generated: $(date)

## System Status
$(sqlite3 "$DB_PATH" -header -column "
SELECT 
    COUNT(DISTINCT name) as total_agents,
    COUNT(DISTINCT CASE WHEN status = 'active' THEN name END) as active_agents,
    COUNT(DISTINCT CASE WHEN status = 'testing' THEN name END) as testing_agents
FROM agents;
")

## Recent Improvements (Last 30 Days)
$(sqlite3 "$DB_PATH" -header -column "
SELECT 
    agent_name,
    improvement_type,
    trigger_type,
    status,
    datetime(applied_at, 'localtime') as applied
FROM improvements 
WHERE applied_at > datetime('now', '-30 days')
ORDER BY applied_at DESC
LIMIT 10;
")

## Pattern Effectiveness
$(sqlite3 "$DB_PATH" -header -column "
SELECT 
    pattern_name,
    pattern_type,
    usage_count,
    ROUND(success_rate * 100, 1) || '%' as success_rate,
    ROUND(confidence_score, 2) as confidence
FROM learning_patterns
ORDER BY usage_count DESC, success_rate DESC;
")

## Performance Summary
$("$SCRIPT_DIR/agent-performance-tracker.sh" report)

## Validation Results
$("$SCRIPT_DIR/agent-validator.sh" summary "30 days")

## Recommendations
Based on the analysis above, the system recommends:
1. Focus improvement efforts on agents with success rates < 95%
2. Apply high-confidence patterns (>0.8) to suitable agents
3. Monitor memory usage patterns for optimization opportunities
4. Review and update validation criteria based on failure patterns

EOF
    
    log_message GREEN "Report generated: $output_file"
    
    # Display summary on console
    echo ""
    echo "=== AGENT EXCELLENCE SYSTEM SUMMARY ==="
    sqlite3 "$DB_PATH" -header -column "
    SELECT 
        'Total Agents' as Metric,
        COUNT(DISTINCT name) as Value
    FROM agents
    UNION ALL
    SELECT 
        'Improvements Applied',
        COUNT(*) 
    FROM improvements 
    WHERE applied_at > datetime('now', '-7 days')
    UNION ALL
    SELECT 
        'Active Patterns',
        COUNT(*)
    FROM learning_patterns
    WHERE confidence_score > 0.7;
    "
    echo "======================================="
}

# Function to parse human-readable time to seconds
parse_time_to_seconds() {
    local time_str=$1
    local seconds=0
    
    if [[ "$time_str" =~ ([0-9]+)\ *hours? ]]; then
        seconds=$((${BASH_REMATCH[1]} * 3600))
    elif [[ "$time_str" =~ ([0-9]+)\ *minutes? ]]; then
        seconds=$((${BASH_REMATCH[1]} * 60))
    elif [[ "$time_str" =~ ([0-9]+)\ *days? ]]; then
        seconds=$((${BASH_REMATCH[1]} * 86400))
    else
        seconds=3600  # Default to 1 hour
    fi
    
    echo $seconds
}

# Function to run interactive mode
interactive_mode() {
    log_message BLUE "Starting Agent Excellence Interactive Mode"
    
    while true; do
        echo ""
        echo "=== AGENT EXCELLENCE MASTER CONTROLLER ==="
        echo "1. Run single improvement cycle"
        echo "2. Start continuous improvement (24h cycle)"
        echo "3. Generate system report"
        echo "4. Validate all agents"
        echo "5. Analyze agent performance"
        echo "6. Scan for patterns"
        echo "7. Generate test agent"
        echo "8. Initialize system"
        echo "9. Exit"
        echo ""
        read -p "Select option (1-9): " choice
        
        case $choice in
            1)
                improvement_cycle once
                ;;
            2)
                improvement_cycle "24 hours"
                ;;
            3)
                generate_report
                ;;
            4)
                "$SCRIPT_DIR/agent-validator.sh" batch "*.md"
                ;;
            5)
                "$SCRIPT_DIR/agent-performance-tracker.sh" report
                ;;
            6)
                "$SCRIPT_DIR/pattern-detector.sh" scan
                ;;
            7)
                read -p "Enter agent name: " agent_name
                read -p "Enter patterns (comma-separated): " patterns
                "$SCRIPT_DIR/agent-generator-enhanced.sh" generate "$agent_name" base "$patterns"
                ;;
            8)
                initialize_system
                ;;
            9)
                log_message GREEN "Exiting Agent Excellence System"
                exit 0
                ;;
            *)
                log_message YELLOW "Invalid option. Please select 1-9."
                ;;
        esac
    done
}

# Main command processing
case "${1:-interactive}" in
    init)
        initialize_system
        ;;
    
    cycle)
        improvement_cycle "${2:-24 hours}"
        ;;
    
    once)
        improvement_cycle once
        ;;
    
    report)
        generate_report "$2"
        ;;
    
    interactive)
        interactive_mode
        ;;
    
    *)
        echo "Agent Excellence Master Controller"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  init                 Initialize the Agent Excellence system"
        echo "  cycle [period]       Start continuous improvement cycle (default: 24 hours)"
        echo "  once                 Run single improvement cycle"
        echo "  report [file]        Generate system report"
        echo "  interactive          Start interactive mode (default)"
        echo ""
        echo "Examples:"
        echo "  $0 init"
        echo "  $0 cycle '6 hours'"
        echo "  $0 once"
        echo "  $0 report /tmp/report.md"
        echo ""
        echo "The Agent Excellence system continuously:"
        echo "  1. Monitors agent performance"
        echo "  2. Detects improvement patterns"
        echo "  3. Generates improved agents"
        echo "  4. Validates improvements"
        echo "  5. Deploys successful upgrades"
        echo "  6. Updates learning patterns"
        ;;
esac