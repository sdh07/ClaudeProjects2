# CPDM Improvement: Vision Phase Clarity

## Issue Identified
**Date**: 2025-08-06 (Sprint 6, Day 1)
**Discovered During**: Testing Agent Update feature evaluation
**Reported By**: Product Manager during CPDM test drive

## Problem
The Vision phase evaluation was mixing PM-level decisions with technical architecture details:
- Including implementation approaches (file watchers, Git integration)
- Suggesting technical phases and solutions
- Dictating HOW instead of focusing on WHAT and WHY

## Root Cause
- Vision agent template not clearly separated from Design phase
- Triple Helix evaluation bleeding into solution space
- Confusion about PM role boundaries

## Improvement Required

### Vision Phase Should Focus On:
✅ **WHAT** - What problem are we solving?
✅ **WHY** - Why is this valuable?
✅ **WHO** - Who benefits and how much?
✅ **WHEN** - What's the priority/urgency?
✅ **SUCCESS** - How do we measure success?

### Vision Phase Should NOT Include:
❌ **HOW** - Technical implementation details
❌ Architecture decisions
❌ Technology choices
❌ System design
❌ Implementation phases

## Proposed Changes to CPDM

### 1. Update Vision Agent Template
```yaml
vision_evaluation:
  business_case:
    - problem_statement
    - user_impact
    - strategic_alignment
    - success_criteria
  NOT:
    - technical_approach
    - architecture
    - implementation_plan
```

### 2. Add Phase Boundary Checks
- Quality gate: Flag any technical details in Vision phase
- Clear handoff: Vision → Design includes only requirements, not solutions

### 3. Update PM Dashboard
- Remove any implementation suggestions
- Focus on business metrics only
- Add warning if technical details creep in

## Impact
- Clearer role separation
- Faster PM decisions (less to review)
- Better architect autonomy in Design phase
- Reduced rework from premature technical decisions

## Action Items
1. Update vision-agent evaluation template
2. Add to CPDM documentation
3. Train all agents on phase boundaries
4. Add quality gate for phase separation

---
*Improvement Type: Process Clarity*
*Priority: HIGH*
*Discovered: Sprint 6 CPDM Test Drive*