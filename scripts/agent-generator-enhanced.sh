#!/bin/bash

# Agent Generator Enhanced - SubAgentMasterDesigner Component
# Generates improved agents using templates and learning patterns

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DB_PATH="$PROJECT_ROOT/.cpdm/agent-excellence/database/agent-excellence.db"
TEMPLATES_DIR="$PROJECT_ROOT/.cpdm/agent-excellence/templates"
AGENTS_DIR="$PROJECT_ROOT/agents"
LEARNING_REPO="$PROJECT_ROOT/.cpdm/agent-excellence/learning-repository"
TEMP_DIR="/tmp/agent-generator"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Ensure directories exist
mkdir -p "$TEMP_DIR" "$TEMPLATES_DIR" "$LEARNING_REPO/improvements"

# Function to log messages
log_message() {
    local level=$1
    shift
    echo -e "${!level}[$level]${NC} $*"
}

# Function to generate agent from template with improvements
generate_agent() {
    local agent_name=$1
    local template_type=${2:-"base"}
    local improvements=${3:-""}
    local target_dir=${4:-"$AGENTS_DIR"}
    
    log_message BLUE "Generating agent '$agent_name' using template '$template_type'"
    
    # Find template file
    local template_file=""
    if [ -f "$TEMPLATES_DIR/$template_type/${template_type}-agent.md" ]; then
        template_file="$TEMPLATES_DIR/$template_type/${template_type}-agent.md"
    elif [ -f "$TEMPLATES_DIR/base/base-agent.md" ]; then
        template_file="$TEMPLATES_DIR/base/base-agent.md"
        log_message YELLOW "Template '$template_type' not found, using base template"
    else
        log_message RED "No templates found! Creating basic template..."
        create_base_template
        template_file="$TEMPLATES_DIR/base/base-agent.md"
    fi
    
    # Generate agent file path
    local agent_file="$target_dir/generated/$agent_name.md"
    mkdir -p "$(dirname "$agent_file")"
    
    # Process template with substitutions
    process_template "$template_file" "$agent_file" "$agent_name" "$improvements"
    
    # Apply learning patterns if specified
    if [ -n "$improvements" ]; then
        apply_improvement_patterns "$agent_file" "$agent_name" "$improvements"
    fi
    
    # Register agent in database
    register_agent "$agent_name" "$template_type"
    
    log_message GREEN "Generated agent: $agent_file"
}

# Function to process template with variable substitution
process_template() {
    local template_file=$1
    local output_file=$2
    local agent_name=$3
    local improvements=$4
    
    log_message BLUE "Processing template: $template_file"
    
    # Read template content
    local template_content=$(cat "$template_file")
    
    # Generate metadata based on agent name and type
    local agent_type=$(infer_agent_type "$agent_name")
    local capabilities=$(generate_capabilities "$agent_name" "$agent_type")
    local dependencies=$(generate_dependencies "$agent_type")
    local tools=$(generate_tools "$agent_type")
    
    # Perform substitutions
    template_content=$(echo "$template_content" | sed "s/{{agent_name}}/$agent_name/g")
    template_content=$(echo "$template_content" | sed "s/{{version}}/1.0.0/g")
    template_content=$(echo "$template_content" | sed "s/{{description}}/Auto-generated $agent_type agent with SubAgentMasterDesigner/g")
    template_content=$(echo "$template_content" | sed "s/{{capabilities}}/$capabilities/g")
    template_content=$(echo "$template_content" | sed "s/{{dependencies}}/$dependencies/g")
    template_content=$(echo "$template_content" | sed "s/{{tools}}/$tools/g")
    template_content=$(echo "$template_content" | sed "s/{{context_required}}/project state, task queue/g")
    template_content=$(echo "$template_content" | sed "s/{{output_format}}/structured JSON with results and metadata/g")
    
    # Generate specific sections based on agent type
    local purpose=$(generate_purpose "$agent_name" "$agent_type")
    local primary_functions=$(generate_functions "$agent_type")
    local workflow=$(generate_workflow "$agent_type")
    local error_handling=$(generate_error_handling "$agent_type")
    local performance_notes=$(generate_performance_notes "$agent_type")
    local behavior_rules=$(generate_behavior_rules "$agent_type")
    local examples=$(generate_examples "$agent_name" "$agent_type")
    
    # More substitutions
    template_content=$(echo "$template_content" | sed "s/{{purpose}}/$purpose/g")
    template_content=$(echo "$template_content" | sed "s/{{primary_functions}}/$primary_functions/g")
    template_content=$(echo "$template_content" | sed "s/{{capabilities_detail}}/$capabilities/g")
    template_content=$(echo "$template_content" | sed "s/{{incoming_messages}}/Task requests, status updates, error notifications/g")
    template_content=$(echo "$template_content" | sed "s/{{outgoing_messages}}/Task results, progress updates, error reports/g")
    template_content=$(echo "$template_content" | sed "s/{{dependencies_detail}}/$dependencies/g")
    template_content=$(echo "$template_content" | sed "s/{{dependents}}/orchestrator-agent, monitoring systems/g")
    template_content=$(echo "$template_content" | sed "s/{{workflow}}/$workflow/g")
    template_content=$(echo "$template_content" | sed "s/{{error_handling}}/$error_handling/g")
    template_content=$(echo "$template_content" | sed "s/{{performance_notes}}/$performance_notes/g")
    template_content=$(echo "$template_content" | sed "s/{{behavior_rules}}/$behavior_rules/g")
    template_content=$(echo "$template_content" | sed "s/{{examples}}/$examples/g")
    template_content=$(echo "$template_content" | sed "s/{{improvements_history}}//g")
    
    # Write processed template
    echo "$template_content" > "$output_file"
    
    log_message GREEN "Template processed successfully"
}

