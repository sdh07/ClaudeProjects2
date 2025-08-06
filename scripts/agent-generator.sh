#!/bin/bash

# Agent Excellence: Agent Generator Module
# Purpose: Generate improved agents from templates and patterns
# Version: 1.0.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DB_PATH="$PROJECT_ROOT/.cpdm/agent-excellence/database/agent-excellence.db"
LEARNING_REPO="$PROJECT_ROOT/.cpdm/agent-excellence/learning-repository"
IMPROVEMENTS_DIR="$PROJECT_ROOT/.cpdm/agent-excellence/improvements"
AGENTS_DIR="$PROJECT_ROOT/agents"

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
Agent Generator Module - SubAgentMasterDesigner

USAGE:
    $0 [COMMAND] [OPTIONS]

COMMANDS:
    apply               Apply pattern improvements to agents
    generate            Generate new agent from template
    upgrade             Upgrade existing agent with patterns
    create              Create new agent with specific capabilities
    version             Manage agent versions
    rollback            Rollback agent to previous version

OPTIONS:
    --agent NAME        Target agent name
    --pattern NAME      Pattern name to apply
    --template NAME     Template name for generation
    --version VERSION   Target version (default: auto-increment)
    --output DIR        Output directory (default: agents/)
    --backup            Create backup before modification
    --force             Force application without validation
    --dry-run           Show changes without applying
    --help              Show this help message

EXAMPLES:
    $0 apply --agent orchestrator-agent --pattern retry-with-backoff
    $0 generate --template base --agent my-new-agent
    $0 upgrade --agent build-agent --pattern parallel-execution
    $0 version --agent test-agent --list
    $0 rollback --agent test-agent --version 1.2.0

EOF
}

# Initialize system
init_system() {
    if [[ ! -f "$DB_PATH" ]]; then
        log_error "Database not found at $DB_PATH"
        exit 1
    fi
    
    if [[ ! -d "$LEARNING_REPO" ]]; then
        log_error "Learning repository not found at $LEARNING_REPO"
        exit 1
    fi
    
    mkdir -p "$IMPROVEMENTS_DIR"
}

# Get current agent version
get_agent_version() {
    local agent_name="$1"
    local agent_file="$AGENTS_DIR/$agent_name.md"
    
    if [[ -f "$agent_file" ]]; then
        grep -E "^version:" "$agent_file" | head -1 | cut -d: -f2 | xargs || echo "1.0.0"
    else
        echo "1.0.0"
    fi
}

# Increment version
increment_version() {
    local version="$1"
    local increment_type="${2:-patch}"  # major, minor, patch
    
    IFS='.' read -ra VERSION_PARTS <<< "$version"
    local major="${VERSION_PARTS[0]:-1}"
    local minor="${VERSION_PARTS[1]:-0}"
    local patch="${VERSION_PARTS[2]:-0}"
    
    case "$increment_type" in
        "major")
            echo "$((major + 1)).0.0"
            ;;
        "minor")
            echo "$major.$((minor + 1)).0"
            ;;
        *)
            echo "$major.$minor.$((patch + 1))"
            ;;
    esac
}

# Create backup of agent
backup_agent() {
    local agent_name="$1"
    local version="$2"
    local agent_file="$AGENTS_DIR/$agent_name.md"
    
    if [[ -f "$agent_file" ]]; then
        local backup_dir="$IMPROVEMENTS_DIR/backups/$agent_name"
        mkdir -p "$backup_dir"
        
        local backup_file="$backup_dir/$agent_name-v$version-$(date +%Y%m%d-%H%M%S).md"
        cp "$agent_file" "$backup_file"
        
        log_info "Backup created: $backup_file"
        echo "$backup_file"
    fi
}

