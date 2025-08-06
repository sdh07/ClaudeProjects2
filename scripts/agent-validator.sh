#!/bin/bash

# Agent Validator - SubAgentMasterDesigner Component
# Validates agents before deployment using comprehensive test framework

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DB_PATH="$PROJECT_ROOT/.cpdm/agent-excellence/database/agent-excellence.db"
AGENTS_DIR="$PROJECT_ROOT/agents"
TEMP_DIR="/tmp/agent-validator"
TEST_OUTPUT_DIR="$TEMP_DIR/test-results"
VALIDATION_CONFIG="$PROJECT_ROOT/.cpdm/agent-excellence/validation-config.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Ensure directories exist
mkdir -p "$TEMP_DIR" "$TEST_OUTPUT_DIR"

# Function to log messages
log_message() {
    local level=$1
    shift
    echo -e "${!level}[$level]${NC} $*"
}

# Function to create validation configuration if missing
create_validation_config() {
    if [ ! -f "$VALIDATION_CONFIG" ]; then
        cat > "$VALIDATION_CONFIG" <<EOF
{
  "validation_levels": [
    {
      "name": "syntax",
      "description": "Basic syntax and format validation",
      "required": true,
      "weight": 0.3
    },
    {
      "name": "semantic",
      "description": "Logical consistency and completeness",
      "required": true,
      "weight": 0.4
    },
    {
      "name": "integration",
      "description": "Integration compatibility testing",
      "required": false,
      "weight": 0.2
    },
    {
      "name": "performance",
      "description": "Performance and resource validation",
      "required": false,
      "weight": 0.1
    }
  ],
  "pass_threshold": 0.75,
  "warning_threshold": 0.60,
  "test_timeout": 300,
  "parallel_tests": true,
  "generate_report": true
}
EOF
        log_message GREEN "Created validation configuration: $VALIDATION_CONFIG"
    fi
}

# Function to validate agent syntax
validate_syntax() {
    local agent_file=$1
    local results_file=$2
    
    log_message BLUE "Running syntax validation on $agent_file"
    
    local score=0
    local max_score=100
    local issues=()
    
    # Check file exists and is readable
    if [ ! -f "$agent_file" ]; then
        issues+=("Agent file does not exist")
        echo "{\"test\": \"file_exists\", \"passed\": false, \"score\": 0, \"error\": \"File not found\"}" >> "$results_file"
        return 1
    fi
    
    # Check YAML frontmatter
    if head -20 "$agent_file" | grep -q "^---$"; then
        score=$((score + 20))
        echo "{\"test\": \"yaml_frontmatter\", \"passed\": true, \"score\": 20}" >> "$results_file"
        
        # Validate required fields in frontmatter
        local required_fields=("name" "description" "version" "capabilities")
        for field in "${required_fields[@]}"; do
            if grep -q "^$field:" "$agent_file"; then
                score=$((score + 5))
                echo "{\"test\": \"required_field_$field\", \"passed\": true, \"score\": 5}" >> "$results_file"
            else
                issues+=("Missing required field: $field")
                echo "{\"test\": \"required_field_$field\", \"passed\": false, \"score\": 0, \"error\": \"Missing required field\"}" >> "$results_file"
            fi
        done
    else
        issues+=("Missing or invalid YAML frontmatter")
        echo "{\"test\": \"yaml_frontmatter\", \"passed\": false, \"score\": 0, \"error\": \"Missing frontmatter\"}" >> "$results_file"
    fi
    
    # Check for required sections
    local required_sections=("Core Purpose" "Primary Functions" "Capabilities" "Workflow")
    for section in "${required_sections[@]}"; do
        if grep -q "## $section" "$agent_file"; then
            score=$((score + 10))
            echo "{\"test\": \"section_$section\", \"passed\": true, \"score\": 10}" >> "$results_file"
        else
            issues+=("Missing required section: $section")
            echo "{\"test\": \"section_$section\", \"passed\": false, \"score\": 0, \"error\": \"Missing section\"}" >> "$results_file"
        fi
    done
    
    # Check markdown validity (basic)
    if ! grep -q "^#[^#]" "$agent_file"; then
        issues+=("No main header found")
        echo "{\"test\": \"markdown_header\", \"passed\": false, \"score\": 0, \"error\": \"No main header\"}" >> "$results_file"
    else
        score=$((score + 10))
        echo "{\"test\": \"markdown_header\", \"passed\": true, \"score\": 10}" >> "$results_file"
    fi
    
    # Check for template placeholders (should not exist in final agent)
    if grep -q "{{[^}]*}}" "$agent_file"; then
        issues+=("Contains unresolved template placeholders")
        echo "{\"test\": \"template_placeholders\", \"passed\": false, \"score\": 0, \"error\": \"Unresolved placeholders\"}" >> "$results_file"
    else
        score=$((score + 10))
        echo "{\"test\": \"template_placeholders\", \"passed\": true, \"score\": 10}" >> "$results_file"
    fi
    
    local final_score=$(echo "scale=2; $score / $max_score" | bc -l 2>/dev/null || echo "0.0")
    
    echo "{\"validation_level\": \"syntax\", \"score\": $final_score, \"max_score\": 1.0, \"issues\": $(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)}" >> "$results_file"
    
    log_message GREEN "Syntax validation completed. Score: $final_score"
    
    if (( $(echo "$final_score >= 0.7" | bc -l 2>/dev/null || echo "0") )); then
        return 0
    else
        return 1
    fi
}