# Function to infer agent type from name
infer_agent_type() {
    local agent_name=$1
    
    case "$agent_name" in
        *test*|*testing*)
            echo "testing"
            ;;
        *build*|*compile*)
            echo "build"
            ;;
        *deploy*|*deployment*)
            echo "deployment"
            ;;
        *monitor*|*metric*)
            echo "monitoring"
            ;;
        *data*|*analyze*|*analysis*)
            echo "data-analysis"
            ;;
        *code*|*review*)
            echo "code-review"
            ;;
        *security*|*scan*)
            echo "security"
            ;;
        *performance*|*optimize*)
            echo "performance"
            ;;
        *integration*|*api*)
            echo "integration"
            ;;
        *workflow*|*orchestrat*)
            echo "workflow"
            ;;
        *)
            echo "general"
            ;;
    esac
}

# Function to generate capabilities based on agent type
generate_capabilities() {
    local agent_name=$1
    local agent_type=$2
    
    case "$agent_type" in
        testing)
            echo "- Automated test execution\\n- Test result analysis\\n- Coverage reporting\\n- Performance benchmarking"
            ;;
        build)
            echo "- Source code compilation\\n- Dependency management\\n- Build optimization\\n- Artifact generation"
            ;;
        deployment)
            echo "- Environment provisioning\\n- Application deployment\\n- Configuration management\\n- Rollback handling"
            ;;
        monitoring)
            echo "- Metrics collection\\n- Performance monitoring\\n- Alert generation\\n- Dashboard updates"
            ;;
        data-analysis)
            echo "- Data processing\\n- Statistical analysis\\n- Report generation\\n- Trend identification"
            ;;
        code-review)
            echo "- Code quality analysis\\n- Security scanning\\n- Best practice enforcement\\n- Change approval"
            ;;
        security)
            echo "- Vulnerability scanning\\n- Security policy enforcement\\n- Threat detection\\n- Compliance checking"
            ;;
        performance)
            echo "- Performance profiling\\n- Bottleneck identification\\n- Optimization recommendations\\n- Load testing"
            ;;
        integration)
            echo "- Service integration\\n- API management\\n- Data transformation\\n- Protocol handling"
            ;;
        workflow)
            echo "- Task orchestration\\n- Process automation\\n- Resource scheduling\\n- Status tracking"
            ;;
        *)
            echo "- Task execution\\n- Result processing\\n- Error handling\\n- Status reporting"
            ;;
    esac
}

