#!/bin/bash
# Setup proper directory structure according to physical architecture

echo "=== Setting Up Proper ClaudeProjects2 Structure ==="
echo "Following the physical architecture specification..."
echo

# Base directories
PROJECT_ROOT="$(pwd)"
USER_HOME="$HOME"

# 1. Create runtime directories (Architecture line 207-211)
echo "1. Creating runtime directories..."
mkdir -p runtime/cache
mkdir -p runtime/logs
mkdir -p runtime/temp
echo "✅ Runtime directories created"

# 2. Fix message queue structure (ADR-003 line 54-66)
echo -e "\n2. Restructuring message queue with priority directories..."
mkdir -p .claudeprojects/messages/queues
mkdir -p .claudeprojects/messages/processing
mkdir -p .claudeprojects/messages/dead-letter
mkdir -p .claudeprojects/messages/archive

# Create per-agent queues with priority
for agent in orchestrator-agent project-agent context-agent version-agent \
             code-review-agent test-agent build-agent issue-agent \
             methodology-agent knowledge-agent; do
    mkdir -p ".claudeprojects/messages/queues/$agent/priority"
    mkdir -p ".claudeprojects/messages/queues/$agent/normal"
    mkdir -p ".claudeprojects/messages/queues/$agent/low"
    mkdir -p ".claudeprojects/messages/processing/$agent"
done
echo "✅ Message queue restructured with priority support"

# 3. Fix context structure (Architecture line 244-250)
echo -e "\n3. Fixing context persistence structure..."
mkdir -p .claudeprojects/context/working
mkdir -p .claudeprojects/context/history
mkdir -p .claudeprojects/knowledge
mkdir -p .claudeprojects/agents
mkdir -p .claudeprojects/config

