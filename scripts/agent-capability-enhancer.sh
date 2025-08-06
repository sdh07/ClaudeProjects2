#!/bin/bash
# Agent Capability Enhancement Script
# Sprint 8, Day 2: Add capability metadata to all agents

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENTS_DIR="$PROJECT_ROOT/agents"
CAPABILITY_DB="$PROJECT_ROOT/.cpdm/context/contexts.db"
CAPABILITY_REGISTRY="$PROJECT_ROOT/.cpdm/config/agent-capabilities.json"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Agent Capability Enhancement${NC}"
echo "============================="

# Define capability taxonomy
cat > "$PROJECT_ROOT/.cpdm/config/capability-taxonomy.json" <<'EOF'
{
  "domains": [
    "architecture",
    "code-generation",
    "code-review",
    "testing",
    "deployment",
    "documentation",
    "project-management",
    "version-control",
    "quality-assurance",
    "context-management",
    "orchestration",
    "analytics",
    "knowledge-management",
    "process-automation",
    "learning",
    "feedback-processing"
  ],
  "skills": [
    "analysis",
    "synthesis",
    "validation",
    "generation",
    "transformation",
    "optimization",
    "monitoring",
    "reporting",
    "planning",
    "execution",
    "coordination",
    "persistence",
    "recovery",
    "pattern-recognition",
    "decision-making"
  ],
  "tools": [
    "Read",
    "Write",
    "Edit",
    "MultiEdit",
    "Bash",
    "Grep",
    "Glob",
    "Task",
    "TodoWrite",
    "WebFetch",
    "WebSearch",
    "git",
    "sqlite3",
    "jq",
    "gh"
  ]
}
EOF

echo -e "${GREEN}✓ Capability taxonomy created${NC}"

# Function to extract current tools from agent
extract_tools() {
    local agent_file="$1"
    if grep -q "^tools:" "$agent_file"; then
        grep "^tools:" "$agent_file" | sed 's/^tools: //' | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -v '^$'
    fi
}