# Function to generate dependencies based on agent type
generate_dependencies() {
    local agent_type=$1
    
    case "$agent_type" in
        testing)
            echo "test-framework, code-coverage-tools"
            ;;
        build)
            echo "compiler, package-manager, build-tools"
            ;;
        deployment)
            echo "container-runtime, configuration-service, environment-manager"
            ;;
        monitoring)
            echo "metrics-collector, alerting-service, dashboard-service"
            ;;
        data-analysis)
            echo "data-source, statistical-engine, reporting-service"
            ;;
        code-review)
            echo "version-control, static-analysis-tools, quality-gate"
            ;;
        security)
            echo "security-scanner, policy-engine, threat-intelligence"
            ;;
        performance)
            echo "profiler, benchmarking-tools, optimization-engine"
            ;;
        integration)
            echo "api-gateway, message-queue, data-transformer"
            ;;
        workflow)
            echo "task-queue, scheduler, state-manager"
            ;;
        *)
            echo "message-queue, state-store"
            ;;
    esac
}

# Function to generate tools based on agent type
generate_tools() {
    local agent_type=$1
    
    case "$agent_type" in
        testing)
            echo "pytest, jest, junit, coverage"
            ;;
        build)
            echo "make, gradle, npm, docker"
            ;;
        deployment)
            echo "kubectl, helm, terraform, ansible"
            ;;
        monitoring)
            echo "prometheus, grafana, elasticsearch, kibana"
            ;;
        data-analysis)
            echo "pandas, numpy, jupyter, matplotlib"
            ;;
        code-review)
            echo "sonarqube, eslint, flake8, bandit"
            ;;
        security)
            echo "nmap, owasp-zap, snyk, clamav"
            ;;
        performance)
            echo "apache-bench, jmeter, profiler, flamegraph"
            ;;
        integration)
            echo "postman, curl, swagger, kafka"
            ;;
        workflow)
            echo "airflow, prefect, celery, redis"
            ;;
        *)
            echo "bash, python, jq, curl"
            ;;
    esac
}

# Additional generator functions
generate_purpose() {
    local agent_name=$1
    local agent_type=$2
    echo "Specialized $agent_type agent responsible for automated $agent_type operations in the ClaudeProjects2 ecosystem."
}

generate_functions() {
    local agent_type=$1
    case "$agent_type" in
        testing)
            echo "1. Execute test suites\\n2. Analyze test results\\n3. Generate coverage reports\\n4. Identify failing tests"
            ;;
        build)
            echo "1. Compile source code\\n2. Manage dependencies\\n3. Generate build artifacts\\n4. Optimize build processes"
            ;;
        *)
            echo "1. Process incoming tasks\\n2. Execute core operations\\n3. Generate results\\n4. Handle error conditions"
            ;;
    esac
}

generate_workflow() {
    local agent_type=$1
    echo "1. Receive task request\\n2. Validate inputs\\n3. Execute $agent_type operations\\n4. Generate results\\n5. Report status"
}

generate_error_handling() {
    local agent_type=$1
    echo "- Input validation with detailed error messages\\n- Retry logic with exponential backoff\\n- Graceful degradation on partial failures\\n- Comprehensive error logging"
}

generate_performance_notes() {
    local agent_type=$1
    echo "- Optimized for concurrent execution\\n- Implements caching for repeated operations\\n- Uses resource pooling where applicable\\n- Monitors execution time and memory usage"
}

generate_behavior_rules() {
    local agent_type=$1
    echo "- Always validate inputs before processing\\n- Provide detailed progress updates\\n- Fail fast on critical errors\\n- Clean up resources after completion"
}

generate_examples() {
    local agent_name=$1
    local agent_type=$2
    echo "## Example Usage\\n\\n\\\`\\\`\\\`bash\\n# Execute $agent_name task\\n./$agent_name.sh --task process --input data.json --output results.json\\n\\\`\\\`\\\`"
}

# Function to apply improvement patterns to generated agent
apply_improvement_patterns() {
    local agent_file=$1
    local agent_name=$2
    local improvements=$3
    
    log_message BLUE "Applying improvement patterns: $improvements"
    
    # Split improvements by comma
    IFS=',' read -ra PATTERNS <<< "$improvements"
    
    for pattern in "${PATTERNS[@]}"; do
        pattern=$(echo "$pattern" | xargs)  # trim whitespace
        apply_single_pattern "$agent_file" "$agent_name" "$pattern"
    done
}

