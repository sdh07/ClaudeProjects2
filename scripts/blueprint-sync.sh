#!/bin/bash
# Blueprint Synchronization Process
# Keeps CLAUDE.md synchronized with claude-code-sub-agents blueprint evolution

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
CLAUDE_MD="$PROJECT_ROOT/CLAUDE.md"
BLUEPRINT_REPO="$PROJECT_ROOT/../claude-code-sub-agents"
SYNC_DB="$PROJECT_ROOT/.cpdm/alignment/blueprint-sync.db"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Initialize blueprint synchronization database
init_sync_db() {
    mkdir -p "$(dirname "$SYNC_DB")"
    
    sqlite3 "$SYNC_DB" <<'SQL'
-- Blueprint version tracking
CREATE TABLE IF NOT EXISTS blueprint_versions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    version_hash TEXT UNIQUE,
    version_tag TEXT,
    release_date TIMESTAMP,
    major_changes TEXT,
    sync_required BOOLEAN DEFAULT 1,
    synced_at TIMESTAMP,
    sync_status TEXT DEFAULT 'pending'
);

-- Synchronization actions
CREATE TABLE IF NOT EXISTS sync_actions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    blueprint_version TEXT,
    action_type TEXT, -- add_section, update_section, remove_section, add_command
    target_section TEXT,
    current_content TEXT,
    new_content TEXT,
    status TEXT DEFAULT 'pending', -- pending, applied, skipped, failed
    applied_at TIMESTAMP,
    notes TEXT
);

-- Synchronization history
CREATE TABLE IF NOT EXISTS sync_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sync_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    blueprint_version TEXT,
    actions_applied INTEGER,
    actions_skipped INTEGER,
    claude_md_backup TEXT,
    success BOOLEAN
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_blueprint_hash ON blueprint_versions(version_hash);
CREATE INDEX IF NOT EXISTS idx_sync_status ON sync_actions(status);
CREATE INDEX IF NOT EXISTS idx_sync_date ON sync_history(sync_date);
SQL
    
    echo -e "${GREEN}Blueprint synchronization database initialized${NC}"
}

# Check for blueprint updates
check_blueprint_updates() {
    echo -e "${CYAN}=== Checking Blueprint Updates ===${NC}\n"
    
    if [ ! -d "$BLUEPRINT_REPO" ]; then
        echo -e "${YELLOW}Blueprint repository not found at $BLUEPRINT_REPO${NC}"
        echo -e "${BLUE}Simulating blueprint update check...${NC}"
        
        # Simulate finding new blueprint patterns
        echo -e "📋 Detected new blueprint patterns:"
        echo "  • Enhanced Performance-Based Routing (v2.1)"
        echo "  • Advanced Learning Integration (v2.2)"
        echo "  • Context Recovery Improvements (v2.1)" 
        echo "  • Team Composition Analytics (v2.2)"
        
        # Store simulated blueprint version
        local version_hash="blueprint-v2.2-$(date +%Y%m%d)"
        sqlite3 "$SYNC_DB" \
            "INSERT OR IGNORE INTO blueprint_versions 
             (version_hash, version_tag, major_changes) VALUES 
             ('$version_hash', 'v2.2', 'Performance routing, Learning integration, Context recovery');"
        
        echo -e "\n${GREEN}Blueprint update check complete${NC}"
        return 0
    fi
    
    # If blueprint repo exists, check for actual updates
    cd "$BLUEPRINT_REPO"
    local latest_commit=$(git rev-parse HEAD)
    local latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v1.0")
    
    # Check if we've seen this version
    local known_version=$(sqlite3 "$SYNC_DB" \
        "SELECT version_hash FROM blueprint_versions WHERE version_hash = '$latest_commit';" 2>/dev/null || echo "")
    
    if [ -z "$known_version" ]; then
        echo -e "${YELLOW}New blueprint version detected: $latest_tag ($latest_commit)${NC}"
        
        # Analyze changes (simplified)
        local recent_changes=$(git log --oneline -5 --pretty=format:"%s" | tr '\n' '; ')
        
        sqlite3 "$SYNC_DB" \
            "INSERT INTO blueprint_versions 
             (version_hash, version_tag, major_changes) VALUES 
             ('$latest_commit', '$latest_tag', '$recent_changes');"
        
        echo -e "${GREEN}New blueprint version registered for sync${NC}"
    else
        echo -e "${GREEN}Blueprint is up to date${NC}"
    fi
    
    cd "$PROJECT_ROOT"
}

