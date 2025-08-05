#!/bin/bash
# Agent loader and discovery mechanism for ClaudeProjects2

AGENTS_DIR="agents"
AGENT_REGISTRY=".claudeprojects/state/agent-registry.json"

# Ensure registry directory exists
mkdir -p "$(dirname "$AGENT_REGISTRY")"

# Function to extract YAML frontmatter from markdown
extract_frontmatter() {
    local file="$1"
    
    # Extract content between --- markers
    awk '
        /^---$/ { if (++count == 1) next; if (count == 2) exit; }
        count == 1 { print }
    ' "$file"
}

# Function to parse agent metadata
parse_agent() {
    local file="$1"
    local relative_path="${file#$AGENTS_DIR/}"
    local agent_dir=$(dirname "$relative_path")
    
    # Extract frontmatter
    local frontmatter=$(extract_frontmatter "$file")
    
    # Parse individual fields (basic parsing, would need proper YAML parser for production)
    local name=$(echo "$frontmatter" | grep "^name:" | cut -d: -f2- | sed 's/^ *//g' | tr -d '"')
    local description=$(echo "$frontmatter" | grep "^description:" | cut -d: -f2- | sed 's/^ *//g' | tr -d '"')
    local category=$(echo "$frontmatter" | grep "^category:" | cut -d: -f2- | sed 's/^ *//g' | tr -d '"')
    local version=$(echo "$frontmatter" | grep "^version:" | cut -d: -f2- | sed 's/^ *//g' | tr -d '"')
    local status=$(echo "$frontmatter" | grep "^status:" | cut -d: -f2- | sed 's/^ *//g' | tr -d '"')
    
    # Extract tools array (simplified)
    local tools=$(echo "$frontmatter" | grep "^tools:" | cut -d: -f2- | sed 's/^ *//g' | tr -d '[]' | tr ',' ' ')
    
    # Default values
    [ -z "$version" ] && version="1.0.0"
    [ -z "$status" ] && status="active"
    [ -z "$category" ] && category="uncategorized"
    
    # Output as JSON
    cat <<EOF
{
  "name": "$name",
  "description": "$description",
  "category": "$category",
  "version": "$version",
  "status": "$status",
  "path": "$file",
  "tools": [$(echo "$tools" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')]
}
EOF
}

# Function to discover all agents
discover_agents() {
    local agents_json="["
    local first=true
    
    # Find all .md files in agents directory
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            # Check if file has frontmatter
            if grep -q "^---$" "$file"; then
                local agent_json=$(parse_agent "$file")
                
                if [ "$first" = true ]; then
                    first=false
                else
                    agents_json+=","
                fi
                
                agents_json+="$agent_json"
            fi
        fi
    done < <(find "$AGENTS_DIR" -name "*.md" -type f)
    
    agents_json+="]"
    
    echo "$agents_json"
}

# Function to save registry
save_registry() {
    local agents_json="$1"
    local temp_file="${AGENT_REGISTRY}.tmp"
    
    # Create registry with metadata
    cat > "$temp_file" <<EOF
{
  "version": "1.0.0",
  "updated": "$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")",
  "agents": $agents_json
}
EOF
    
    # Atomic move
    mv "$temp_file" "$AGENT_REGISTRY"
}

# Function to load specific agent
load_agent() {
    local agent_name="$1"
    
    if [ -f "$AGENT_REGISTRY" ]; then
        jq -r ".agents[] | select(.name == \"$agent_name\")" "$AGENT_REGISTRY"
    else
        echo "Error: Agent registry not found. Run 'discover' first." >&2
        return 1
    fi
}

# Function to list agents
list_agents() {
    local category="$1"
    
    if [ -f "$AGENT_REGISTRY" ]; then
        if [ -z "$category" ]; then
            jq -r '.agents[] | "\(.name) (\(.category)) - \(.description)"' "$AGENT_REGISTRY"
        else
            jq -r ".agents[] | select(.category == \"$category\") | \"\(.name) - \(.description)\"" "$AGENT_REGISTRY"
        fi
    else
        echo "Error: Agent registry not found. Run 'discover' first." >&2
        return 1
    fi
}

# Function to get agent content
get_agent_content() {
    local agent_name="$1"
    local agent_path=$(load_agent "$agent_name" | jq -r '.path')
    
    if [ -f "$agent_path" ]; then
        # Skip frontmatter and return content
        awk '
            /^---$/ { if (++count == 2) { getline; content=1 } }
            content { print }
        ' "$agent_path"
    else
        echo "Error: Agent file not found: $agent_path" >&2
        return 1
    fi
}

# Main command processing
case "$1" in
    discover)
        echo "Discovering agents in $AGENTS_DIR..."
        agents=$(discover_agents)
        save_registry "$agents"
        count=$(echo "$agents" | jq 'length')
        echo "Found $count agents. Registry saved to $AGENT_REGISTRY"
        ;;
    list)
        list_agents "$2"
        ;;
    load)
        load_agent "$2"
        ;;
    content)
        get_agent_content "$2"
        ;;
    registry)
        if [ -f "$AGENT_REGISTRY" ]; then
            cat "$AGENT_REGISTRY"
        else
            echo "Error: Agent registry not found. Run 'discover' first." >&2
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {discover|list|load|content|registry} [args...]"
        echo ""
        echo "Commands:"
        echo "  discover              - Scan for agents and update registry"
        echo "  list [category]       - List all agents or by category"
        echo "  load <agent-name>     - Load agent metadata"
        echo "  content <agent-name>  - Get agent prompt content"
        echo "  registry              - Show full registry"
        exit 1
        ;;
esac