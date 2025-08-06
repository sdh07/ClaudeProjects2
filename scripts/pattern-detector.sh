#!/bin/bash

# Agent Excellence: Pattern Detector Module
# Purpose: Detect applicable learning patterns for agent improvements
# Version: 1.0.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DB_PATH="$PROJECT_ROOT/.cpdm/agent-excellence/database/agent-excellence.db"
LEARNING_REPO="$PROJECT_ROOT/.cpdm/agent-excellence/learning-repository"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

# Usage information
usage() {
    cat << EOF
Pattern Detector Module - SubAgentMasterDesigner

USAGE:
    $0 [COMMAND] [OPTIONS]

COMMANDS:
    scan               Scan for applicable improvement patterns
    match              Match specific agent issues to patterns
    suggest            Suggest patterns for performance improvement
    analyze            Analyze pattern effectiveness and usage
    update             Update pattern metadata from database
    load               Load patterns from repository to database

OPTIONS:
    --agent NAME       Focus on specific agent
    --type TYPE        Pattern type: performance|reliability|integration|workflow
    --threshold N      Confidence threshold (0.0-1.0, default: 0.7)
    --format FORMAT    Output format: text|json|csv (default: text)
    --output FILE      Write output to file
    --force            Force pattern application even if risky
    --help             Show this help message

EXAMPLES:
    $0 scan --agent orchestrator-agent --threshold 0.8
    $0 match --type performance --format json
    $0 suggest --agent build-agent --output /tmp/suggestions.txt
    $0 analyze --type reliability

EOF
}

# Initialize database and learning repository
init_system() {
    if [[ ! -f "$DB_PATH" ]]; then
        log_error "Database not found at $DB_PATH"
        log_error "Run './scripts/cpdm-workflow-engine.sh init' first"
        exit 1
    fi
    
    if [[ ! -d "$LEARNING_REPO" ]]; then
        log_error "Learning repository not found at $LEARNING_REPO"
        exit 1
    fi
}

# Load patterns from repository to database
load_patterns() {
    log_info "Loading patterns from learning repository to database"
    
    local pattern_count=0
    
    # Find all pattern JSON files
    find "$LEARNING_REPO/patterns" -name "*.json" -type f | while read -r pattern_file; do
        if [[ -f "$pattern_file" ]]; then
            local pattern_content=$(cat "$pattern_file")
            
            # Extract pattern metadata using jq if available, otherwise use basic parsing
            if command -v jq >/dev/null 2>&1; then
                local pattern_name=$(echo "$pattern_content" | jq -r '.pattern_name // empty')
                local pattern_type=$(echo "$pattern_content" | jq -r '.pattern_type // empty')
                local description=$(echo "$pattern_content" | jq -r '.description // empty')
                local success_rate=$(echo "$pattern_content" | jq -r '.metrics.success_rate // "0%" | ltrimstr("%") | tonumber / 100' 2>/dev/null || echo "0.0")
                local confidence=$(echo "$pattern_content" | jq -r '.confidence_score // 0.7')
                
                if [[ -n "$pattern_name" && -n "$pattern_type" ]]; then
                    # Insert or update pattern in database
                    sqlite3 "$DB_PATH" "
                    INSERT OR REPLACE INTO learning_patterns 
                    (pattern_name, pattern_type, pattern_description, applicability_criteria, 
                     improvement_template, success_rate, confidence_score, created_at)
                    VALUES 
                    ('$pattern_name', '$pattern_type', '$description', '$pattern_content', 
                     '$pattern_content', $success_rate, $confidence, datetime('now'))
                    " 2>/dev/null || log_warn "Failed to load pattern: $pattern_name"
                    
                    ((pattern_count++))
                    log_info "Loaded pattern: $pattern_name ($pattern_type)"
                fi
            else
                log_warn "jq not available, skipping pattern parsing for $pattern_file"
            fi
        fi
    done
    
    log_success "Loaded $pattern_count patterns into database"
}