# Function to validate agent semantics
validate_semantics() {
    local agent_file=$1
    local results_file=$2
    
    log_message BLUE "Running semantic validation on $agent_file"
    
    local score=0
    local max_score=100
    local issues=()
    
    # Extract agent name from file
    local agent_name=$(basename "$agent_file" .md)
    
    # Check agent name consistency
    if grep -q "name: $agent_name" "$agent_file" && grep -q "# $agent_name Agent" "$agent_file"; then
        score=$((score + 15))
        echo "{\"test\": \"name_consistency\", \"passed\": true, \"score\": 15}" >> "$results_file"
    else
        issues+=("Agent name inconsistency between filename, frontmatter, and header")
        echo "{\"test\": \"name_consistency\", \"passed\": false, \"score\": 0, \"error\": \"Name inconsistency\"}" >> "$results_file"
    fi
    
    # Check for coherent purpose statement
    local purpose_lines=$(grep -A 5 "## Core Purpose" "$agent_file" | tail -n +2 | wc -l)
    if [ "$purpose_lines" -gt 0 ]; then
        score=$((score + 15))
        echo "{\"test\": \"purpose_defined\", \"passed\": true, \"score\": 15}" >> "$results_file"
    else
        issues+=("Core purpose not properly defined")
        echo "{\"test\": \"purpose_defined\", \"passed\": false, \"score\": 0, \"error\": \"Purpose missing\"}" >> "$results_file"
    fi
    
    # Check capabilities vs functions alignment
    local has_capabilities=$(grep -c "^-" "$agent_file" | head -1)
    local has_functions=$(grep -A 10 "## Primary Functions" "$agent_file" | grep -c "^[0-9]" | head -1)
    
    if [ "$has_capabilities" -gt 2 ] && [ "$has_functions" -gt 2 ]; then
        score=$((score + 20))
        echo "{\"test\": \"capabilities_functions_alignment\", \"passed\": true, \"score\": 20}" >> "$results_file"
    else
        issues+=("Insufficient detail in capabilities or functions")
        echo "{\"test\": \"capabilities_functions_alignment\", \"passed\": false, \"score\": 0, \"error\": \"Insufficient detail\"}" >> "$results_file"
    fi
    
    # Check for error handling specification
    if grep -q "## Error Handling" "$agent_file" && grep -A 10 "## Error Handling" "$agent_file" | grep -q "retry\|timeout\|validation"; then
        score=$((score + 15))
        echo "{\"test\": \"error_handling_specified\", \"passed\": true, \"score\": 15}" >> "$results_file"
    else
        issues+=("Error handling not properly specified")
        echo "{\"test\": \"error_handling_specified\", \"passed\": false, \"score\": 0, \"error\": \"Error handling missing\"}" >> "$results_file"
    fi
    
    # Check for workflow definition
    if grep -A 10 "## Workflow" "$agent_file" | grep -q "[0-9]\\."; then
        score=$((score + 15))
        echo "{\"test\": \"workflow_defined\", \"passed\": true, \"score\": 15}" >> "$results_file"
    else
        issues+=("Workflow not clearly defined")
        echo "{\"test\": \"workflow_defined\", \"passed\": false, \"score\": 0, \"error\": \"Workflow undefined\"}" >> "$results_file"
    fi
    
    # Check for performance considerations
    if grep -q "## Performance" "$agent_file"; then
        score=$((score + 10))
        echo "{\"test\": \"performance_considerations\", \"passed\": true, \"score\": 10}" >> "$results_file"
    else
        issues+=("Performance considerations not documented")
        echo "{\"test\": \"performance_considerations\", \"passed\": false, \"score\": 0, \"error\": \"Performance notes missing\"}" >> "$results_file"
    fi
    
    # Check for behavior rules
    if grep -q "## Behavior Rules" "$agent_file"; then
        score=$((score + 10))
        echo "{\"test\": \"behavior_rules\", \"passed\": true, \"score\": 10}" >> "$results_file"
    else
        issues+=("Behavior rules not specified")
        echo "{\"test\": \"behavior_rules\", \"passed\": false, \"score\": 0, \"error\": \"Behavior rules missing\"}" >> "$results_file"
    fi
    
    local final_score=$(echo "scale=2; $score / $max_score" | bc -l 2>/dev/null || echo "0.0")
    
    echo "{\"validation_level\": \"semantics\", \"score\": $final_score, \"max_score\": 1.0, \"issues\": $(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)}" >> "$results_file"
    
    log_message GREEN "Semantic validation completed. Score: $final_score"
    
    if (( $(echo "$final_score >= 0.7" | bc -l 2>/dev/null || echo "0") )); then
        return 0
    else
        return 1
    fi
}