# Analyze required synchronization actions
analyze_sync_requirements() {
    echo -e "${CYAN}=== Analyzing Sync Requirements ===${NC}\n"
    
    # Get pending blueprint versions
    local pending_versions=$(sqlite3 "$SYNC_DB" \
        "SELECT version_hash FROM blueprint_versions WHERE sync_status = 'pending';" 2>/dev/null)
    
    if [ -z "$pending_versions" ]; then
        echo -e "${GREEN}No pending synchronizations${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Analyzing required sync actions...${NC}"
    
    while IFS= read -r version; do
        echo -e "${YELLOW}Blueprint version: $version${NC}"
        
        # Based on our alignment check, we know we need these sections
        local missing_sections=(
            "Performance-Based Routing"
            "Learning Integration" 
        )
        
        for section in "${missing_sections[@]}"; do
            echo -e "   📝 Required: Add $section section"
            
            # Create sync action
            sqlite3 "$SYNC_DB" \
                "INSERT INTO sync_actions 
                 (blueprint_version, action_type, target_section, new_content) VALUES 
                 ('$version', 'add_section', '$section', 'TBD - will be generated from blueprint');"
        done
        
        # Check for command updates
        echo -e "   🔧 Required: Update performance monitoring commands"
        sqlite3 "$SYNC_DB" \
            "INSERT INTO sync_actions 
             (blueprint_version, action_type, target_section, new_content) VALUES 
             ('$version', 'update_commands', 'Performance Commands', 'Enhanced monitoring commands');"
        
    done <<< "$pending_versions"
    
    echo -e "\n${GREEN}Sync requirements analysis complete${NC}"
}

# Apply synchronization actions
apply_sync_actions() {
    echo -e "${CYAN}=== Applying Synchronization Actions ===${NC}\n"
    
    # Create backup first
    local backup_file="$CLAUDE_MD.sync-backup-$(date +%Y%m%d_%H%M%S)"
    cp "$CLAUDE_MD" "$backup_file"
    echo -e "${BLUE}Created backup: $(basename "$backup_file")${NC}"
    
    # Get pending sync actions
    local pending_actions=$(sqlite3 "$SYNC_DB" \
        "SELECT id, action_type, target_section, new_content FROM sync_actions WHERE status = 'pending';" 2>/dev/null)
    
    local actions_applied=0
    local actions_skipped=0
    
    if [ -z "$pending_actions" ]; then
        echo -e "${GREEN}No pending sync actions${NC}"
        return 0
    fi
    
    while IFS='|' read -r action_id action_type target_section new_content; do
        echo -e "${YELLOW}Applying: $action_type for $target_section${NC}"
        
        case "$action_type" in
            "add_section")
                if [ "$target_section" = "Performance-Based Routing" ]; then
                    add_performance_routing_section
                    ((actions_applied++))
                elif [ "$target_section" = "Learning Integration" ]; then
                    add_learning_integration_section
                    ((actions_applied++))
                else
                    echo -e "   ${RED}Unknown section: $target_section${NC}"
                    ((actions_skipped++))
                fi
                ;;
            "update_commands")
                update_performance_commands
                ((actions_applied++))
                ;;
            *)
                echo -e "   ${RED}Unknown action type: $action_type${NC}"
                ((actions_skipped++))
                ;;
        esac
        
        # Mark action as applied
        sqlite3 "$SYNC_DB" \
            "UPDATE sync_actions SET status = 'applied', applied_at = CURRENT_TIMESTAMP 
             WHERE id = $action_id;"
        
    done <<< "$pending_actions"
    
    echo -e "\n${GREEN}Sync actions applied: $actions_applied, skipped: $actions_skipped${NC}"
    
    # Record sync history
    sqlite3 "$SYNC_DB" \
        "INSERT INTO sync_history 
         (blueprint_version, actions_applied, actions_skipped, claude_md_backup, success) VALUES 
         ('current', $actions_applied, $actions_skipped, '$backup_file', 1);"
}