# Scan for applicable patterns
scan_patterns() {
    local agent_filter=""
    local type_filter=""
    local threshold=0.7
    local format="text"
    local output_file=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --agent)
                agent_filter="$2"
                shift 2
                ;;
            --type)
                type_filter="$2"
                shift 2
                ;;
            --threshold)
                threshold="$2"
                shift 2
                ;;
            --format)
                format="$2"
                shift 2
                ;;
            --output)
                output_file="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    log_info "Scanning for applicable patterns (threshold: $threshold)"
    
    # Get agents with performance issues
    local problem_agents_query="
    SELECT DISTINCT agent_name,
           ROUND((SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as success_rate,
           ROUND(AVG(execution_time_ms), 2) as avg_time_ms,
           COUNT(DISTINCT error_type) as error_types
    FROM agent_metrics 
    WHERE timestamp > datetime('now', '-7 days')
    $(if [[ -n "$agent_filter" ]]; then echo "AND agent_name = '$agent_filter'"; fi)
    GROUP BY agent_name
    HAVING success_rate < 95 OR avg_time_ms > 3000
    ORDER BY success_rate ASC, avg_time_ms DESC
    "
    
    # Get applicable patterns
    local patterns_query="
    SELECT pattern_name, pattern_type, pattern_description, confidence_score, success_rate
    FROM learning_patterns
    WHERE confidence_score >= $threshold
    $(if [[ -n "$type_filter" ]]; then echo "AND pattern_type = '$type_filter'"; fi)
    ORDER BY confidence_score DESC, success_rate DESC
    "
    
    local output=""
    
    if [[ "$format" == "text" ]]; then
        output+="=== PATTERN DETECTION SCAN ===\n\n"
        output+="Scan Date: $(date)\n"
        output+="Confidence Threshold: $threshold\n"
        output+="$(if [[ -n "$agent_filter" ]]; then echo "Agent Filter: $agent_filter"; fi)\n"
        output+="$(if [[ -n "$type_filter" ]]; then echo "Type Filter: $type_filter"; fi)\n\n"
        
        output+="=== AGENTS WITH ISSUES ===\n"
        output+="$(sqlite3 -header -column "$DB_PATH" "$problem_agents_query")\n\n"
        
        output+="=== APPLICABLE PATTERNS ===\n"
        output+="$(sqlite3 -header -column "$DB_PATH" "$patterns_query")\n\n"
        
        # Generate matches
        output+="=== PATTERN MATCHES ===\n"
        
        # Read problem agents and match with patterns
        sqlite3 "$DB_PATH" "$problem_agents_query" | tail -n +2 | while IFS='|' read -r agent success_rate avg_time error_types; do
            agent=$(echo "$agent" | xargs)  # trim whitespace
            success_rate=$(echo "$success_rate" | xargs)
            avg_time=$(echo "$avg_time" | xargs)
            
            output+="Agent: $agent (Success: $success_rate%, Avg Time: ${avg_time}ms)\n"
            
            # Suggest performance patterns for slow agents
            if (( $(echo "$avg_time > 3000" | bc -l 2>/dev/null || echo "0") )); then
                output+="  → SUGGESTED: parallel-execution (performance optimization)\n"
            fi
            
            # Suggest reliability patterns for low success rate
            if (( $(echo "$success_rate < 95" | bc -l 2>/dev/null || echo "0") )); then
                output+="  → SUGGESTED: retry-with-backoff (reliability improvement)\n"
            fi
            
            output+="\n"
        done
        
    elif [[ "$format" == "json" ]]; then
        # Generate JSON output with matches
        output='{"scan_date": "'$(date -Iseconds)'", "threshold": '$threshold', "agents": [], "patterns": [], "matches": []}'
        
        # Note: Full JSON implementation would require more complex processing
        # For now, provide basic structure
        
    else
        # CSV format
        output="agent_name,issue_type,suggested_pattern,confidence,reason\n"
        
        sqlite3 "$DB_PATH" "$problem_agents_query" | tail -n +2 | while IFS='|' read -r agent success_rate avg_time error_types; do
            agent=$(echo "$agent" | xargs)
            success_rate=$(echo "$success_rate" | xargs)
            avg_time=$(echo "$avg_time" | xargs)
            
            if (( $(echo "$avg_time > 3000" | bc -l 2>/dev/null || echo "0") )); then
                output+="$agent,performance,parallel-execution,0.85,slow_execution\n"
            fi
            
            if (( $(echo "$success_rate < 95" | bc -l 2>/dev/null || echo "0") )); then
                output+="$agent,reliability,retry-with-backoff,0.90,low_success_rate\n"
            fi
        done
    fi
    
    if [[ -n "$output_file" ]]; then
        echo -e "$output" > "$output_file"
        log_success "Scan results saved to $output_file"
    else
        echo -e "$output"
    fi
}

# Match specific agent issues to patterns
match_issues() {
    local agent_filter=""
    local type_filter=""
    local format="text"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --agent)
                agent_filter="$2"
                shift 2
                ;;
            --type)
                type_filter="$2"
                shift 2
                ;;
            --format)
                format="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    log_info "Matching agent issues to learning patterns"
    
    # Get recent failures and their patterns
    local failures_query="
    SELECT af.agent_name, af.failure_type, af.error_message, af.frequency, af.resolved
    FROM agent_failures af
    WHERE af.last_occurrence > datetime('now', '-7 days')
    $(if [[ -n "$agent_filter" ]]; then echo "AND af.agent_name = '$agent_filter'"; fi)
    AND af.resolved = 0
    ORDER BY af.frequency DESC
    "
    
    if [[ "$format" == "text" ]]; then
        echo "=== ISSUE-PATTERN MATCHING ==="
        echo
        echo "Recent Failures:"
        sqlite3 -header -column "$DB_PATH" "$failures_query"
        echo
        echo "=== PATTERN RECOMMENDATIONS ==="
        
        # Match failures to patterns
        sqlite3 "$DB_PATH" "$failures_query" | tail -n +2 | while IFS='|' read -r agent failure_type error_msg frequency resolved; do
            agent=$(echo "$agent" | xargs)
            failure_type=$(echo "$failure_type" | xargs)
            frequency=$(echo "$frequency" | xargs)
            
            echo "Agent: $agent"
            echo "  Issue: $failure_type (frequency: $frequency)"
            
            # Pattern matching logic
            case "$failure_type" in
                *timeout*|*connection*|*network*)
                    echo "  → MATCH: retry-with-backoff (reliability pattern)"
                    echo "    Reason: Network/timeout failures benefit from retry logic"
                    ;;
                *memory*|*resource*)
                    echo "  → MATCH: memory-optimization (performance pattern)"
                    echo "    Reason: Resource exhaustion detected"
                    ;;
                *parallel*|*concurrent*)
                    echo "  → MATCH: parallel-execution (performance pattern)"
                    echo "    Reason: Concurrency issues, need better parallelization"
                    ;;
                *)
                    echo "  → MATCH: error-handling-enhancement (reliability pattern)"
                    echo "    Reason: General error handling improvement needed"
                    ;;
            esac
            echo
        done
    else
        sqlite3 -json "$DB_PATH" "$failures_query" 2>/dev/null || sqlite3 -csv -header "$DB_PATH" "$failures_query"
    fi
}

