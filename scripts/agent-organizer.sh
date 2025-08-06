#!/bin/bash
# Agent Organizer - Dynamic Team Composition
# Sprint 8, Day 4: Intelligent agent selection based on capabilities

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
CONTEXT_DB="$PROJECT_ROOT/.cpdm/context/contexts.db"
AGENT_DIR="$PROJECT_ROOT/agents"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Find agents by capability
find_agents_by_capability() {
    local domain="$1"
    local skill="$2"
    local tool="$3"
    
    local query="SELECT DISTINCT name FROM agents WHERE 1=1"
    
    if [ -n "$domain" ]; then
        query="$query AND capabilities LIKE '%\"domains\":%' AND capabilities LIKE '%\"$domain\"%'"
    fi
    
    if [ -n "$skill" ]; then
        query="$query AND capabilities LIKE '%\"skills\":%' AND capabilities LIKE '%\"$skill\"%'"
    fi
    
    if [ -n "$tool" ]; then
        query="$query AND capabilities LIKE '%\"tools\":%' AND capabilities LIKE '%\"$tool\"%'"
    fi
    
    sqlite3 "$CONTEXT_DB" "$query;"
}

# Compose team for task
compose_team() {
    local task_type="$1"
    local requirements="$2"
    
    echo -e "${BLUE}Composing team for task: $task_type${NC}"
    
    local team=()
    
    case "$task_type" in
        "code-review")
            team+=("code-review-agent")
            team+=("test-agent")
            ;;
        "feature-implementation")
            team+=("vision-agent")
            team+=("logical-architect-agent")
            team+=("physical-architect-agent")
            team+=("project-agent")
            ;;
        "sprint-planning")
            team+=("project-agent")
            team+=("methodology-agent")
            team+=("knowledge-agent")
            ;;
        "architecture-design")
            team+=("logical-architect-agent")
            team+=("physical-architect-agent")
            team+=("quality-agent")
            ;;
        "quality-check")
            team+=("quality-agent")
            team+=("test-agent")
            team+=("code-review-agent")
            ;;
        *)
            # Dynamic composition based on requirements
            if echo "$requirements" | grep -q "test"; then
                team+=("test-agent")
            fi
            if echo "$requirements" | grep -q "build"; then
                team+=("build-agent")
            fi
            if echo "$requirements" | grep -q "review"; then
                team+=("code-review-agent")
            fi
            if echo "$requirements" | grep -q "git\|version"; then
                team+=("version-agent")
            fi
            ;;
    esac
    
    # Return team as space-separated list
    echo "${team[@]}"
}

# Get agent performance metrics
get_agent_performance() {
    local agent="$1"
    
    sqlite3 -json "$CONTEXT_DB" <<SQL
SELECT 
    name,
    COALESCE(json_extract(performance, '$.avg_response_time'), 0) as avg_response_time,
    COALESCE(json_extract(performance, '$.success_rate'), 0) as success_rate,
    COALESCE(json_extract(performance, '$.tasks_completed'), 0) as tasks_completed
FROM agents 
WHERE name='$agent';
SQL
}

# Rank agents by performance
rank_agents() {
    local agents=("$@")
    
    echo -e "${BLUE}Ranking agents by performance...${NC}"
    
    # Create temp table for ranking
    sqlite3 "$CONTEXT_DB" <<SQL
CREATE TEMP TABLE IF NOT EXISTS agent_scores (
    name TEXT PRIMARY KEY,
    score REAL
);
SQL
    
    # Calculate scores
    for agent in "${agents[@]}"; do
        sqlite3 "$CONTEXT_DB" <<SQL
INSERT OR REPLACE INTO agent_scores (name, score)
SELECT 
    name,
    (COALESCE(json_extract(performance, '$.success_rate'), 50) * 0.5 +
     (100 - COALESCE(json_extract(performance, '$.avg_response_time'), 5000) / 100) * 0.3 +
     COALESCE(json_extract(performance, '$.tasks_completed'), 0) * 0.2) as score
FROM agents 
WHERE name='$agent';
SQL
    done
    
    # Get ranked list
    sqlite3 "$CONTEXT_DB" \
        "SELECT name FROM agent_scores ORDER BY score DESC;"
}