# Get pattern from learning repository
get_pattern() {
    local pattern_name="$1"
    
    # First try database
    local pattern_content=$(sqlite3 "$DB_PATH" "
        SELECT improvement_template 
        FROM learning_patterns 
        WHERE pattern_name = '$pattern_name'
        LIMIT 1
    " 2>/dev/null || echo "")
    
    if [[ -n "$pattern_content" ]]; then
        echo "$pattern_content"
        return
    fi
    
    # Fallback to file system
    local pattern_files=(
        "$LEARNING_REPO/patterns/performance/$pattern_name.json"
        "$LEARNING_REPO/patterns/reliability/$pattern_name.json"
        "$LEARNING_REPO/patterns/integration/$pattern_name.json"
        "$LEARNING_REPO/patterns/workflow/$pattern_name.json"
    )
    
    for pattern_file in "${pattern_files[@]}"; do
        if [[ -f "$pattern_file" ]]; then
            cat "$pattern_file"
            return
        fi
    done
    
    log_error "Pattern not found: $pattern_name"
    return 1
}

# Apply pattern to agent
apply_pattern() {
    local agent_name="$1"
    local pattern_name="$2"
    local dry_run="${3:-false}"
    local force="${4:-false}"
    
    log_info "Applying pattern '$pattern_name' to agent '$agent_name'"
    
    local agent_file="$AGENTS_DIR/$agent_name.md"
    
    if [[ ! -f "$agent_file" ]]; then
        log_error "Agent file not found: $agent_file"
        return 1
    fi
    
    # Get pattern definition
    local pattern_content=$(get_pattern "$pattern_name")
    if [[ -z "$pattern_content" ]]; then
        log_error "Failed to get pattern: $pattern_name"
        return 1
    fi
    
    # Extract pattern information (basic parsing without jq dependency)
    local pattern_type=$(echo "$pattern_content" | grep -o '"pattern_type":[[:space:]]*"[^"]*"' | cut -d'"' -f4)
    local description=$(echo "$pattern_content" | grep -o '"description":[[:space:]]*"[^"]*"' | cut -d'"' -f4)
    
    # Get current version and create backup
    local current_version=$(get_agent_version "$agent_name")
    local new_version=$(increment_version "$current_version" "patch")
    
    if [[ "$dry_run" == "false" ]]; then
        backup_agent "$agent_name" "$current_version"
    fi
    
    # Create improved agent content
    local improved_content=""
    local timestamp=$(date -Iseconds)
    
    # Read existing agent content
    local existing_content=$(cat "$agent_file")
    
    # Apply pattern-specific improvements
    case "$pattern_name" in
        "retry-with-backoff")
            improved_content=$(apply_retry_pattern "$existing_content" "$new_version")
            ;;
        "parallel-execution")
            improved_content=$(apply_parallel_pattern "$existing_content" "$new_version")
            ;;
        "memory-optimization")
            improved_content=$(apply_memory_pattern "$existing_content" "$new_version")
            ;;
        "error-handling-enhancement")
            improved_content=$(apply_error_handling_pattern "$existing_content" "$new_version")
            ;;
        *)
            improved_content=$(apply_generic_pattern "$existing_content" "$pattern_name" "$new_version")
            ;;
    esac
    
    if [[ "$dry_run" == "true" ]]; then
        echo "=== DRY RUN: PROPOSED CHANGES ==="
        echo "Agent: $agent_name"
        echo "Pattern: $pattern_name ($pattern_type)"
        echo "Version: $current_version → $new_version"
        echo "Description: $description"
        echo
        echo "=== IMPROVED AGENT PREVIEW ==="
        echo "$improved_content" | head -30
        echo "... (truncated)"
        return
    fi
    
    # Write improved agent
    echo "$improved_content" > "$agent_file"
    
    # Record improvement in database
    sqlite3 "$DB_PATH" "
    INSERT INTO improvements 
    (agent_name, version_before, version_after, improvement_type, trigger_type, 
     description, applied_at, status)
    VALUES 
    ('$agent_name', '$current_version', '$new_version', '$pattern_type', 'manual',
     'Applied pattern: $pattern_name - $description', '$timestamp', 'testing')
    " 2>/dev/null || log_warn "Failed to record improvement in database"
    
    # Update agent registry
    sqlite3 "$DB_PATH" "
    INSERT OR REPLACE INTO agents 
    (name, version, description, updated_at, improvement_count)
    VALUES 
    ('$agent_name', '$new_version', 'Improved with $pattern_name pattern', 
     '$timestamp', COALESCE((SELECT improvement_count FROM agents WHERE name = '$agent_name'), 0) + 1)
    " 2>/dev/null || log_warn "Failed to update agent registry"
    
    log_success "Pattern applied successfully"
    log_info "Agent: $agent_name updated to version $new_version"
}