# Function to validate agent integration compatibility
validate_integration() {
    local agent_file=$1
    local results_file=$2
    
    log_message BLUE "Running integration validation on $agent_file"
    
    local score=0
    local max_score=100
    local issues=()
    
    # Check for message handling specification
    if grep -q "### Incoming Messages" "$agent_file" && grep -q "### Outgoing Messages" "$agent_file"; then
        score=$((score + 25))
        echo "{\"test\": \"message_handling\", \"passed\": true, \"score\": 25}" >> "$results_file"
    else
        issues+=("Message handling not properly specified")
        echo "{\"test\": \"message_handling\", \"passed\": false, \"score\": 0, \"error\": \"Message handling missing\"}" >> "$results_file"
    fi
    
    # Check for dependency specification
    if grep -q "dependencies:" "$agent_file" && grep -q "### Dependencies" "$agent_file"; then
        score=$((score + 20))
        echo "{\"test\": \"dependencies_specified\", \"passed\": true, \"score\": 20}" >> "$results_file"
    else
        issues+=("Dependencies not properly specified")
        echo "{\"test\": \"dependencies_specified\", \"passed\": false, \"score\": 0, \"error\": \"Dependencies missing\"}" >> "$results_file"
    fi
    
    # Check for integration points
    if grep -q "## Integration Points" "$agent_file"; then
        score=$((score + 20))
        echo "{\"test\": \"integration_points\", \"passed\": true, \"score\": 20}" >> "$results_file"
    else
        issues+=("Integration points not documented")
        echo "{\"test\": \"integration_points\", \"passed\": false, \"score\": 0, \"error\": \"Integration points missing\"}" >> "$results_file"
    fi
    
    # Check for tools specification
    if grep -q "tools:" "$agent_file"; then
        score=$((score + 15))
        echo "{\"test\": \"tools_specified\", \"passed\": true, \"score\": 15}" >> "$results_file"
    else
        issues+=("Tools not specified")
        echo "{\"test\": \"tools_specified\", \"passed\": false, \"score\": 0, \"error\": \"Tools missing\"}" >> "$results_file"
    fi
    
    # Check for context requirements
    if grep -q "context_required:" "$agent_file"; then
        score=$((score + 10))
        echo "{\"test\": \"context_requirements\", \"passed\": true, \"score\": 10}" >> "$results_file"
    else
        issues+=("Context requirements not specified")
        echo "{\"test\": \"context_requirements\", \"passed\": false, \"score\": 0, \"error\": \"Context requirements missing\"}" >> "$results_file"
    fi
    
    # Check for output format specification
    if grep -q "output_format:" "$agent_file"; then
        score=$((score + 10))
        echo "{\"test\": \"output_format\", \"passed\": true, \"score\": 10}" >> "$results_file"
    else
        issues+=("Output format not specified")
        echo "{\"test\": \"output_format\", \"passed\": false, \"score\": 0, \"error\": \"Output format missing\"}" >> "$results_file"
    fi
    
    local final_score=$(echo "scale=2; $score / $max_score" | bc -l 2>/dev/null || echo "0.0")
    
    echo "{\"validation_level\": \"integration\", \"score\": $final_score, \"max_score\": 1.0, \"issues\": $(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)}" >> "$results_file"
    
    log_message GREEN "Integration validation completed. Score: $final_score"
    
    if (( $(echo "$final_score >= 0.6" | bc -l 2>/dev/null || echo "0") )); then
        return 0
    else
        return 1
    fi
}