# Suggest patterns for improvement
suggest_patterns() {
    local agent_filter=""
    local format="text"
    local output_file=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --agent)
                agent_filter="$2"
                shift 2
                ;;
            --format)
                format="$2"
                shift 2
                ;;
            --output)
                output_file="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    log_info "Generating pattern suggestions"
    
    local suggestions=""
    
    # Performance suggestions based on metrics
    local slow_agents=$(sqlite3 "$DB_PATH" "
    SELECT agent_name, ROUND(AVG(execution_time_ms), 2) as avg_time
    FROM agent_metrics 
    WHERE timestamp > datetime('now', '-7 days')
    $(if [[ -n "$agent_filter" ]]; then echo "AND agent_name = '$agent_filter'"; fi)
    GROUP BY agent_name
    HAVING avg_time > 3000
    ORDER BY avg_time DESC
    " | head -5)
    
    if [[ -n "$slow_agents" ]]; then
        suggestions+="=== PERFORMANCE IMPROVEMENT SUGGESTIONS ===\n\n"
        echo "$slow_agents" | while IFS='|' read -r agent avg_time; do
            suggestions+="Agent: $agent (Avg: ${avg_time}ms)\n"
            suggestions+="  Pattern: parallel-execution\n"
            suggestions+="  Benefit: 60-80% performance improvement\n"
            suggestions+="  Risk: Medium (increased memory usage)\n\n"
        done
    fi
    
    # Reliability suggestions based on failures
    local unreliable_agents=$(sqlite3 "$DB_PATH" "
    SELECT agent_name, ROUND((SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as success_rate
    FROM agent_metrics 
    WHERE timestamp > datetime('now', '-7 days')
    $(if [[ -n "$agent_filter" ]]; then echo "AND agent_name = '$agent_filter'"; fi)
    GROUP BY agent_name
    HAVING success_rate < 95
    ORDER BY success_rate ASC
    " | head -5)
    
    if [[ -n "$unreliable_agents" ]]; then
        suggestions+="=== RELIABILITY IMPROVEMENT SUGGESTIONS ===\n\n"
        echo "$unreliable_agents" | while IFS='|' read -r agent success_rate; do
            suggestions+="Agent: $agent (Success: ${success_rate}%)\n"
            suggestions+="  Pattern: retry-with-backoff\n"
            suggestions+="  Benefit: 20-40% reliability improvement\n"
            suggestions+="  Risk: Low (increased latency)\n\n"
        done
    fi
    
    if [[ -z "$suggestions" ]]; then
        suggestions="No specific improvement patterns suggested. System performing within acceptable parameters."
    fi
    
    if [[ -n "$output_file" ]]; then
        echo -e "$suggestions" > "$output_file"
        log_success "Suggestions saved to $output_file"
    else
        echo -e "$suggestions"
    fi
}

# Analyze pattern effectiveness
analyze_patterns() {
    local type_filter=""
    local format="text"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --type)
                type_filter="$2"
                shift 2
                ;;
            --format)
                format="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    log_info "Analyzing pattern effectiveness"
    
    local patterns_query="
    SELECT 
        pattern_name,
        pattern_type,
        usage_count,
        ROUND(success_rate * 100, 2) as success_rate_percent,
        ROUND(avg_performance_gain, 2) as avg_gain,
        ROUND(confidence_score, 2) as confidence,
        CASE 
            WHEN last_used IS NULL THEN 'Never'
            ELSE datetime(last_used, 'localtime')
        END as last_used
    FROM learning_patterns
    $(if [[ -n "$type_filter" ]]; then echo "WHERE pattern_type = '$type_filter'"; fi)
    ORDER BY confidence_score DESC, success_rate DESC
    "
    
    if [[ "$format" == "text" ]]; then
        echo "=== PATTERN EFFECTIVENESS ANALYSIS ==="
        echo
        sqlite3 -header -column "$DB_PATH" "$patterns_query"
        
        echo
        echo "=== PATTERN USAGE SUMMARY ==="
        
        local summary_query="
        SELECT 
            pattern_type,
            COUNT(*) as total_patterns,
            ROUND(AVG(success_rate * 100), 2) as avg_success_rate,
            SUM(usage_count) as total_usage
        FROM learning_patterns
        GROUP BY pattern_type
        ORDER BY avg_success_rate DESC
        "
        
        sqlite3 -header -column "$DB_PATH" "$summary_query"
        
    else
        case "$format" in
            "json")
                sqlite3 -json "$DB_PATH" "$patterns_query"
                ;;
            "csv")
                sqlite3 -csv -header "$DB_PATH" "$patterns_query"
                ;;
        esac
    fi
}