# Apply retry-with-backoff pattern
apply_retry_pattern() {
    local content="$1"
    local version="$2"
    
    # Update version in frontmatter
    content=$(echo "$content" | sed "s/^version:.*/version: $version/")
    
    # Add retry logic section to capabilities
    local retry_section='
## Retry Logic

This agent implements exponential backoff retry mechanism for resilient operation:

```bash
# Retry function with exponential backoff
retry_with_backoff() {
    local max_attempts=${1:-3}
    local delay=${2:-1}
    local max_delay=${3:-60}
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if "$@"; then
            return 0
        fi
        
        if [[ $attempt -eq $max_attempts ]]; then
            log_error "All retry attempts failed"
            return 1
        fi
        
        local wait_time=$((delay * (2 ** (attempt - 1))))
        wait_time=$((wait_time > max_delay ? max_delay : wait_time))
        
        log_warn "Attempt $attempt failed, retrying in ${wait_time}s..."
        sleep $wait_time
        ((attempt++))
    done
}

# Usage example:
# retry_with_backoff 3 1 30 curl -s "https://api.example.com/data"
```'
    
    # Insert retry section before the last line
    echo "$content" | sed '$i\'"$retry_section"
}

# Apply parallel-execution pattern
apply_parallel_pattern() {
    local content="$1"
    local version="$2"
    
    # Update version in frontmatter
    content=$(echo "$content" | sed "s/^version:.*/version: $version/")
    
    # Add parallel execution section
    local parallel_section='
## Parallel Execution

This agent supports parallel task execution for improved performance:

```bash
# Parallel execution with job control
execute_parallel() {
    local max_jobs=${1:-4}
    local tasks=("${@:2}")
    local job_count=0
    
    for task in "${tasks[@]}"; do
        # Wait if we have too many background jobs
        while [[ $(jobs -r | wc -l) -ge $max_jobs ]]; do
            sleep 0.1
        done
        
        # Execute task in background
        eval "$task" &
        ((job_count++))
    done
    
    # Wait for all jobs to complete
    wait
    log_info "Completed $job_count parallel tasks"
}

# Usage example:
# tasks=("task1" "task2" "task3" "task4")
# execute_parallel 2 "${tasks[@]}"
```'
    
    echo "$content" | sed '$i\'"$parallel_section"
}

# Apply memory-optimization pattern
apply_memory_pattern() {
    local content="$1"
    local version="$2"
    
    # Update version
    content=$(echo "$content" | sed "s/^version:.*/version: $version/")
    
    # Add memory optimization section
    local memory_section='
## Memory Optimization

This agent implements memory-efficient processing patterns:

```bash
# Memory-efficient batch processing
process_in_batches() {
    local batch_size=${1:-100}
    local input_file="$2"
    local process_func="$3"
    
    local line_count=0
    local batch=()
    
    while IFS= read -r line; do
        batch+=("$line")
        ((line_count++))
        
        if [[ $((line_count % batch_size)) -eq 0 ]]; then
            $process_func "${batch[@]}"
            batch=()
        fi
    done < "$input_file"
    
    # Process remaining items
    if [[ ${#batch[@]} -gt 0 ]]; then
        $process_func "${batch[@]}"
    fi
}

# Memory monitoring
monitor_memory() {
    local pid=${1:-$$}
    ps -o pid,vsz,rss,pcpu,command -p "$pid"
}
```'
    
    echo "$content" | sed '$i\'"$memory_section"
}