# Function to validate agent performance characteristics
validate_performance() {
    local agent_file=$1
    local results_file=$2
    
    log_message BLUE "Running performance validation on $agent_file"
    
    local score=0
    local max_score=100
    local issues=()
    
    # Check for performance documentation
    if grep -q "## Performance" "$agent_file"; then
        score=$((score + 30))
        echo "{\"test\": \"performance_documented\", \"passed\": true, \"score\": 30}" >> "$results_file"
        
        # Check for specific performance metrics
        if grep -A 10 "## Performance" "$agent_file" | grep -q "time\|memory\|throughput\|latency"; then
            score=$((score + 20))
            echo "{\"test\": \"performance_metrics\", \"passed\": true, \"score\": 20}" >> "$results_file"
        else
            issues+=("Performance metrics not specified")
            echo "{\"test\": \"performance_metrics\", \"passed\": false, \"score\": 0, \"error\": \"Metrics missing\"}" >> "$results_file"
        fi
    else
        issues+=("Performance considerations not documented")
        echo "{\"test\": \"performance_documented\", \"passed\": false, \"score\": 0, \"error\": \"Performance section missing\"}" >> "$results_file"
    fi
    
    # Check for optimization indicators
    if grep -q "optimization\|caching\|parallel\|async\|batch" "$agent_file"; then
        score=$((score + 25))
        echo "{\"test\": \"optimization_features\", \"passed\": true, \"score\": 25}" >> "$results_file"
    else
        issues+=("No optimization features mentioned")
        echo "{\"test\": \"optimization_features\", \"passed\": false, \"score\": 0, \"error\": \"No optimizations\"}" >> "$results_file"
    fi
    
    # Check for resource management
    if grep -q "resource\|cleanup\|memory\|pool" "$agent_file"; then
        score=$((score + 15))
        echo "{\"test\": \"resource_management\", \"passed\": true, \"score\": 15}" >> "$results_file"
    else
        issues+=("Resource management not addressed")
        echo "{\"test\": \"resource_management\", \"passed\": false, \"score\": 0, \"error\": \"Resource management missing\"}" >> "$results_file"
    fi
    
    # Check for timeout handling
    if grep -q "timeout\|deadline\|TTL" "$agent_file"; then
        score=$((score + 10))
        echo "{\"test\": \"timeout_handling\", \"passed\": true, \"score\": 10}" >> "$results_file"
    else
        issues+=("Timeout handling not specified")
        echo "{\"test\": \"timeout_handling\", \"passed\": false, \"score\": 0, \"error\": \"Timeout handling missing\"}" >> "$results_file"
    fi
    
    local final_score=$(echo "scale=2; $score / $max_score" | bc -l 2>/dev/null || echo "0.0")
    
    echo "{\"validation_level\": \"performance\", \"score\": $final_score, \"max_score\": 1.0, \"issues\": $(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)}" >> "$results_file"
    
    log_message GREEN "Performance validation completed. Score: $final_score"
    
    if (( $(echo "$final_score >= 0.5" | bc -l 2>/dev/null || echo "0") )); then
        return 0
    else
        return 1
    fi
}