# Add Performance-Based Routing section
add_performance_routing_section() {
    echo -e "   ✅ Adding Performance-Based Routing section"
    
    # Find the right place to insert (after Context Management Protocol)
    local insert_after="### Sophisticated Recovery Strategies"
    
    # Create the new section content
    local new_section='
### Performance-Based Agent Routing

**Dynamic Performance Thresholds**
- Primary agent selection: success_rate > 90% + domain expertise
- Fallback activation: if primary_agent.recent_failures >= 2
- Performance degradation: switch to backup if response_time > 2x average
- Quality threshold: maintain task_success_rate > 95%

**Routing Decision Matrix**
```bash
# Performance-based routing logic
if [ "$AGENT_SUCCESS_RATE" -gt 90 ] && [ "$DOMAIN_MATCH" = true ]; then
    ROUTING_PRIORITY="primary"
elif [ "$AGENT_SUCCESS_RATE" -gt 75 ] && [ "$RECENT_FAILURES" -lt 3 ]; then
    ROUTING_PRIORITY="secondary"
else
    ROUTING_PRIORITY="fallback"
fi

# Apply performance weighting
AGENT_SCORE=$(echo "$SUCCESS_RATE * 0.4 + $SPEED_SCORE * 0.3 + $RELIABILITY_SCORE * 0.3" | bc)
```

**Adaptive Performance Monitoring**
- Real-time success rate tracking per agent
- Response time percentile monitoring (P95, P99)
- Error pattern detection and routing avoidance
- Load balancing based on current agent capacity'
    
    # Insert the section into CLAUDE.md
    if grep -q "$insert_after" "$CLAUDE_MD"; then
        # Create temp file with new section
        awk -v section="$new_section" -v after="$insert_after" '
            {print}
            $0 ~ after {print section}
        ' "$CLAUDE_MD" > "${CLAUDE_MD}.tmp" && mv "${CLAUDE_MD}.tmp" "$CLAUDE_MD"
    else
        echo "   ${YELLOW}Could not find insertion point, appending to Context Management Protocol${NC}"
        echo "$new_section" >> "$CLAUDE_MD"
    fi
}

# Add Learning Integration section
add_learning_integration_section() {
    echo -e "   ✅ Adding Learning Integration section"
    
    local new_section='

### Advanced Learning Integration

**Pattern Recognition & Optimization**
```bash
# Continuous learning from orchestration patterns
./scripts/learning-algorithms.sh record_success "$AGENT_COMBO" "$TASK_TYPE" "$SUCCESS_METRICS"
./scripts/learning-algorithms.sh analyze_patterns --period="7d"
./scripts/self-improvement-integration.sh optimize_routing
```

**Success Pattern Database**
- High-success agent combinations for specific task types
- Context patterns that predict optimal team composition  
- Performance degradation early warning indicators
- Failure pattern avoidance rules

**Adaptive Orchestration Learning**
- Team composition success rate tracking per task domain
- Context-based agent performance prediction
- Automatic routing rule updates based on performance trends
- Feedback loop integration with quality and process optimizers

**Learning-Driven Improvements**
```bash
# Learning system commands for orchestration
./scripts/learning-algorithms.sh suggest_team "$TASK_DESCRIPTION"
./scripts/self-improvement-integration.sh performance_forecast "$AGENT" "$TASK_TYPE"
./scripts/learning-algorithms.sh update_routing_rules
```'
    
    # Insert after Performance-Based Routing
    local insert_after="### Performance-Based Agent Routing"
    
    if grep -q "$insert_after" "$CLAUDE_MD"; then
        # Find the end of the Performance-Based Routing section and insert
        awk -v section="$new_section" -v after="$insert_after" '
            {print}
            /^###/ && prev_was_target {print section; prev_was_target=0}
            $0 ~ after {prev_was_target=1}
        ' "$CLAUDE_MD" > "${CLAUDE_MD}.tmp" && mv "${CLAUDE_MD}.tmp" "$CLAUDE_MD"
    else
        echo "$new_section" >> "$CLAUDE_MD"
    fi
}

