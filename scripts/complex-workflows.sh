#!/bin/bash

# Complex Agent Workflows Demonstration
# Shows advanced multi-agent coordination patterns

set -e

# Configuration
AGENTS_DIR="${AGENTS_DIR:-./agents}"
QUEUE_DIR="${QUEUE_DIR:-./.claudeprojects/messages}"
LOG_DIR="${LOG_DIR:-./.claudeprojects/logs}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Workflow 1: Parallel Feature Development
workflow_parallel_features() {
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "${BLUE}Workflow 1: Parallel Feature Development${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo ""
    echo "Scenario: Implementing 3 features simultaneously"
    echo ""
    
    # Start three parallel workflows
    echo -e "${YELLOW}[USER]${NC} Requesting 3 features:"
    echo "  1. User authentication"
    echo "  2. Export to PDF"
    echo "  3. Real-time collaboration"
    sleep 1
    
    echo -e "\n${CYAN}[ORCHESTRATOR]${NC} Analyzing requests and delegating..."
    sleep 1
    
    # Feature 1: Authentication
    echo -e "\n${GREEN}Branch 1: Authentication${NC}"
    echo -e "  ${CYAN}orchestrator${NC} → ${CYAN}project-agent${NC} [plan_auth]"
    echo -e "  ${CYAN}project-agent${NC} → ${CYAN}architecture-designer${NC} [design_auth]"
    echo -e "  ${CYAN}architecture-designer${NC} → ${CYAN}code-generator${NC} [implement_auth]"
    
    # Feature 2: PDF Export
    echo -e "\n${GREEN}Branch 2: PDF Export${NC}"
    echo -e "  ${CYAN}orchestrator${NC} → ${CYAN}project-agent${NC} [plan_pdf]"
    echo -e "  ${CYAN}project-agent${NC} → ${CYAN}research-agent${NC} [research_pdf_libs]"
    echo -e "  ${CYAN}research-agent${NC} → ${CYAN}code-generator${NC} [implement_pdf]"
    
    # Feature 3: Collaboration
    echo -e "\n${GREEN}Branch 3: Real-time Collaboration${NC}"
    echo -e "  ${CYAN}orchestrator${NC} → ${CYAN}innovation-agent${NC} [design_realtime]"
    echo -e "  ${CYAN}innovation-agent${NC} → ${CYAN}architecture-designer${NC} [websocket_arch]"
    echo -e "  ${CYAN}architecture-designer${NC} → ${CYAN}code-generator${NC} [implement_collab]"
    
    sleep 2
    
    echo -e "\n${YELLOW}⚡ All three branches executing in parallel...${NC}"
    sleep 2
    
    # Convergence point
    echo -e "\n${BLUE}[CONVERGENCE]${NC} All features ready for integration"
    echo -e "  ${CYAN}code-review-agent${NC} reviewing all 3 features..."
    echo -e "  ${CYAN}test-agent${NC} running integration tests..."
    echo -e "  ${CYAN}build-agent${NC} creating unified build..."
    
    sleep 1
    echo -e "\n${GREEN}✓ Parallel workflow complete!${NC}"
    echo "  Time saved: 66% (parallel vs sequential)"
}