# Function to run comprehensive validation
validate_agent() {
    local agent_file=$1
    local output_format=${2:-"text"}
    local validation_levels=${3:-"syntax,semantics,integration,performance"}
    
    if [ ! -f "$agent_file" ]; then
        log_message RED "Agent file not found: $agent_file"
        return 1
    fi
    
    local agent_name=$(basename "$agent_file" .md)
    local results_file="$TEST_OUTPUT_DIR/${agent_name}_validation_results.json"
    local timestamp=$(date -Iseconds)
    
    log_message BLUE "Starting comprehensive validation for $agent_name"
    
    # Initialize results file
    echo "{\"agent_name\": \"$agent_name\", \"validation_timestamp\": \"$timestamp\", \"results\": [" > "$results_file"
    
    # Create validation configuration
    create_validation_config
    
    local total_score=0
    local max_total_score=0
    local level_count=0
    local failed_levels=()
    
    # Run validation levels
    IFS=',' read -ra LEVELS <<< "$validation_levels"
    
    for level in "${LEVELS[@]}"; do
        level=$(echo "$level" | xargs)  # trim whitespace
        
        case "$level" in
            "syntax")
                if validate_syntax "$agent_file" "$results_file"; then
                    log_message GREEN " Syntax validation passed"
                else
                    log_message YELLOW "  Syntax validation failed"
                    failed_levels+=("syntax")
                fi
                ;;
            "semantics")
                if validate_semantics "$agent_file" "$results_file"; then
                    log_message GREEN " Semantic validation passed"
                else
                    log_message YELLOW "  Semantic validation failed"
                    failed_levels+=("semantics")
                fi
                ;;
            "integration")
                if validate_integration "$agent_file" "$results_file"; then
                    log_message GREEN " Integration validation passed"
                else
                    log_message YELLOW "  Integration validation failed"
                    failed_levels+=("integration")
                fi
                ;;
            "performance")
                if validate_performance "$agent_file" "$results_file"; then
                    log_message GREEN " Performance validation passed"
                else
                    log_message YELLOW "  Performance validation failed"
                    failed_levels+=("performance")
                fi
                ;;
            *)
                log_message YELLOW "Unknown validation level: $level"
                ;;
        esac
        
        ((level_count++))
    done
    
    # Close results file
    echo "]}" >> "$results_file"
    
    # Calculate overall score
    local overall_score=$(jq -r '[.results[] | select(.validation_level) | .score] | add / length' "$results_file" 2>/dev/null || echo "0.0")
    
    # Record validation results in database
    record_validation_results "$agent_name" "$overall_score" "$results_file"
    
    # Generate report based on format
    case "$output_format" in
        "json")
            cat "$results_file"
            ;;
        "csv")
            generate_csv_report "$results_file"
            ;;
        *)
            generate_text_report "$agent_name" "$overall_score" "${failed_levels[@]}"
            ;;
    esac
    
    # Return appropriate exit code
    if (( $(echo "$overall_score >= 0.75" | bc -l 2>/dev/null || echo "0") )); then
        log_message GREEN "Overall validation: PASSED (score: $overall_score)"
        return 0
    elif (( $(echo "$overall_score >= 0.60" | bc -l 2>/dev/null || echo "0") )); then
        log_message YELLOW "Overall validation: WARNING (score: $overall_score)"
        return 1
    else
        log_message RED "Overall validation: FAILED (score: $overall_score)"
        return 2
    fi
}

