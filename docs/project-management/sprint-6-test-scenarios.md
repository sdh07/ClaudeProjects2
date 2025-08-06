# Sprint 6: CPDM Test Drive Scenarios

> **Testing the complete CPDM from a Product Manager perspective**

## Sprint 6 Overview

**Goal**: Validate that CPDM effectively guides Product Managers through real-world scenarios

**Duration**: 5 days

**Success Criteria**: 
- PM can manage features without technical knowledge
- All decision points are clear
- Feedback loops work automatically
- "This is the way" confirmation

---

## Test Scenario 1: Morning Routine (Day 1)

### Scenario Setup
You arrive Monday morning with emails about 3 new feature requests, 2 customer complaints, and a critical bug.

### Your Tasks

#### 8:00 AM - Check Dashboard
```bash
# Open your dashboard
cat docs/methodologies/CPDM/pm-dashboard-interactive.md

# Expected: See weekend activity summary
# Expected: 2 items need attention
```

#### 8:15 AM - Process Feature Requests

**Request 1: "Dark Mode"**
- Customer requested
- Evaluate with Triple Helix
- Make approval decision

```bash
# Start evaluation
./scripts/cpdm-workflow-engine.sh start "dark-mode" "UI theme support for dark mode"

# System should show:
# - Triple Helix: 24/30 (Good)
# - ROI: 8x (Below threshold)
# - Your decision: ???
```

**Request 2: "Batch Import"**
- Enterprise customer need
- High value potential
- Evaluate and decide

**Request 3: "Emoji Support"**
- Nice to have
- Low priority
- Quick decision needed

#### 8:30 AM - Handle Critical Bug
```bash
# Bug: "Login fails for SSO users"
# Use fast-track process
./scripts/cpdm-workflow-engine.sh start "sso-bugfix" "CRITICAL: Fix SSO login"
./scripts/cpdm-workflow-engine.sh override "sso-bugfix" "Critical production bug" "PM"
```

#### 9:00 AM - Review Decisions
- Check all features are progressing
- Verify bug fix is fast-tracked
- Document decisions

### Success Metrics
- [ ] All requests processed in 60 minutes
- [ ] Critical bug fast-tracked
- [ ] Decisions documented automatically
- [ ] Team notified of priorities

---

## Test Scenario 2: Vision Pivot (Day 2)

### Scenario Setup
CEO announces strategic shift: "We're now focusing on enterprise customers instead of individual users"

### Your Tasks

#### Update Vision
1. Modify product vision document
2. Change emphasis from "individual productivity" to "team collaboration"
3. Update success metrics

```bash
# Edit vision
vi docs/architecture/01-product-vision/Product Vision.md

# Notify system
vision-agent update-vision --major-change

# Expected: System re-evaluates all 20 active features
```

#### Review Re-prioritization
```bash
# See impact analysis
vision-agent show-vision-impact

# Expected output:
# 5 features now misaligned (marked for review)
# 3 features increased priority
# 12 features unchanged
# 2 new opportunities identified
```

#### Make Decisions
- Cancel misaligned features
- Approve new enterprise features
- Communicate changes to team

### Success Metrics
- [ ] Vision updated in < 30 minutes
- [ ] All features re-evaluated automatically
- [ ] Clear action items generated
- [ ] Team alignment maintained

---

## Test Scenario 3: Quality Gate Override (Day 3)

### Scenario Setup
Important feature fails performance test but customer demo is tomorrow

### Your Tasks

#### Assess the Situation
```bash
# Feature "real-time-sync" failed quality gate
quality-agent diagnose-gate --feature="real-time-sync"

# Output:
# Performance: 250ms (target: 100ms) ❌
# All other gates: PASSED ✅
```

#### Evaluate Options
1. **Option A**: Delay demo
2. **Option B**: Deploy with warning
3. **Option C**: Reduce scope
4. **Option D**: Override and optimize later

#### Make Decision
```bash
# If choosing Option D:
./scripts/cpdm-workflow-engine.sh override "real-time-sync" \
  "Customer demo critical, performance acceptable for demo" "PM"

# Create follow-up
vision-agent create-improvement "optimize-sync-performance" "HIGH"
```

### Success Metrics
- [ ] Decision made in < 15 minutes
- [ ] Risk assessment documented
- [ ] Follow-up actions created
- [ ] Stakeholders informed

---

## Test Scenario 4: Sprint Planning (Day 4)

### Scenario Setup
Plan Sprint 7 with competing priorities and limited resources

### Your Tasks

#### Review Backlog
```bash
# Get prioritized backlog
vision-agent show-backlog --prioritized

# Shows:
# 15 features ready
# 5 critical, 7 high, 3 medium
# Team capacity: 8 features
```

#### Use Data for Decisions
```bash
# Get ROI analysis
vision-agent analyze-roi --top=10

# Get technical dependencies
logical-architect-agent show-dependencies

# Get resource constraints
quality-agent show-capacity
```

#### Create Sprint Plan
1. Select 8 features based on:
   - ROI scores
   - Dependencies
   - Team capacity
   - Strategic alignment

2. Document rationale
3. Get team buy-in

### Success Metrics
- [ ] Sprint planned in < 2 hours
- [ ] Data-driven decisions
- [ ] Clear rationale documented
- [ ] Team consensus achieved

---

## Test Scenario 5: Production Crisis (Day 5)

### Scenario Setup
Production feature causing data loss, needs immediate rollback

### Your Tasks

#### Immediate Response
```bash
# 1. Initiate rollback
deployment-team rollback "data-export-feature"

# 2. Start root cause analysis
trace-agent analyze-failure "data-export-feature"

# 3. Create hotfix
./scripts/cpdm-workflow-engine.sh start "data-export-hotfix" "EMERGENCY: Fix data loss"
```

#### Manage Communication
- Notify stakeholders
- Update status page
- Document timeline

#### Post-Mortem
```bash
# Generate incident report
trace-agent generate-incident-report "data-export-failure"

# Update vision/policies
vision-agent add-constraint "data-integrity-validation"
```

### Success Metrics
- [ ] Rollback in < 5 minutes
- [ ] Root cause identified in < 30 minutes
- [ ] Hotfix deployed in < 2 hours
- [ ] Lessons documented

---

## Daily PM Workflow Test

### Morning (15 minutes)
```bash
# 1. Check dashboard
pm-dashboard

# 2. Process pending approvals
pm-dashboard process-approvals

# 3. Review blockers
./scripts/cpdm-workflow-engine.sh status --blocked
```

### Midday (10 minutes)
```bash
# 1. Check progress
./scripts/cpdm-workflow-engine.sh status --in-progress

# 2. Address questions
pm-dashboard show-questions
```

### End of Day (10 minutes)
```bash
# 1. Review completions
./scripts/cpdm-workflow-engine.sh status --completed-today

# 2. Update priorities for tomorrow
vision-agent update-priorities
```

---

## Validation Checklist

### User Experience
- [ ] Dashboard is intuitive
- [ ] Decisions are clear
- [ ] Notifications are helpful, not overwhelming
- [ ] Commands are memorable

### Process Flow
- [ ] Vision changes propagate automatically
- [ ] Quality gates protect without blocking
- [ ] Overrides are safe and tracked
- [ ] Feedback loops close properly

### Time Management
- [ ] Daily tasks < 30 minutes
- [ ] Weekly review < 2 hours
- [ ] Decision response < 15 minutes
- [ ] Crisis response < 5 minutes

### Business Value
- [ ] ROI tracking accurate
- [ ] Priorities align with strategy
- [ ] Resources used efficiently
- [ ] Stakeholders stay informed

---

## Sprint 6 Success Criteria

### Quantitative
- All 5 scenarios completed successfully
- Daily workflow takes < 35 minutes
- 90% of decisions made in first attempt
- Zero critical features blocked > 24 hours

### Qualitative
- PM feels in control
- Decisions are data-driven
- Process feels natural
- Would recommend to other PMs

### The Ultimate Test
**"Is this the way?"**
- [ ] Yes, this is the way
- [ ] Needs minor adjustments
- [ ] Needs major changes

---

## Feedback Collection

### Daily Feedback
- What worked well?
- What was confusing?
- What was missing?
- Time spent on PM tasks?

### Sprint Feedback
- Overall experience rating (1-10)
- Would you continue using CPDM?
- Top 3 improvements needed
- Missing capabilities

### Improvement Actions
All feedback will be:
1. Collected by trace-agent
2. Analyzed for patterns
3. Converted to improvements
4. Prioritized for Sprint 7

---

*Sprint 6: CPDM Test Drive*
*Duration: 5 days*
*Focus: Product Manager Experience*