# Update pattern metadata from database
update_patterns() {
    log_info "Updating pattern metadata from improvement results"
    
    # Update success rates based on improvement results
    local update_query="
    UPDATE learning_patterns SET
        success_rate = (
            SELECT COALESCE(AVG(
                CASE WHEN validation_score > 0.8 THEN 1.0 ELSE 0.0 END
            ), success_rate)
            FROM improvements i
            WHERE i.description LIKE '%' || learning_patterns.pattern_name || '%'
        ),
        usage_count = (
            SELECT COALESCE(COUNT(*), usage_count)
            FROM improvements i
            WHERE i.description LIKE '%' || learning_patterns.pattern_name || '%'
        ),
        last_used = (
            SELECT MAX(applied_at)
            FROM improvements i
            WHERE i.description LIKE '%' || learning_patterns.pattern_name || '%'
        )
    WHERE EXISTS (
        SELECT 1 FROM improvements i
        WHERE i.description LIKE '%' || learning_patterns.pattern_name || '%'
    )
    "
    
    sqlite3 "$DB_PATH" "$update_query"
    
    # Update confidence scores based on recent performance
    local confidence_update="
    UPDATE learning_patterns SET
        confidence_score = CASE
            WHEN success_rate > 0.9 AND usage_count > 5 THEN 0.95
            WHEN success_rate > 0.8 AND usage_count > 3 THEN 0.85
            WHEN success_rate > 0.7 AND usage_count > 1 THEN 0.75
            WHEN success_rate > 0.5 THEN 0.65
            ELSE 0.5
        END
    "
    
    sqlite3 "$DB_PATH" "$confidence_update"
    
    log_success "Pattern metadata updated"
}

# Main function
main() {
    if [[ $# -eq 0 ]]; then
        usage
        exit 1
    fi
    
    init_system
    
    local command="$1"
    shift
    
    case "$command" in
        "load")
            load_patterns "$@"
            ;;
        "scan")
            scan_patterns "$@"
            ;;
        "match")
            match_issues "$@"
            ;;
        "suggest")
            suggest_patterns "$@"
            ;;
        "analyze")
            analyze_patterns "$@"
            ;;
        "update")
            update_patterns "$@"
            ;;
        "--help"|"help")
            usage
            ;;
        *)
            log_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi