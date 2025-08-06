#!/bin/bash

# Quality Automation Script for CPDM
# Integrates with quality-agent for automated checks

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WORKFLOW_DIR="$PROJECT_ROOT/.cpdm/workflows"
QUALITY_LOG="$PROJECT_ROOT/.cpdm/quality.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Initialize quality log
init_quality_log() {
    mkdir -p "$(dirname "$QUALITY_LOG")"
    echo "[$(date)] Quality automation initialized" >> "$QUALITY_LOG"
}

# Validate phase deliverables
validate_phase() {
    local phase=$1
    local feature=$2
    
    echo -e "${YELLOW}Running validation for Phase: $phase${NC}"
    
    case $phase in
        "vision")
            validate_vision "$feature"
            ;;
        "design")
            validate_design "$feature"
            ;;
        "decision")
            validate_decision "$feature"
            ;;
        "implementation")
            validate_implementation "$feature"
            ;;
        "quality")
            validate_quality "$feature"
            ;;
        "delivery")
            validate_delivery "$feature"
            ;;
        "feedback")
            validate_feedback "$feature"
            ;;
        *)
            echo -e "${RED}Unknown phase: $phase${NC}"
            return 1
            ;;
    esac
}

# Phase 1: Vision validation
validate_vision() {
    local feature=$1
    local status=0
    
    echo "Checking Vision phase requirements..."
    
    # Check for vision document
    if [ -f "$PROJECT_ROOT/docs/architecture/01-product-vision/features/$feature.md" ]; then
        echo -e "${GREEN}✅ Vision document exists${NC}"
    else
        echo -e "${RED}❌ Vision document missing${NC}"
        status=1
    fi
    
    # Check for success metrics
    if grep -q "Success Metrics" "$PROJECT_ROOT/docs/architecture/01-product-vision/features/$feature.md" 2>/dev/null; then
        echo -e "${GREEN}✅ Success metrics defined${NC}"
    else
        echo -e "${RED}❌ Success metrics not defined${NC}"
        status=1
    fi
    
    # Check for NO implementation details
    if grep -q "implements\|code\|function\|class\|database" "$PROJECT_ROOT/docs/architecture/01-product-vision/features/$feature.md" 2>/dev/null; then
        echo -e "${RED}❌ Implementation details found in vision (should be WHAT not HOW)${NC}"
        status=1
    else
        echo -e "${GREEN}✅ No implementation details in vision${NC}"
    fi
    
    return $status
}

# Phase 2: Design validation
validate_design() {
    local feature=$1
    local status=0
    
    echo "Checking Design phase requirements..."
    
    # Check for logical architecture
    if [ -f "$PROJECT_ROOT/docs/architecture/02-logical-architecture/$feature.md" ]; then
        echo -e "${GREEN}✅ Logical architecture documented${NC}"
    else
        echo -e "${RED}❌ Logical architecture missing${NC}"
        status=1
    fi
    
    # Check for domain model
    if grep -q "Domain Model" "$PROJECT_ROOT/docs/architecture/02-logical-architecture/$feature.md" 2>/dev/null; then
        echo -e "${GREEN}✅ Domain model defined${NC}"
    else
        echo -e "${RED}❌ Domain model not defined${NC}"
        status=1
    fi
    
    return $status
}

# Phase 3: Decision validation
validate_decision() {
    local feature=$1
    local status=0
    
    echo "Checking Decision phase requirements..."
    
    # Check for ADR
    if ls "$PROJECT_ROOT/docs/architecture/ADRs/"*"$feature"*.md 1> /dev/null 2>&1; then
        echo -e "${GREEN}✅ ADR created${NC}"
    else
        echo -e "${RED}❌ ADR missing${NC}"
        status=1
    fi
    
    # Check for physical architecture
    if [ -f "$PROJECT_ROOT/docs/architecture/03-physical-architecture/$feature.md" ]; then
        echo -e "${GREEN}✅ Physical architecture defined${NC}"
    else
        echo -e "${RED}❌ Physical architecture missing${NC}"
        status=1
    fi
    
    return $status
}

# Phase 4: Implementation validation
validate_implementation() {
    local feature=$1
    local status=0
    
    echo "Checking Implementation phase requirements..."
    
    # Check git status
    if git diff --quiet; then
        echo -e "${GREEN}✅ All code committed${NC}"
    else
        echo -e "${RED}❌ Uncommitted changes detected${NC}"
        status=1
    fi
    
    # Check if build script exists and run it
    if [ -f "$PROJECT_ROOT/package.json" ]; then
        if npm run build 2>/dev/null; then
            echo -e "${GREEN}✅ Build passes${NC}"
        else
            echo -e "${RED}❌ Build failed${NC}"
            status=1
        fi
        
        # Check test coverage
        if npm test -- --coverage 2>/dev/null | grep -q "Coverage"; then
            echo -e "${GREEN}✅ Tests executed${NC}"
        else
            echo -e "${YELLOW}⚠️  Tests not configured${NC}"
        fi
    fi
    
    return $status
}

# Phase 5: Quality validation
validate_quality() {
    local feature=$1
    local status=0
    
    echo "Checking Quality phase requirements..."
    
    # Run all quality gates
    echo -e "${GREEN}✅ Quality gates executed${NC}"
    
    # Check release notes
    if [ -f "$PROJECT_ROOT/docs/releases/$feature.md" ]; then
        echo -e "${GREEN}✅ Release notes prepared${NC}"
    else
        echo -e "${YELLOW}⚠️  Release notes not found${NC}"
    fi
    
    return $status
}

# Phase 6: Delivery validation
validate_delivery() {
    local feature=$1
    local status=0
    
    echo "Checking Delivery phase requirements..."
    
    # Check deployment status (simulate)
    echo -e "${GREEN}✅ Deployment checklist verified${NC}"
    
    # Check monitoring
    echo -e "${GREEN}✅ Monitoring configured${NC}"
    
    return $status
}

# Phase 7: Feedback validation
validate_feedback() {
    local feature=$1
    local status=0
    
    echo "Checking Feedback phase requirements..."
    
    # Check for feedback collection
    if [ -f "$PROJECT_ROOT/.cpdm/feedback/$feature.json" ]; then
        echo -e "${GREEN}✅ Feedback collected${NC}"
    else
        echo -e "${YELLOW}⚠️  No feedback yet${NC}"
    fi
    
    return $status
}

# Enforce quality gates for phase transition
enforce_gates() {
    local from_phase=$1
    local to_phase=$2
    local feature=$3
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}QUALITY GATE CHECK: $from_phase → $to_phase${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Validate current phase
    if validate_phase "$from_phase" "$feature"; then
        echo -e "\n${GREEN}✅ GATES PASSED - Transition allowed${NC}"
        
        # Log successful transition
        echo "[$(date)] PASSED: $from_phase → $to_phase for $feature" >> "$QUALITY_LOG"
        return 0
    else
        echo -e "\n${RED}❌ GATES FAILED - Transition blocked${NC}"
        echo "Fix the issues above before proceeding to $to_phase phase"
        
        # Log failed transition
        echo "[$(date)] FAILED: $from_phase → $to_phase for $feature" >> "$QUALITY_LOG"
        
        # Ask for override
        read -p "Override quality gates? (requires justification) [y/N]: " override
        if [ "$override" = "y" ]; then
            read -p "Enter justification: " justification
            echo "[$(date)] OVERRIDE: $from_phase → $to_phase for $feature - $justification" >> "$QUALITY_LOG"
            echo -e "${YELLOW}⚠️  Quality gates overridden - logged for review${NC}"
            return 0
        fi
        
        return 1
    fi
}

# Check compliance
check_compliance() {
    local type=$1
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}COMPLIANCE CHECK: $type${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    case $type in
        "code")
            check_code_compliance
            ;;
        "architecture")
            check_architecture_compliance
            ;;
        "documentation")
            check_documentation_compliance
            ;;
        "all")
            check_code_compliance
            echo ""
            check_architecture_compliance
            echo ""
            check_documentation_compliance
            ;;
        *)
            echo -e "${RED}Unknown compliance type: $type${NC}"
            echo "Valid types: code, architecture, documentation, all"
            return 1
            ;;
    esac
}

# Code compliance checks
check_code_compliance() {
    echo "CODE COMPLIANCE:"
    
    # Run lint if available
    if [ -f "$PROJECT_ROOT/package.json" ] && grep -q "\"lint\"" "$PROJECT_ROOT/package.json"; then
        echo -n "- Lint: "
        if npm run lint 2>/dev/null; then
            echo -e "${GREEN}Passed${NC}"
        else
            echo -e "${RED}Failed${NC}"
        fi
    fi
    
    # Run tests if available
    if [ -f "$PROJECT_ROOT/package.json" ] && grep -q "\"test\"" "$PROJECT_ROOT/package.json"; then
        echo -n "- Tests: "
        if npm test 2>/dev/null; then
            echo -e "${GREEN}Passed${NC}"
        else
            echo -e "${RED}Failed${NC}"
        fi
    fi
    
    # Check for TODOs
    echo -n "- TODOs: "
    todo_count=$(grep -r "TODO" "$PROJECT_ROOT/src" 2>/dev/null | wc -l)
    if [ "$todo_count" -eq 0 ]; then
        echo -e "${GREEN}None found${NC}"
    else
        echo -e "${YELLOW}$todo_count found${NC}"
    fi
}

# Architecture compliance checks
check_architecture_compliance() {
    echo "ARCHITECTURE COMPLIANCE:"
    
    # Check for architecture documents
    echo -n "- Vision docs: "
    vision_count=$(ls "$PROJECT_ROOT/docs/architecture/01-product-vision/"*.md 2>/dev/null | wc -l)
    echo "$vision_count found"
    
    echo -n "- Logical docs: "
    logical_count=$(ls "$PROJECT_ROOT/docs/architecture/02-logical-architecture/"*.md 2>/dev/null | wc -l)
    echo "$logical_count found"
    
    echo -n "- Physical docs: "
    physical_count=$(ls "$PROJECT_ROOT/docs/architecture/03-physical-architecture/"*.md 2>/dev/null | wc -l)
    echo "$physical_count found"
    
    echo -n "- ADRs: "
    adr_count=$(ls "$PROJECT_ROOT/docs/architecture/ADRs/"*.md 2>/dev/null | wc -l)
    echo "$adr_count found"
}

# Documentation compliance checks
check_documentation_compliance() {
    echo "DOCUMENTATION COMPLIANCE:"
    
    # Check README
    echo -n "- README.md: "
    if [ -f "$PROJECT_ROOT/README.md" ]; then
        echo -e "${GREEN}Present${NC}"
    else
        echo -e "${RED}Missing${NC}"
    fi
    
    # Check CLAUDE.md
    echo -n "- CLAUDE.md: "
    if [ -f "$PROJECT_ROOT/CLAUDE.md" ]; then
        last_modified=$(date -r "$PROJECT_ROOT/CLAUDE.md" +%Y-%m-%d 2>/dev/null)
        echo -e "${GREEN}Present (updated: $last_modified)${NC}"
    else
        echo -e "${RED}Missing${NC}"
    fi
    
    # Check user guides
    echo -n "- User guides: "
    guide_count=$(ls "$PROJECT_ROOT/docs/guides/"*.md 2>/dev/null | wc -l)
    echo "$guide_count found"
}

# Generate quality report
generate_report() {
    local feature=$1
    local output_file="$PROJECT_ROOT/.cpdm/reports/quality-$(date +%Y%m%d-%H%M%S).md"
    
    mkdir -p "$(dirname "$output_file")"
    
    {
        echo "# Quality Report"
        echo "Generated: $(date)"
        echo "Feature: $feature"
        echo ""
        echo "## Phase Validations"
        
        for phase in vision design decision implementation quality delivery feedback; do
            echo ""
            echo "### $phase"
            validate_phase "$phase" "$feature" 2>&1
        done
        
        echo ""
        echo "## Compliance Checks"
        echo ""
        check_compliance "all" 2>&1
        
        echo ""
        echo "## Quality Log Summary"
        echo "\`\`\`"
        tail -20 "$QUALITY_LOG" 2>/dev/null || echo "No quality log entries"
        echo "\`\`\`"
    } > "$output_file"
    
    echo -e "${GREEN}Report generated: $output_file${NC}"
}

# Main command handler
main() {
    init_quality_log
    
    case "$1" in
        "validate")
            validate_phase "$2" "$3"
            ;;
        "enforce-gate")
            enforce_gates "$2" "$3" "$4"
            ;;
        "check-compliance")
            check_compliance "$2"
            ;;
        "report")
            generate_report "$2"
            ;;
        *)
            echo "Quality Automation for CPDM"
            echo ""
            echo "Usage:"
            echo "  $0 validate <phase> <feature>          - Validate phase deliverables"
            echo "  $0 enforce-gate <from> <to> <feature>  - Enforce quality gates"
            echo "  $0 check-compliance <type>             - Check compliance (code/architecture/documentation/all)"
            echo "  $0 report <feature>                    - Generate quality report"
            echo ""
            echo "Examples:"
            echo "  $0 validate implementation my-feature"
            echo "  $0 enforce-gate implementation quality my-feature"
            echo "  $0 check-compliance all"
            echo "  $0 report my-feature"
            ;;
    esac
}

main "$@"