# Function to determine agent capabilities based on name and content
determine_capabilities() {
    local agent_file="$1"
    local agent_name=$(basename "$agent_file" .md)
    local domains="[]"
    local skills="[]"
    
    # Determine domains based on agent name and location
    case "$agent_file" in
        */architecture/*)
            domains='["architecture", "documentation"]'
            skills='["analysis", "synthesis", "planning", "decision-making"]'
            ;;
        */core/*)
            case "$agent_name" in
                *orchestrator*)
                    domains='["orchestration", "coordination"]'
                    skills='["coordination", "decision-making", "monitoring"]'
                    ;;
                *context*)
                    domains='["context-management"]'
                    skills='["persistence", "recovery", "transformation"]'
                    ;;
                *methodology*)
                    domains='["process-automation", "project-management"]'
                    skills='["planning", "execution", "monitoring"]'
                    ;;
                *)
                    domains='["orchestration"]'
                    skills='["coordination", "execution"]'
                    ;;
            esac
            ;;
        */delivery/*)
            case "$agent_name" in
                *build*)
                    domains='["deployment", "process-automation"]'
                    skills='["execution", "validation", "monitoring"]'
                    ;;
                *test*)
                    domains='["testing", "quality-assurance"]'
                    skills='["validation", "analysis", "reporting"]'
                    ;;
                *review*)
                    domains='["code-review", "quality-assurance"]'
                    skills='["analysis", "validation", "optimization"]'
                    ;;
                *issue*)
                    domains='["project-management", "documentation"]'
                    skills='["planning", "reporting", "coordination"]'
                    ;;
            esac
            ;;
        */domain/*)
            case "$agent_name" in
                *project*)
                    domains='["project-management", "orchestration"]'
                    skills='["planning", "coordination", "monitoring"]'
                    ;;
                *vision*)
                    domains='["architecture", "documentation"]'
                    skills='["synthesis", "planning", "decision-making"]'
                    ;;
            esac
            ;;
        */quality/*)
            domains='["quality-assurance", "feedback-processing"]'
            skills='["validation", "analysis", "reporting", "pattern-recognition"]'
            ;;
        */knowledge/*)
            domains='["knowledge-management", "documentation"]'
            skills='["synthesis", "persistence", "reporting"]'
            ;;
        */process/*)
            domains='["process-automation", "project-management"]'
            skills='["planning", "execution", "monitoring", "coordination"]'
            ;;
        */analytics/*)
            domains='["analytics", "feedback-processing"]'
            skills='["analysis", "pattern-recognition", "reporting"]'
            ;;
        */infrastructure/*)
            domains='["version-control", "deployment"]'
            skills='["execution", "monitoring", "recovery"]'
            ;;
        */excellence/*)
            domains='["learning", "code-generation", "optimization"]'
            skills='["pattern-recognition", "generation", "optimization", "transformation"]'
            ;;
    esac
    
    echo "{\"domains\": $domains, \"skills\": $skills}"
}

# Function to update agent with capabilities
update_agent() {
    local agent_file="$1"
    local agent_name=$(basename "$agent_file" .md)
    
    echo -e "${YELLOW}Updating $agent_name...${NC}"
    
    # Check if agent already has capabilities
    if grep -q "^capabilities:" "$agent_file"; then
        echo -e "  ${BLUE}Already has capabilities, skipping${NC}"
        return
    fi
    
    # Extract existing tools
    local tools=$(extract_tools "$agent_file")
    local tools_json="[]"
    if [[ -n "$tools" ]]; then
        tools_json=$(echo "$tools" | jq -R . | jq -s .)
    fi
    
    # Determine capabilities
    local capabilities=$(determine_capabilities "$agent_file")
    local domains=$(echo "$capabilities" | jq -r '.domains')
    local skills=$(echo "$capabilities" | jq -r '.skills')
    
    # Create backup
    cp "$agent_file" "${agent_file}.backup"
    
    # Add capabilities to frontmatter
    if grep -q "^---" "$agent_file"; then
        # Find the end of frontmatter
        local line_num=$(grep -n "^---" "$agent_file" | head -2 | tail -1 | cut -d: -f1)
        
        # Insert capabilities before the closing ---
        {
            head -n $((line_num - 1)) "$agent_file"
            echo "capabilities:"
            echo "  domains: $domains"
            echo "  skills: $skills"
            echo "  tools: $tools_json"
            echo "performance:"
            echo "  avg_response_time: 2000"
            echo "  success_rate: 95"
            tail -n +$line_num "$agent_file"
        } > "${agent_file}.tmp"
        
        mv "${agent_file}.tmp" "$agent_file"
        rm "${agent_file}.backup"
        
        echo -e "  ${GREEN}✓ Updated with capabilities${NC}"
    else
        echo -e "  ${RED}✗ No frontmatter found${NC}"
    fi
}

# Update all agents
echo -e "\n${BLUE}Updating agents with capabilities...${NC}"

total=0
updated=0

while IFS= read -r agent_file; do
    ((total++))
    update_agent "$agent_file"
    if [[ $? -eq 0 ]]; then
        ((updated++))
    fi
done < <(find "$AGENTS_DIR" -name "*.md" -type f | sort)

echo -e "\n${GREEN}Summary:${NC}"
echo "  Total agents: $total"
echo "  Updated: $updated"

# Generate capability registry
echo -e "\n${BLUE}Generating capability registry...${NC}"

echo '{"agents": [' > "$CAPABILITY_REGISTRY"

first=true
while IFS= read -r agent_file; do
    agent_name=$(basename "$agent_file" .md)
    
    # Extract capabilities from updated agent
    if grep -q "^capabilities:" "$agent_file"; then
        if [[ "$first" != "true" ]]; then
            echo "," >> "$CAPABILITY_REGISTRY"
        fi
        first=false
        
        # Extract YAML and convert to JSON (simplified)
        echo -n "  {\"id\": \"$agent_name\", " >> "$CAPABILITY_REGISTRY"
        
        # Extract domains
        domains=$(grep -A1 "domains:" "$agent_file" | tail -1 | sed 's/.*domains: //')
        echo -n "\"domains\": $domains, " >> "$CAPABILITY_REGISTRY"
        
        # Extract skills
        skills=$(grep -A1 "skills:" "$agent_file" | tail -1 | sed 's/.*skills: //')
        echo -n "\"skills\": $skills, " >> "$CAPABILITY_REGISTRY"
        
        # Extract performance
        echo -n "\"performance\": {" >> "$CAPABILITY_REGISTRY"
        echo -n "\"avg_response_time\": 2000, " >> "$CAPABILITY_REGISTRY"
        echo -n "\"success_rate\": 95}}" >> "$CAPABILITY_REGISTRY"
    fi
done < <(find "$AGENTS_DIR" -name "*.md" -type f | sort)

echo "]}" >> "$CAPABILITY_REGISTRY"

# Validate JSON
if jq . "$CAPABILITY_REGISTRY" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Capability registry created${NC}"
    echo -e "  Location: $CAPABILITY_REGISTRY"
else
    echo -e "${RED}✗ Invalid JSON in registry${NC}"
fi

# Register agents in database
echo -e "\n${BLUE}Registering agents in database...${NC}"

while IFS= read -r agent_file; do
    agent_name=$(basename "$agent_file" .md)
    agent_type=$(dirname "$agent_file" | xargs basename)
    
    if grep -q "^capabilities:" "$agent_file"; then
        capabilities=$(determine_capabilities "$agent_file")
        
        sqlite3 "$CAPABILITY_DB" <<SQL
INSERT OR REPLACE INTO agents (id, name, type, capabilities, created_at)
VALUES ('$agent_name', '$agent_name', '$agent_type', '$capabilities', CURRENT_TIMESTAMP);
SQL
    fi
done < <(find "$AGENTS_DIR" -name "*.md" -type f)

echo -e "${GREEN}✓ Agents registered in database${NC}"

echo -e "\n${GREEN}✅ Agent capability enhancement complete!${NC}"