# Apply error-handling-enhancement pattern
apply_error_handling_pattern() {
    local content="$1"
    local version="$2"
    
    # Update version
    content=$(echo "$content" | sed "s/^version:.*/version: $version/")
    
    # Add enhanced error handling section
    local error_section='
## Enhanced Error Handling

This agent implements comprehensive error handling and recovery:

```bash
# Error handling with context
handle_error() {
    local error_code=$1
    local error_message="$2"
    local context="$3"
    local timestamp=$(date -Iseconds)
    
    # Log structured error
    {
        echo "ERROR_TIMESTAMP: $timestamp"
        echo "ERROR_CODE: $error_code"
        echo "ERROR_MESSAGE: $error_message"
        echo "ERROR_CONTEXT: $context"
        echo "STACK_TRACE:"
        caller 0
    } >> "$ERROR_LOG"
    
    # Attempt recovery based on error type
    case "$error_code" in
        "NETWORK_ERROR")
            log_warn "Network error detected, implementing retry logic"
            return 2  # Indicate retry needed
            ;;
        "RESOURCE_ERROR")
            log_warn "Resource error detected, cleaning up and retrying"
            cleanup_resources
            return 2
            ;;
        *)
            log_error "Unhandled error: $error_message"
            return 1
            ;;
    esac
}

# Trap handler for cleanup
cleanup_on_exit() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_warn "Agent exiting with code $exit_code, performing cleanup"
        cleanup_resources
    fi
}

trap cleanup_on_exit EXIT
```'
    
    echo "$content" | sed '$i\'"$error_section"
}

# Apply generic pattern
apply_generic_pattern() {
    local content="$1"
    local pattern_name="$2"
    local version="$3"
    
    # Update version
    content=$(echo "$content" | sed "s/^version:.*/version: $version/")
    
    # Add generic improvement section
    local improvement_section="
## Applied Improvement: $pattern_name

This agent has been enhanced with the $pattern_name pattern:

- Improved reliability and performance
- Enhanced error handling capabilities
- Better resource utilization
- Increased operational efficiency

Pattern applied: $(date -Iseconds)
"
    
    echo "$content" | sed '$i\'"$improvement_section"
}

# Generate new agent from template
generate_agent() {
    local template_name="$1"
    local agent_name="$2"
    local output_dir="${3:-$AGENTS_DIR}"
    
    log_info "Generating new agent '$agent_name' from template '$template_name'"
    
    # Find template
    local template_file=""
    local template_paths=(
        "$LEARNING_REPO/templates/base/$template_name.md"
        "$LEARNING_REPO/templates/specialized/$template_name.md"
        "$LEARNING_REPO/templates/composite/$template_name.md"
    )
    
    for template_path in "${template_paths[@]}"; do
        if [[ -f "$template_path" ]]; then
            template_file="$template_path"
            break
        fi
    done
    
    if [[ -z "$template_file" ]]; then
        log_error "Template not found: $template_name"
        return 1
    fi
    
    # Read template and customize
    local template_content=$(cat "$template_file")
    local timestamp=$(date -Iseconds)
    
    # Replace placeholders
    local agent_content=$(echo "$template_content" | \
        sed "s/{{AGENT_NAME}}/$agent_name/g" | \
        sed "s/{{TIMESTAMP}}/$timestamp/g" | \
        sed "s/{{VERSION}}/1.0.0/g")
    
    # Ensure output directory exists
    mkdir -p "$output_dir"
    
    # Write new agent file
    local agent_file="$output_dir/$agent_name.md"
    echo "$agent_content" > "$agent_file"
    
    # Register in database
    sqlite3 "$DB_PATH" "
    INSERT OR REPLACE INTO agents 
    (name, version, description, created_at, status)
    VALUES 
    ('$agent_name', '1.0.0', 'Generated from $template_name template', '$timestamp', 'active')
    " 2>/dev/null || log_warn "Failed to register agent in database"
    
    log_success "Agent generated: $agent_file"
}

# Manage agent versions
manage_versions() {
    local agent_name="$1"
    local action="$2"
    
    case "$action" in
        "list")
            echo "=== VERSION HISTORY: $agent_name ==="
            
            # From database
            sqlite3 -header -column "$DB_PATH" "
            SELECT version_after as version, applied_at, improvement_type, description
            FROM improvements 
            WHERE agent_name = '$agent_name'
            ORDER BY applied_at DESC
            " 2>/dev/null || log_warn "No version history in database"
            
            # From backups
            local backup_dir="$IMPROVEMENTS_DIR/backups/$agent_name"
            if [[ -d "$backup_dir" ]]; then
                echo
                echo "=== AVAILABLE BACKUPS ==="
                ls -la "$backup_dir"
            fi
            ;;
        "current")
            get_agent_version "$agent_name"
            ;;
        *)
            log_error "Unknown version action: $action"
            return 1
            ;;
    esac
}