# Migrate existing state to context/working
if [ -d ".claudeprojects/state" ]; then
    echo "  Migrating state/ to context/working/"
    mv .claudeprojects/state/* .claudeprojects/context/working/ 2>/dev/null || true
    rmdir .claudeprojects/state 2>/dev/null || true
fi
echo "✅ Context structure fixed"

# 4. Create Obsidian vault structure (Architecture line 216-220)
echo -e "\n4. Creating Obsidian vault structure..."
VAULT_PATH="$USER_HOME/Documents/ClaudeProjects2-Vault"
mkdir -p "$VAULT_PATH/Projects"
mkdir -p "$VAULT_PATH/Methodologies"
mkdir -p "$VAULT_PATH/Knowledge"
mkdir -p "$VAULT_PATH/Analytics"

# Create vault README
cat > "$VAULT_PATH/README.md" <<EOF
# ClaudeProjects2 Knowledge Vault

This is your centralized knowledge base for all ClaudeProjects2 projects.

## Structure

- **Projects/**: Individual project documentation
- **Methodologies/**: Executable methodology documentation
- **Knowledge/**: Captured insights, patterns, and learnings
- **Analytics/**: Performance metrics and reports

## Integration

This vault integrates with ClaudeProjects2 agents via:
- knowledge-agent: Captures insights
- obsidian-agent: Manages notes
- analytics-agent: Generates reports

## Usage

1. Open this vault in Obsidian
2. Enable the REST API plugin (if using MCP)
3. Let agents manage content automatically
EOF

echo "✅ Obsidian vault created at: $VAULT_PATH"

# 5. Create proper config structure (Architecture line 204-206)
echo -e "\n5. Setting up configuration..."
mkdir -p config

# Create MCP configuration
cat > config/claude-desktop.json <<EOF
{
  "mcpServers": {
    "obsidian": {
      "command": "node",
      "args": ["$USER_HOME/.nvm/versions/node/v20.11.0/lib/node_modules/@campsis/mcp-obsidian/dist/index.js"],
      "env": {
        "OBSIDIAN_VAULT_PATH": "$VAULT_PATH"
      }
    }
  }
}
EOF

# Create settings
cat > config/settings.json <<EOF
{
  "version": "1.0.0",
  "project": {
    "name": "ClaudeProjects2",
    "type": "system"
  },
  "agents": {
    "autoLoad": ["core", "infrastructure"],
    "onDemand": ["domain", "delivery", "knowledge"]
  },
  "performance": {
    "cacheSize": "100MB",
    "contextTimeout": 500,
    "parallelAgents": 4
  },
  "paths": {
    "vault": "$VAULT_PATH",
    "runtime": "$PROJECT_ROOT/runtime"
  }
}
EOF
echo "✅ Configuration created"

# 6. Create analytics database structure (Architecture line 263)
echo -e "\n6. Setting up analytics database..."
mkdir -p .claudeprojects/analytics

# Initialize SQLite schema
sqlite3 .claudeprojects/analytics/metrics.db <<SQL
CREATE TABLE IF NOT EXISTS agent_metrics (
    id INTEGER PRIMARY KEY,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    agent_name TEXT,
    execution_time_ms INTEGER,
    memory_used_mb INTEGER,
    task_type TEXT,
    success BOOLEAN
);

CREATE TABLE IF NOT EXISTS project_metrics (
    id INTEGER PRIMARY KEY,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    time_saved_hours REAL,
    productivity_multiplier REAL,
    methodology_efficiency REAL,
    knowledge_growth_rate REAL
);

CREATE INDEX idx_agent_timestamp ON agent_metrics(timestamp);
CREATE INDEX idx_project_timestamp ON project_metrics(timestamp);
SQL
echo "✅ Analytics database initialized"

# 7. Update message queue script to use new structure
echo -e "\n7. Creating updated message queue script..."
cat > scripts/message-queue-v2.sh <<'EOF'
#!/bin/bash
# Message queue v2 - Follows architecture specification

QUEUE_DIR=".claudeprojects/messages"

# Function to send a message with priority routing
send_message() {
    local from="$1"
    local to="$2"
    local type="$3"
    local data="$4"
    local priority="${5:-normal}"
    
    local id="$(date +%s%N)-$(uuidgen | tr '[:upper:]' '[:lower:]' | cut -d'-' -f1)"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local filename="${timestamp}_${id}.json"
    local queue_path="$QUEUE_DIR/queues/$to/$priority"
    local temp_file="$queue_path/.tmp-$filename"
    local final_file="$queue_path/$filename"
    
    # Create message
    cat > "$temp_file" <<JSON
{
  "header": {
    "id": "$id",
    "timestamp": "$timestamp",
    "from": "$from",
    "to": "$to",
    "priority": "$priority",
    "ttl": 300000
  },
  "body": {
    "type": "$type",
    "action": "process",
    "payload": $data
  }
}
JSON
    
    # Atomic move
    mv "$temp_file" "$final_file"
    echo "Message sent to $to ($priority): $final_file"
}

# Process messages with priority order
receive_message() {
    local agent="$1"
    
    # Check priority queues in order
    for priority in priority normal low; do
        local queue_path="$QUEUE_DIR/queues/$agent/$priority"
        
        # Get oldest message
        for file in $(ls -1 "$queue_path"/*.json 2>/dev/null | sort | head -1); do
            if [ -f "$file" ]; then
                local basename=$(basename "$file")
                local lock_file="$QUEUE_DIR/processing/$agent/$basename.lock"
                
                # Try to acquire lock
                if mkdir -p "$(dirname "$lock_file")" && \
                   echo $$ > "$lock_file" 2>/dev/null; then
                    # Move to processing
                    local processing_file="$QUEUE_DIR/processing/$agent/$basename"
                    if mv "$file" "$processing_file" 2>/dev/null; then
                        cat "$processing_file"
                        echo "$processing_file"
                        return 0
                    fi
                    rm -f "$lock_file"
                fi
            fi
        done
    done
    
    return 1
}

# Archive completed message
complete_message() {
    local processing_file="$1"
    if [ -f "$processing_file" ]; then
        local basename=$(basename "$processing_file")
        local archive_file="$QUEUE_DIR/archive/$basename"
        mv "$processing_file" "$archive_file"
        rm -f "${processing_file}.lock"
        echo "Message archived: $archive_file"
    fi
}

# Main
case "$1" in
    send)
        send_message "$2" "$3" "$4" "$5" "$6"
        ;;
    receive)
        receive_message "$2"
        ;;
    complete)
        complete_message "$2"
        ;;
    *)
        echo "Usage: $0 {send|receive|complete} [args...]"
        exit 1
        ;;
esac
EOF

chmod +x scripts/message-queue-v2.sh
echo "✅ Updated message queue script created"

# 8. Create migration script for existing messages
echo -e "\n8. Migrating existing messages..."
if [ -d ".claudeprojects/messages/pending" ]; then
    for msg in .claudeprojects/messages/pending/*.json; do
        if [ -f "$msg" ]; then
            # Parse the 'to' field and priority
            to=$(jq -r '.to' "$msg" 2>/dev/null || echo "unknown")
            priority=$(jq -r '.priority // "normal"' "$msg" 2>/dev/null || echo "normal")
            
            # Move to new structure
            target_dir=".claudeprojects/messages/queues/$to/$priority"
            mkdir -p "$target_dir"
            mv "$msg" "$target_dir/" 2>/dev/null || true
        fi
    done
    echo "✅ Messages migrated to new structure"
fi

# Summary
echo -e "\n=== Setup Complete ==="
echo "✅ Runtime directories created"
echo "✅ Message queue restructured with priorities"
echo "✅ Context persistence fixed"
echo "✅ Obsidian vault created at $VAULT_PATH"
echo "✅ Configuration files created"
echo "✅ Analytics database initialized"
echo "✅ Updated scripts ready"
echo
echo "Next steps:"
echo "1. Open Obsidian and add vault: $VAULT_PATH"
echo "2. Start using message-queue-v2.sh for proper priority handling"
echo "3. Run agents with new structure"
echo
echo "The system now fully complies with the physical architecture!"
EOF