# Function to apply a single improvement pattern
apply_single_pattern() {
    local agent_file=$1
    local agent_name=$2
    local pattern=$3
    
    log_message BLUE "Applying pattern: $pattern"
    
    # Get pattern details from database or files
    local pattern_file="$LEARNING_REPO/patterns/performance/$pattern.json"
    if [ ! -f "$pattern_file" ]; then
        pattern_file="$LEARNING_REPO/patterns/reliability/$pattern.json"
    fi
    if [ ! -f "$pattern_file" ]; then
        pattern_file="$LEARNING_REPO/patterns/integration/$pattern.json"
    fi
    if [ ! -f "$pattern_file" ]; then
        pattern_file="$LEARNING_REPO/patterns/workflow/$pattern.json"
    fi
    
    if [ -f "$pattern_file" ]; then
        # Extract implementation details
        local implementation_before=""
        local implementation_after=""
        
        if command -v jq >/dev/null 2>&1; then
            implementation_before=$(jq -r '.implementation.before // ""' "$pattern_file")
            implementation_after=$(jq -r '.implementation.after // ""' "$pattern_file")
        fi
        
        # Apply pattern-specific improvements
        case "$pattern" in
            "parallel-execution")
                add_parallel_execution_capability "$agent_file"
                ;;
            "retry-with-backoff")
                add_retry_logic "$agent_file"
                ;;
            "memory-optimization")
                add_memory_optimization "$agent_file"
                ;;
            "smart-caching")
                add_caching_capability "$agent_file"
                ;;
            "input-validation")
                add_input_validation "$agent_file"
                ;;
            "error-recovery")
                add_error_recovery "$agent_file"
                ;;
            *)
                log_message YELLOW "Unknown pattern: $pattern"
                ;;
        esac
        
        # Record improvement application
        record_improvement "$agent_name" "$pattern" "Generated with pattern"
        
        log_message GREEN "Applied pattern: $pattern"
    else
        log_message YELLOW "Pattern file not found: $pattern"
    fi
}

# Pattern-specific improvement functions
add_parallel_execution_capability() {
    local agent_file=$1
    
    # Add parallel execution section
    cat >> "$agent_file" <<EOF

## Parallel Execution Optimization
*Applied by SubAgentMasterDesigner*

This agent implements parallel execution for independent operations:
- Batch processing with configurable concurrency
- Async/await patterns for I/O operations  
- Resource pooling for expensive operations
- Progress tracking across parallel tasks

### Implementation
- Uses thread pools or async patterns where applicable
- Implements proper error handling for concurrent operations
- Provides progress aggregation across parallel tasks
- Maintains order when required

EOF
}

add_retry_logic() {
    local agent_file=$1
    
    cat >> "$agent_file" <<EOF

## Retry with Backoff
*Applied by SubAgentMasterDesigner*

Enhanced reliability through intelligent retry mechanisms:
- Exponential backoff with jitter
- Configurable retry limits
- Context-aware retry decisions
- Circuit breaker pattern for repeated failures

### Configuration
- Max retries: 3-5 depending on operation
- Initial delay: 1 second
- Backoff multiplier: 2.0
- Max delay: 30 seconds

EOF
}

add_memory_optimization() {
    local agent_file=$1
    
    cat >> "$agent_file" <<EOF

## Memory Optimization
*Applied by SubAgentMasterDesigner*

Optimized memory usage through:
- Streaming data processing where possible
- Chunked processing for large datasets
- Explicit resource cleanup
- Memory usage monitoring and limits

### Features
- Generator patterns for large data sets
- Configurable chunk sizes
- Automatic garbage collection triggers
- Memory pressure detection

EOF
}

add_caching_capability() {
    local agent_file=$1
    
    cat >> "$agent_file" <<EOF

## Smart Caching
*Applied by SubAgentMasterDesigner*

Intelligent caching system with:
- TTL-based cache invalidation
- Size-based cache eviction
- Cache hit ratio monitoring
- Context-aware caching strategies

### Cache Configuration
- Default TTL: 5 minutes
- Max cache size: 1000 entries
- Hit ratio target: >80%
- Automatic cache warming

EOF
}

add_input_validation() {
    local agent_file=$1
    
    cat >> "$agent_file" <<EOF

## Input Validation Enhancement
*Applied by SubAgentMasterDesigner*

Comprehensive input validation:
- Schema-based validation
- Type checking and conversion
- Range and format validation
- Sanitization for security

### Validation Rules
- All inputs validated before processing
- Detailed error messages for invalid inputs
- Automatic type coercion where safe
- Input logging for debugging

EOF
}

add_error_recovery() {
    local agent_file=$1
    
    cat >> "$agent_file" <<EOF

## Error Recovery System
*Applied by SubAgentMasterDesigner*

Robust error recovery mechanisms:
- Checkpoint/resume capability
- Graceful degradation strategies
- State persistence across failures
- Recovery workflow automation

### Recovery Features
- Automatic state checkpointing
- Resume from last successful checkpoint
- Partial result preservation
- Recovery time optimization

EOF
}

# Function to register agent in database
register_agent() {
    local agent_name=$1
    local template_type=$2
    
    sqlite3 "$DB_PATH" <<EOF
INSERT OR REPLACE INTO agents (
    name,
    version,
    description,
    status,
    improvement_count
) VALUES (
    '$agent_name',
    '1.0.0',
    'Auto-generated agent using $template_type template',
    'testing',
    0
);
EOF
    
    log_message GREEN "Registered agent in database: $agent_name"
}

# Function to record improvement application
record_improvement() {
    local agent_name=$1
    local pattern=$2
    local description=$3
    
    sqlite3 "$DB_PATH" <<EOF
INSERT INTO improvements (
    agent_name,
    version_before,
    version_after,
    improvement_type,
    trigger_type,
    description,
    status
) VALUES (
    '$agent_name',
    '1.0.0',
    '1.0.0',
    'capability',
    'technology',
    'Applied $pattern pattern: $description',
    'deployed'
);
EOF
}

# Function to create base template if missing
create_base_template() {
    local base_template="$TEMPLATES_DIR/base/base-agent.md"
    mkdir -p "$(dirname "$base_template")"
    
    cat > "$base_template" <<'EOF'
---
name: {{agent_name}}
description: {{description}}
version: {{version}}
dependencies: {{dependencies}}
capabilities: {{capabilities}}
tools: {{tools}}
context_required: {{context_required}}
output_format: {{output_format}}
---

# {{agent_name}} Agent

## Core Purpose
{{purpose}}

## Primary Functions
{{primary_functions}}

## Capabilities
{{capabilities_detail}}

## Message Handling

### Incoming Messages
{{incoming_messages}}

### Outgoing Messages  
{{outgoing_messages}}

## Integration Points

### Dependencies
{{dependencies_detail}}

### Dependents
{{dependents}}

## Workflow
{{workflow}}

## Error Handling
{{error_handling}}

## Performance Considerations
{{performance_notes}}

## Behavior Rules
{{behavior_rules}}

## Examples
{{examples}}

## Improvements Applied
<!-- Auto-generated by SubAgentMasterDesigner -->
{{improvements_history}}
EOF
    
    log_message GREEN "Created base template: $base_template"
}