# Function to record validation results in database
record_validation_results() {
    local agent_name=$1
    local overall_score=$2
    local results_file=$3
    
    # Get improvement ID if this is validating an improvement
    local improvement_id=""
    improvement_id=$(sqlite3 "$DB_PATH" "SELECT id FROM improvements WHERE agent_name='$agent_name' ORDER BY applied_at DESC LIMIT 1;" 2>/dev/null || echo "")
    
    # Record each test result
    jq -r '.results[] | select(.test) | @json' "$results_file" 2>/dev/null | while IFS= read -r test_result; do
        local test_name=$(echo "$test_result" | jq -r '.test')
        local passed=$(echo "$test_result" | jq -r '.passed')
        local score=$(echo "$test_result" | jq -r '.score // 0')
        local error=$(echo "$test_result" | jq -r '.error // ""')
        
        sqlite3 "$DB_PATH" <<EOF
INSERT INTO validation_results (
    improvement_id,
    test_type,
    test_name,
    passed,
    score,
    details
) VALUES (
    $([ -n "$improvement_id" ] && echo "$improvement_id" || echo "NULL"),
    'validation',
    '$test_name',
    $([ "$passed" = "true" ] && echo "1" || echo "0"),
    $score,
    '$error'
);
EOF
    done
    
    log_message GREEN "Validation results recorded in database"
}

# Function to generate text report
generate_text_report() {
    local agent_name=$1
    local overall_score=$2
    shift 2
    local failed_levels=("$@")
    
    echo ""
    echo "PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP"
    echo "                    AGENT VALIDATION REPORT"
    echo "PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP"
    echo ""
    echo "Agent: $agent_name"
    echo "Validation Date: $(date)"
    echo "Overall Score: $(printf "%.2f" "$overall_score") / 1.00"
    echo ""
    
    if (( $(echo "$overall_score >= 0.75" | bc -l 2>/dev/null || echo "0") )); then
        echo -e "Status: ${GREEN} PASSED${NC}"
        echo "This agent meets all quality standards and is ready for deployment."
    elif (( $(echo "$overall_score >= 0.60" | bc -l 2>/dev/null || echo "0") )); then
        echo -e "Status: ${YELLOW}  WARNING${NC}"
        echo "This agent has minor issues but may be deployed with caution."
    else
        echo -e "Status: ${RED} FAILED${NC}"
        echo "This agent has significant issues and should not be deployed."
    fi
    
    echo ""
    
    if [ ${#failed_levels[@]} -gt 0 ]; then
        echo "Failed Validation Levels:"
        for level in "${failed_levels[@]}"; do
            echo "  - $level"
        done
        echo ""
    fi
    
    echo "Detailed results available in: $TEST_OUTPUT_DIR/${agent_name}_validation_results.json"
    echo ""
    echo "PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP"
}

# Function to generate CSV report
generate_csv_report() {
    local results_file=$1
    
    echo "agent_name,validation_level,test_name,passed,score,error"
    
    jq -r '.results[] | select(.test) | [.agent_name // input_filename, (.validation_level // "unknown"), .test, .passed, .score, (.error // "")] | @csv' "$results_file"
}

# Function to validate multiple agents
validate_batch() {
    local agent_pattern=$1
    local output_format=${2:-"text"}
    local validation_levels=${3:-"syntax,semantics"}
    
    log_message BLUE "Running batch validation with pattern: $agent_pattern"
    
    local total_agents=0
    local passed_agents=0
    local warning_agents=0
    local failed_agents=0
    
    # Find matching agent files
    find "$AGENTS_DIR" -name "$agent_pattern" -type f | while read -r agent_file; do
        if [[ "$agent_file" == *.md ]]; then
            ((total_agents++))
            
            echo ""
            log_message CYAN "Validating $(basename "$agent_file")"
            
            if validate_agent "$agent_file" "$output_format" "$validation_levels"; then
                case $? in
                    0) ((passed_agents++)) ;;
                    1) ((warning_agents++)) ;;
                    *) ((failed_agents++)) ;;
                esac
            else
                ((failed_agents++))
            fi
        fi
    done
    
    echo ""
    echo "PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP"
    echo "                    BATCH VALIDATION SUMMARY"
    echo "PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP"
    echo "Total Agents: $total_agents"
    echo "Passed: $passed_agents"
    echo "Warnings: $warning_agents"
    echo "Failed: $failed_agents"
    echo "PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP"
}