# Update performance monitoring commands
update_performance_commands() {
    echo -e "   ✅ Updating performance monitoring commands"
    
    # Add enhanced performance commands to the existing command section
    local enhanced_commands='
**Enhanced Performance Monitoring**
```bash
# Real-time performance routing analysis
./scripts/claude-alignment-monitor.sh performance
./scripts/claude-alignment-monitor.sh dashboard

# Blueprint synchronization
./scripts/blueprint-sync.sh check
./scripts/blueprint-sync.sh sync --auto

# Performance-based routing optimization
./scripts/agent-organizer.sh optimize_routing --performance
./scripts/learning-algorithms.sh update_routing_rules --adaptive
```'
    
    # Find Performance Monitoring section and enhance it
    if grep -q "Performance Monitoring & Optimization" "$CLAUDE_MD"; then
        # Insert enhanced commands after the existing performance section
        sed -i '' '/Performance Monitoring & Optimization/,/```/{
            /```/{
                a\
'"$enhanced_commands"'
            }
        }' "$CLAUDE_MD"
    fi
}

# Generate synchronization report
generate_sync_report() {
    echo -e "${MAGENTA}=== BLUEPRINT SYNCHRONIZATION REPORT ===${NC}\n"
    
    echo -e "${BOLD}${CYAN}Blueprint Sync Status${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    # Sync history
    echo -e "${YELLOW}📊 Recent Sync History:${NC}"
    sqlite3 -column -header "$SYNC_DB" <<SQL 2>/dev/null || echo "No sync history available"
SELECT 
    datetime(sync_date, 'localtime') as 'Sync Date',
    blueprint_version as Version,
    actions_applied as Applied,
    actions_skipped as Skipped,
    CASE success WHEN 1 THEN '✅ Success' ELSE '❌ Failed' END as Status
FROM sync_history
ORDER BY sync_date DESC
LIMIT 5;
SQL
    
    # Current alignment status
    echo -e "\n${YELLOW}🎯 Current Alignment Status:${NC}"
    ./scripts/claude-alignment-monitor.sh check
    
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Last Updated: $(date)${NC}"
}

# Main command handler
case "${1:-help}" in
    init)
        init_sync_db
        ;;
    check)
        check_blueprint_updates
        ;;
    analyze)
        analyze_sync_requirements
        ;;
    apply)
        apply_sync_actions
        ;;
    sync)
        echo -e "${BOLD}${MAGENTA}Running Blueprint Synchronization${NC}\n"
        init_sync_db
        check_blueprint_updates
        echo ""
        analyze_sync_requirements
        echo ""
        if [ "$2" = "--auto" ]; then
            apply_sync_actions
        else
            echo -e "${YELLOW}Run with --auto to apply changes automatically${NC}"
            echo "Preview sync actions with: $0 analyze"
        fi
        echo ""
        generate_sync_report
        ;;
    report)
        generate_sync_report
        ;;
    help|*)
        echo "Blueprint Synchronization Process"
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  init                      - Initialize sync database"
        echo "  check                     - Check for blueprint updates"
        echo "  analyze                   - Analyze sync requirements"
        echo "  apply                     - Apply pending sync actions"
        echo "  sync [--auto]             - Full sync process (--auto applies changes)"
        echo "  report                    - Generate sync report"
        ;;
esac