# Function to improve existing agent
improve_agent() {
    local agent_name=$1
    local patterns=$2
    local backup=${3:-true}
    
    log_message BLUE "Improving existing agent: $agent_name"
    
    # Find existing agent file
    local agent_file=""
    for dir in "$AGENTS_DIR"/*; do
        if [ -f "$dir/$agent_name.md" ]; then
            agent_file="$dir/$agent_name.md"
            break
        fi
    done
    
    if [ -z "$agent_file" ]; then
        log_message RED "Agent not found: $agent_name"
        return 1
    fi
    
    # Create backup if requested
    if [ "$backup" = true ]; then
        cp "$agent_file" "$agent_file.bak.$(date +%Y%m%d_%H%M%S)"
        log_message GREEN "Created backup: $agent_file.bak.*"
    fi
    
    # Apply improvements
    apply_improvement_patterns "$agent_file" "$agent_name" "$patterns"
    
    # Update version in frontmatter
    local current_version=$(grep "version:" "$agent_file" | head -1 | cut -d: -f2 | xargs)
    if [ -n "$current_version" ]; then
        local new_version=$(echo "$current_version" | awk -F. '{$NF = $NF + 1; print}' OFS=.)
        sed -i "s/version: $current_version/version: $new_version/" "$agent_file"
        log_message GREEN "Updated version: $current_version -> $new_version"
    fi
    
    log_message GREEN "Improved agent: $agent_file"
}

# Function to generate agent from failure analysis
generate_from_failures() {
    local agent_name=$1
    local analysis_period=${2:-"7 days"}
    
    log_message BLUE "Generating improved agent from failure analysis"
    
    # Analyze recent failures
    local failure_patterns=$(sqlite3 "$DB_PATH" -json <<EOF
SELECT 
    failure_type,
    error_message,
    frequency,
    context
FROM agent_failures
WHERE agent_name = '$agent_name'
    AND last_occurrence > datetime('now', '-$analysis_period')
    AND resolved = 0
ORDER BY frequency DESC
LIMIT 5;
EOF
)
    
    # Determine improvement patterns based on failures
    local suggested_patterns=""
    
    if echo "$failure_patterns" | grep -q "timeout\|connection"; then
        suggested_patterns="${suggested_patterns},retry-with-backoff"
    fi
    
    if echo "$failure_patterns" | grep -q "memory\|resource"; then
        suggested_patterns="${suggested_patterns},memory-optimization"
    fi
    
    if echo "$failure_patterns" | grep -q "parallel\|concurrent"; then
        suggested_patterns="${suggested_patterns},parallel-execution"
    fi
    
    # Default to input validation if no specific patterns detected
    if [ -z "$suggested_patterns" ]; then
        suggested_patterns="input-validation"
    else
        suggested_patterns=$(echo "$suggested_patterns" | sed 's/^,//')
    fi
    
    log_message YELLOW "Suggested patterns based on failures: $suggested_patterns"
    
    # Generate improved agent
    generate_agent "${agent_name}-improved" "base" "$suggested_patterns"
}

# Function to clone and improve agent
clone_and_improve() {
    local source_agent=$1
    local target_agent=$2
    local patterns=$3
    
    log_message BLUE "Cloning agent $source_agent to $target_agent with improvements"
    
    # Find source agent
    local source_file=""
    for dir in "$AGENTS_DIR"/*; do
        if [ -f "$dir/$source_agent.md" ]; then
            source_file="$dir/$source_agent.md"
            break
        fi
    done
    
    if [ -z "$source_file" ]; then
        log_message RED "Source agent not found: $source_agent"
        return 1
    fi
    
    # Create target file
    local target_file="$AGENTS_DIR/generated/$target_agent.md"
    mkdir -p "$(dirname "$target_file")"
    
    # Copy source to target with name replacement
    sed "s/name: $source_agent/name: $target_agent/g" "$source_file" > "$target_file"
    sed -i "s/# $source_agent Agent/# $target_agent Agent/g" "$target_file"
    
    # Apply improvements
    apply_improvement_patterns "$target_file" "$target_agent" "$patterns"
    
    # Register in database
    register_agent "$target_agent" "cloned"
    
    log_message GREEN "Cloned and improved agent: $target_file"
}

# Main command processing
case "${1:-help}" in
    generate)
        generate_agent "$2" "${3:-base}" "$4" "$5"
        ;;
    
    improve)
        improve_agent "$2" "$3" "${4:-true}"
        ;;
    
    from-failures)
        generate_from_failures "$2" "${3:-7 days}"
        ;;
        
    clone)
        clone_and_improve "$2" "$3" "$4"
        ;;
        
    template)
        create_base_template
        ;;
        
    *)
        echo "Agent Generator Enhanced - SubAgentMasterDesigner Component"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  generate <name> [template] [patterns] [output_dir]"
        echo "    Generate new agent from template with optional patterns"
        echo ""
        echo "  improve <agent> <patterns> [backup]"
        echo "    Apply improvement patterns to existing agent"
        echo ""
        echo "  from-failures <agent> [period]"
        echo "    Generate improved agent based on failure analysis"
        echo ""
        echo "  clone <source> <target> <patterns>"
        echo "    Clone existing agent and apply improvements"
        echo ""
        echo "  template"
        echo "    Create base template if missing"
        echo ""
        echo "Available patterns:"
        echo "  - parallel-execution: Improve performance through parallelization"
        echo "  - retry-with-backoff: Add resilient retry logic"
        echo "  - memory-optimization: Optimize memory usage"
        echo "  - smart-caching: Add intelligent caching"
        echo "  - input-validation: Enhance input validation"
        echo "  - error-recovery: Add error recovery capabilities"
        echo ""
        echo "Examples:"
        echo "  $0 generate data-processor-v2 base parallel-execution,smart-caching"
        echo "  $0 improve build-agent retry-with-backoff"
        echo "  $0 from-failures test-runner"
        echo "  $0 clone orchestrator-agent orchestrator-enhanced parallel-execution"
        ;;
esac