# Function to get validation summary
validation_summary() {
    local period=${1:-"7 days"}
    
    log_message BLUE "Generating validation summary for last $period"
    
    sqlite3 "$DB_PATH" -header -column <<EOF
SELECT 
    COUNT(DISTINCT improvement_id) as total_validations,
    SUM(CASE WHEN passed = 1 THEN 1 ELSE 0 END) as passed_tests,
    SUM(CASE WHEN passed = 0 THEN 1 ELSE 0 END) as failed_tests,
    ROUND(AVG(score), 3) as avg_score,
    COUNT(DISTINCT test_name) as unique_tests
FROM validation_results
WHERE executed_at > datetime('now', '-$period');
EOF
    
    echo ""
    echo "Recent Validation Failures:"
    sqlite3 "$DB_PATH" -header -column <<EOF
SELECT 
    test_name,
    COUNT(*) as failure_count,
    details as common_error
FROM validation_results
WHERE passed = 0
    AND executed_at > datetime('now', '-$period')
GROUP BY test_name, details
ORDER BY failure_count DESC
LIMIT 5;
EOF
}

# Main command processing
case "${1:-help}" in
    validate)
        validate_agent "$2" "${3:-text}" "${4:-syntax,semantics,integration,performance}"
        ;;
    
    batch)
        validate_batch "${2:-*.md}" "${3:-text}" "${4:-syntax,semantics}"
        ;;
    
    summary)
        validation_summary "${2:-7 days}"
        ;;
    
    config)
        create_validation_config
        ;;
    
    *)
        echo "Agent Validator - SubAgentMasterDesigner Component"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  validate <agent_file> [format] [levels]"
        echo "    Validate specific agent file"
        echo "    - format: text|json|csv (default: text)"
        echo "    - levels: comma-separated list (default: syntax,semantics,integration,performance)"
        echo ""
        echo "  batch <pattern> [format] [levels]"
        echo "    Validate multiple agents matching pattern"
        echo ""
        echo "  summary [period]"
        echo "    Show validation summary (default: 7 days)"
        echo ""
        echo "  config"
        echo "    Create validation configuration file"
        echo ""
        echo "Validation Levels:"
        echo "  - syntax: YAML frontmatter, required sections, markdown structure"
        echo "  - semantics: Logical consistency, completeness, coherence"
        echo "  - integration: Dependencies, message handling, compatibility"
        echo "  - performance: Performance considerations, optimizations"
        echo ""
        echo "Examples:"
        echo "  $0 validate agents/core/orchestrator-agent.md"
        echo "  $0 validate agents/generated/test-agent.md json syntax,semantics"
        echo "  $0 batch '*.md' text syntax"
        echo "  $0 summary '30 days'"
        ;;
esac