# Rollback agent to previous version
rollback_agent() {
    local agent_name="$1"
    local target_version="$2"
    
    log_info "Rolling back agent '$agent_name' to version '$target_version'"
    
    local backup_dir="$IMPROVEMENTS_DIR/backups/$agent_name"
    local backup_file=""
    
    # Find backup file for target version
    if [[ -d "$backup_dir" ]]; then
        backup_file=$(find "$backup_dir" -name "*-v$target_version-*.md" | head -1)
    fi
    
    if [[ -z "$backup_file" || ! -f "$backup_file" ]]; then
        log_error "Backup not found for version $target_version"
        return 1
    fi
    
    # Create backup of current version first
    local current_version=$(get_agent_version "$agent_name")
    backup_agent "$agent_name" "$current_version"
    
    # Restore from backup
    local agent_file="$AGENTS_DIR/$agent_name.md"
    cp "$backup_file" "$agent_file"
    
    # Record rollback
    local timestamp=$(date -Iseconds)
    sqlite3 "$DB_PATH" "
    INSERT INTO rollback_history 
    (improvement_id, agent_name, reason, trigger_type, rolled_back_at)
    SELECT i.id, '$agent_name', 'Manual rollback to v$target_version', 'manual', '$timestamp'
    FROM improvements i
    WHERE i.agent_name = '$agent_name' AND i.version_after = '$current_version'
    LIMIT 1
    " 2>/dev/null || log_warn "Failed to record rollback"
    
    log_success "Agent rolled back to version $target_version"
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
        "apply")
            local agent_name=""
            local pattern_name=""
            local dry_run="false"
            local force="false"
            
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --agent)
                        agent_name="$2"
                        shift 2
                        ;;
                    --pattern)
                        pattern_name="$2"
                        shift 2
                        ;;
                    --dry-run)
                        dry_run="true"
                        shift
                        ;;
                    --force)
                        force="true"
                        shift
                        ;;
                    *)
                        shift
                        ;;
                esac
            done
            
            if [[ -z "$agent_name" || -z "$pattern_name" ]]; then
                log_error "Missing required parameters: --agent and --pattern"
                exit 1
            fi
            
            apply_pattern "$agent_name" "$pattern_name" "$dry_run" "$force"
            ;;
        "generate")
            local template_name=""
            local agent_name=""
            local output_dir="$AGENTS_DIR"
            
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --template)
                        template_name="$2"
                        shift 2
                        ;;
                    --agent)
                        agent_name="$2"
                        shift 2
                        ;;
                    --output)
                        output_dir="$2"
                        shift 2
                        ;;
                    *)
                        shift
                        ;;
                esac
            done
            
            if [[ -z "$template_name" || -z "$agent_name" ]]; then
                log_error "Missing required parameters: --template and --agent"
                exit 1
            fi
            
            generate_agent "$template_name" "$agent_name" "$output_dir"
            ;;
        "upgrade")
            # Alias for apply
            "$0" apply "$@"
            ;;
        "version")
            local agent_name=""
            local action="current"
            
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --agent)
                        agent_name="$2"
                        shift 2
                        ;;
                    --list)
                        action="list"
                        shift
                        ;;
                    *)
                        shift
                        ;;
                esac
            done
            
            if [[ -z "$agent_name" ]]; then
                log_error "Missing required parameter: --agent"
                exit 1
            fi
            
            manage_versions "$agent_name" "$action"
            ;;
        "rollback")
            local agent_name=""
            local target_version=""
            
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --agent)
                        agent_name="$2"
                        shift 2
                        ;;
                    --version)
                        target_version="$2"
                        shift 2
                        ;;
                    *)
                        shift
                        ;;
                esac
            done
            
            if [[ -z "$agent_name" || -z "$target_version" ]]; then
                log_error "Missing required parameters: --agent and --version"
                exit 1
            fi
            
            rollback_agent "$agent_name" "$target_version"
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