# Workflow 2: Self-Healing Error Recovery
workflow_error_recovery() {
    echo -e "\n${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "${BLUE}Workflow 2: Self-Healing Error Recovery${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo ""
    echo "Scenario: Build failure with automatic recovery"
    echo ""
    
    echo -e "${YELLOW}[BUILD-AGENT]${NC} Starting production build..."
    sleep 1
    
    echo -e "${RED}✗ Build failed!${NC} TypeScript error in auth.ts:42"
    sleep 1
    
    echo -e "\n${CYAN}[ERROR-RECOVERY]${NC} Initiating self-healing protocol..."
    
    # Recovery steps
    echo -e "  1. ${CYAN}build-agent${NC} → ${CYAN}orchestrator${NC} [error_report]"
    echo -e "  2. ${CYAN}orchestrator${NC} → ${CYAN}code-review-agent${NC} [analyze_error]"
    echo -e "  3. ${CYAN}code-review-agent${NC} identifies: Missing type annotation"
    echo -e "  4. ${CYAN}orchestrator${NC} → ${CYAN}code-generator${NC} [fix_types]"
    echo -e "  5. ${CYAN}code-generator${NC} applies fix: Added 'User' type"
    echo -e "  6. ${CYAN}orchestrator${NC} → ${CYAN}test-agent${NC} [verify_fix]"
    echo -e "  7. ${CYAN}test-agent${NC} confirms: All tests pass"
    echo -e "  8. ${CYAN}orchestrator${NC} → ${CYAN}build-agent${NC} [retry_build]"
    
    sleep 3
    
    echo -e "\n${GREEN}✓ Build successful after automatic recovery!${NC}"
    echo "  Recovery time: 45 seconds"
    echo "  Human intervention: None required"
}

# Workflow 3: Knowledge-Driven Development
workflow_knowledge_driven() {
    echo -e "\n${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "${BLUE}Workflow 3: Knowledge-Driven Development${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo ""
    echo "Scenario: Learning from past implementations"
    echo ""
    
    echo -e "${YELLOW}[USER]${NC} Add caching to improve performance"
    sleep 1
    
    echo -e "\n${CYAN}[KNOWLEDGE-AGENT]${NC} Searching knowledge base..."
    echo "  Found 3 previous caching implementations:"
    echo "  - Redis cache (Project A) - Success rate: 95%"
    echo "  - Memory cache (Project B) - Success rate: 78%"
    echo "  - Hybrid cache (Project C) - Success rate: 99%"
    sleep 2
    
    echo -e "\n${CYAN}[ORCHESTRATOR]${NC} Applying learned patterns..."
    echo -e "  Selected: Hybrid cache (highest success rate)"
    echo -e "  ${CYAN}knowledge-agent${NC} → ${CYAN}architecture-designer${NC} [cache_pattern]"
    echo -e "  ${CYAN}architecture-designer${NC} adapts pattern for current context"
    echo -e "  ${CYAN}code-generator${NC} implements with optimizations"
    
    sleep 2
    
    echo -e "\n${GREEN}✓ Caching implemented using best practices!${NC}"
    echo "  Performance improvement: 3x faster"
    echo "  Based on: 3 previous successful implementations"
}

# Workflow 4: Conditional Branching
workflow_conditional() {
    echo -e "\n${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "${BLUE}Workflow 4: Conditional Branching Logic${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo ""
    echo "Scenario: Smart routing based on complexity"
    echo ""
    
    echo -e "${YELLOW}[USER]${NC} Fix the search functionality"
    sleep 1
    
    echo -e "\n${CYAN}[ORCHESTRATOR]${NC} Analyzing issue complexity..."
    echo "  Checking: Error logs, recent changes, test results"
    sleep 1
    
    echo -e "\nComplexity: ${YELLOW}MEDIUM${NC}"
    echo "Routing decision:"
    echo ""
    
    echo "IF complexity = LOW:"
    echo "  → Direct fix by code-generator"
    echo ""
    echo "IF complexity = MEDIUM: ${GREEN}← Selected${NC}"
    echo "  → research-agent (investigate)"
    echo "  → code-generator (implement)"
    echo "  → test-agent (verify)"
    echo ""
    echo "IF complexity = HIGH:"
    echo "  → architecture-designer (redesign)"
    echo "  → project-agent (break down)"
    echo "  → Multiple agents (implement)"
    
    sleep 2
    
    echo -e "\n${CYAN}Executing MEDIUM complexity workflow...${NC}"
    echo -e "  ${CYAN}research-agent${NC} found: Elasticsearch query syntax issue"
    echo -e "  ${CYAN}code-generator${NC} fixed: Updated query builder"
    echo -e "  ${CYAN}test-agent${NC} verified: Search working correctly"
    
    echo -e "\n${GREEN}✓ Conditional workflow complete!${NC}"
}

# Workflow 5: Rollback Mechanism
workflow_rollback() {
    echo -e "\n${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "${BLUE}Workflow 5: Intelligent Rollback${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo ""
    echo "Scenario: Production issue requiring rollback"
    echo ""
    
    echo -e "${RED}[ALERT]${NC} Production error rate spike detected!"
    echo "  Error rate: 15% (threshold: 5%)"
    sleep 1
    
    echo -e "\n${CYAN}[ORCHESTRATOR]${NC} Initiating rollback protocol..."
    
    echo -e "\n${YELLOW}Phase 1: Analysis${NC}"
    echo -e "  ${CYAN}analytics-agent${NC} → Identifies problematic commit"
    echo -e "  ${CYAN}version-agent${NC} → Locates last stable version (v1.2.3)"
    
    echo -e "\n${YELLOW}Phase 2: Rollback${NC}"
    echo -e "  ${CYAN}version-agent${NC} → Reverts to v1.2.3"
    echo -e "  ${CYAN}build-agent${NC} → Emergency build initiated"
    echo -e "  ${CYAN}test-agent${NC} → Smoke tests passed"
    
    echo -e "\n${YELLOW}Phase 3: Root Cause${NC}"
    echo -e "  ${CYAN}code-review-agent${NC} → Analyzes failed changes"
    echo -e "  ${CYAN}issue-agent${NC} → Creates bug report #127"
    echo -e "  ${CYAN}knowledge-agent${NC} → Documents incident"
    
    sleep 3
    
    echo -e "\n${GREEN}✓ Rollback complete!${NC}"
    echo "  Downtime: 2 minutes"
    echo "  Root cause: Identified and documented"
    echo "  Fix scheduled: Sprint 5"
}

# Main menu
show_menu() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     Complex Agent Workflows Demo          ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Select a workflow to demonstrate:"
    echo ""
    echo "1) Parallel Feature Development"
    echo "2) Self-Healing Error Recovery"
    echo "3) Knowledge-Driven Development"
    echo "4) Conditional Branching Logic"
    echo "5) Intelligent Rollback"
    echo "6) Run All Workflows"
    echo "0) Exit"
    echo ""
}

# Run selected workflow
run_workflow() {
    case $1 in
        1) workflow_parallel_features ;;
        2) workflow_error_recovery ;;
        3) workflow_knowledge_driven ;;
        4) workflow_conditional ;;
        5) workflow_rollback ;;
        6) 
            workflow_parallel_features
            workflow_error_recovery
            workflow_knowledge_driven
            workflow_conditional
            workflow_rollback
            ;;
        0) 
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

# Main execution
if [ "$1" == "--all" ]; then
    run_workflow 6
elif [ -n "$1" ]; then
    run_workflow "$1"
else
    show_menu
    read -p "Enter choice: " choice
    run_workflow "$choice"
fi

echo -e "\n${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}Complex Workflows Demonstration Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"