# Select best agent for task
select_best_agent() {
    local task_type="$1"
    local domain="$2"
    local skill="$3"
    
    echo -e "${BLUE}Selecting best agent for:${NC}"
    echo "  Task: $task_type"
    echo "  Domain: $domain"
    echo "  Skill: $skill"
    
    # Find capable agents
    local capable_agents=$(find_agents_by_capability "$domain" "$skill" "")
    
    if [ -z "$capable_agents" ]; then
        echo -e "${RED}No agents found with required capabilities${NC}"
        return 1
    fi
    
    # Convert to array
    IFS=$'\n' read -r -d '' -a agents_array <<< "$capable_agents" || true
    
    # If only one agent, return it
    if [ ${#agents_array[@]} -eq 1 ]; then
        echo -e "${GREEN}Selected: ${agents_array[0]}${NC}"
        echo "${agents_array[0]}"
        return 0
    fi
    
    # Rank by performance
    local best_agent=$(rank_agents "${agents_array[@]}" | head -1)
    
    echo -e "${GREEN}Selected: $best_agent${NC}"
    echo "$best_agent"
}

# Analyze task requirements
analyze_task() {
    local task_description="$1"
    
    echo -e "${BLUE}Analyzing task requirements...${NC}"
    
    local analysis
    
    # Detect domains
    local domains=()
    if echo "$task_description" | grep -qi "code.review\|review"; then
        domains+=("code-review")
    fi
    if echo "$task_description" | grep -qi "test\|testing"; then
        domains+=("testing")
    fi
    if echo "$task_description" | grep -qi "build\|compile"; then
        domains+=("build-automation")
    fi
    if echo "$task_description" | grep -qi "architecture\|design"; then
        domains+=("architecture")
    fi
    if echo "$task_description" | grep -qi "git\|commit\|push\|pull"; then
        domains+=("version-control")
    fi
    if echo "$task_description" | grep -qi "sprint\|agile\|planning"; then
        domains+=("project-management")
    fi
    
    # Detect skills
    local skills=()
    if echo "$task_description" | grep -qi "analyze\|analysis"; then
        skills+=("analysis")
    fi
    if echo "$task_description" | grep -qi "create\|generate"; then
        skills+=("creation")
    fi
    if echo "$task_description" | grep -qi "optimize\|improve"; then
        skills+=("optimization")
    fi
    if echo "$task_description" | grep -qi "validate\|verify"; then
        skills+=("validation")
    fi
    
    # Build JSON properly (filter empty values)
    local domains_json=$(printf '%s\n' "${domains[@]}" | grep -v '^$' | jq -R . | jq -s . | tr -d '\n')
    local skills_json=$(printf '%s\n' "${skills[@]}" | grep -v '^$' | jq -R . | jq -s . | tr -d '\n')
    local complexity=$([ ${#domains[@]} -gt 2 ] && echo "high" || echo "medium")
    
    analysis=$(jq -n \
        --argjson domains "${domains_json:-[]}" \
        --argjson skills "${skills_json:-[]}" \
        --arg complexity "$complexity" \
        '{domains: $domains, skills: $skills, complexity: $complexity}')
    
    echo "$analysis"
}

# Dynamic team orchestration
orchestrate_team() {
    local task_description="$1"
    local context_id="${2:-}"
    
    echo -e "${YELLOW}=== Dynamic Team Orchestration ===${NC}\n"
    
    # Analyze task
    local analysis=$(analyze_task "$task_description")
    echo -e "${BLUE}Task Analysis:${NC}"
    echo "$analysis" | jq .
    
    # Extract requirements
    local domains=$(echo "$analysis" | jq -r '.domains[]' 2>/dev/null)
    local skills=$(echo "$analysis" | jq -r '.skills[]' 2>/dev/null)
    local complexity=$(echo "$analysis" | jq -r '.complexity' 2>/dev/null)
    
    # Compose team
    local team=()
    
    # Add agents for each domain
    while IFS= read -r domain; do
        if [ -n "$domain" ]; then
            local agent=$(select_best_agent "task" "$domain" "")
            if [ -n "$agent" ]; then
                team+=("$agent")
            fi
        fi
    done <<< "$domains"
    
    # Remove duplicates
    IFS=" " read -r -a team <<< "$(echo "${team[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')"
    
    echo -e "\n${GREEN}Selected Team:${NC}"
    printf '  - %s\n' "${team[@]}"
    
    # Create execution plan
    echo -e "\n${YELLOW}Execution Plan:${NC}"
    
    if [ "$complexity" = "high" ]; then
        echo "1. Parallel execution for independent tasks"
        echo "2. Sequential handoff for dependent tasks"
        echo "3. Aggregation of results by orchestrator"
    else
        echo "1. Sequential execution with context passing"
        echo "2. Each agent updates shared context"
    fi
    
    # Store team composition in context if provided
    if [ -n "$context_id" ]; then
        local team_json=$(printf '%s\n' "${team[@]}" | jq -R . | jq -s .)
        sqlite3 "$CONTEXT_DB" <<SQL
UPDATE contexts 
SET state = json_set(state, '$.team_composition', json('$team_json'))
WHERE id='$context_id';
SQL
        echo -e "\n${GREEN}Team composition stored in context${NC}"
    fi
    
    # Return team
    echo "${team[@]}"
}

# Show agent capabilities matrix
show_capabilities_matrix() {
    echo -e "${YELLOW}=== Agent Capabilities Matrix ===${NC}\n"
    
    sqlite3 -column -header "$CONTEXT_DB" <<SQL
SELECT 
    a.name as Agent,
    substr(json_extract(a.capabilities, '$.domains'), 1, 40) as Domains,
    substr(json_extract(a.capabilities, '$.skills'), 1, 30) as Skills,
    COALESCE(p.success_rate, 95) || '%' as Success
FROM agents a
LEFT JOIN performance_metrics p ON a.id = p.agent_id
ORDER BY a.name;
SQL
}

# Main command handler
case "${1:-help}" in
    find)
        find_agents_by_capability "$2" "$3" "$4"
        ;;
    compose)
        compose_team "$2" "$3"
        ;;
    select)
        select_best_agent "$2" "$3" "$4"
        ;;
    analyze)
        analyze_task "$2"
        ;;
    orchestrate)
        orchestrate_team "$2" "$3"
        ;;
    matrix)
        show_capabilities_matrix
        ;;
    performance)
        get_agent_performance "$2"
        ;;
    help|*)
        echo "Agent Organizer - Dynamic Team Composition"
        echo "Usage: $0 <command> [args...]"
        echo ""
        echo "Commands:"
        echo "  find <domain> <skill> <tool>     - Find agents by capability"
        echo "  compose <task_type> <reqs>        - Compose team for task type"
        echo "  select <task> <domain> <skill>    - Select best agent"
        echo "  analyze <task_description>        - Analyze task requirements"
        echo "  orchestrate <task> [context_id]  - Full team orchestration"
        echo "  matrix                            - Show capabilities matrix"
        echo "  performance <agent>               - Get agent performance"
        ;;
esac