# Vision → Sprint Plan Workflow

> **How YOUR vision automatically generates a prioritized sprint plan**

## Overview

This workflow demonstrates CPDM's most powerful capability: translating YOUR strategic vision directly into an actionable sprint plan with automatic feature prioritization.

---

## The Complete Flow

### Step 1: You Define the Vision Change

**You might say something like:**
- "We need to focus on enterprise customers now"
- "Performance is our top priority this quarter"
- "We're pivoting to AI-enhanced features"
- "Security and compliance are now critical"
- "Mobile experience needs to be our focus"

**Or any combination:**
- "We need enterprise features with focus on security and performance"

### Step 2: Update Vision Document

```bash
# You edit the vision
vi docs/architecture/01-product-vision/Product Vision.md
```

**You change emphasis, for example:**
```markdown
## Strategic Priorities (Updated Sprint 6)

### Primary Focus: Enterprise Readiness
- SSO and SAML integration
- Advanced security features
- Compliance certifications
- Team collaboration tools

### Secondary Focus: Performance at Scale
- Handle 10,000+ concurrent users
- Sub-100ms response times
- Horizontal scaling capability
```

### Step 3: Trigger Vision Analysis

```bash
# Notify system of vision update
vision-agent update-vision --major-change

# Or use CPDM workflow
./scripts/cpdm-workflow-engine.sh vision-update "Enterprise focus"
```

### Step 4: Automatic Feature Re-evaluation

**System automatically:**

1. **Scans all existing features** (backlog + in-progress)
2. **Re-calculates Triple Helix scores** based on new vision
3. **Updates ROI calculations** with new priorities
4. **Identifies misaligned features**
5. **Discovers new opportunities**

**You see output like:**
```
Analyzing impact of vision change...

Features Now Aligned:
✅ SSO Integration: Score 29/30 (was 20/30)
✅ Team Dashboards: Score 27/30 (was 18/30)
✅ Audit Logging: Score 26/30 (was 15/30)

Features Now Misaligned:
❌ Emoji Support: Score 8/30 (was 22/30)
❌ Dark Mode: Score 12/30 (was 24/30)

New Opportunities Identified:
🆕 LDAP Integration (Score: 28/30, ROI: 22x)
🆕 Compliance Dashboard (Score: 27/30, ROI: 18x)
🆕 Enterprise SLA Monitoring (Score: 26/30, ROI: 20x)

Recommendations:
- Pause 2 misaligned features
- Fast-track 3 enterprise features
- Consider 3 new opportunities
```

### Step 5: Generate Sprint Plan

```bash
# Generate prioritized sprint plan
vision-agent generate-sprint-plan --sprint=7

# Or interactive mode
pm-dashboard plan-sprint
```

**System generates:**

```markdown
# Sprint 7 Plan (Auto-Generated)

## Based on Vision: Enterprise Readiness

### Recommended Features (Capacity: 8)

Priority 1 - Critical Enterprise Features:
1. SSO Integration (29/30, ROI: 25x) - 3 days
2. Audit Logging (26/30, ROI: 20x) - 2 days
3. Team Dashboards (27/30, ROI: 18x) - 3 days

Priority 2 - Performance Enhancements:
4. Database Optimization (24/30, ROI: 15x) - 2 days
5. Caching Layer (23/30, ROI: 14x) - 2 days

Priority 3 - New Opportunities:
6. LDAP Integration (28/30, ROI: 22x) - 3 days
7. Compliance Dashboard (27/30, ROI: 18x) - 2 days

Suggested to Defer:
- Emoji Support (not aligned)
- Dark Mode (not critical)

Total Capacity Required: 17 days
Team Capacity Available: 15 days

RECOMMENDATION: Select items 1,2,3,4,5 for Sprint 7
```

### Step 6: You Make Final Decisions

**Interactive Selection:**
```
Select features for Sprint 7:
[x] 1. SSO Integration - 3 days
[x] 2. Audit Logging - 2 days
[x] 3. Team Dashboards - 3 days
[ ] 4. Database Optimization - 2 days (defer)
[x] 5. Caching Layer - 2 days
[x] 6. LDAP Integration - 3 days

Selected: 13 days (within capacity)
Confirm? [Y/n]
```

### Step 7: Sprint Plan Created

**System automatically:**
1. Creates GitHub issues for each feature
2. Assigns to Sprint 7 milestone
3. Sets priorities based on your selection
4. Updates project board
5. Notifies team

**Final Output:**
```
Sprint 7 Created Successfully!

GitHub Issues Created:
- #150: SSO Integration (P1)
- #151: Audit Logging (P1)
- #152: Team Dashboards (P1)
- #153: Caching Layer (P2)
- #154: LDAP Integration (P2)

Sprint Metrics:
- Total Capacity: 13 days
- Vision Alignment: 96%
- Expected ROI: 110x combined
- Risk Level: Low

Team Notified: ✅
Project Board Updated: ✅
Sprint Ready to Start: Monday
```

---

## Your Control Points

### 1. Vision Definition
**You control:**
- What to emphasize
- Priority changes
- New directions
- Success metrics

### 2. Feature Selection
**You control:**
- Which features to include
- Sprint capacity allocation
- Risk tolerance
- Defer/cancel decisions

### 3. Override Options
**You can always:**
- Include low-scoring features if business critical
- Exclude high-scoring features if not ready
- Adjust capacity based on team feedback
- Change priorities mid-sprint if needed

---

## Example Scenarios You Might Define

### Scenario A: "We just got enterprise customers"
```yaml
Vision Focus: Enterprise Features
Expected Changes:
  - SSO becomes critical
  - Audit logging required
  - Team features prioritized
  - Consumer features deferred
```

### Scenario B: "Performance complaints are hurting us"
```yaml
Vision Focus: Performance & Reliability
Expected Changes:
  - Performance features top priority
  - New features paused
  - Technical debt addressed
  - Monitoring enhanced
```

### Scenario C: "Competitor just launched AI features"
```yaml
Vision Focus: AI Innovation
Expected Changes:
  - AI features fast-tracked
  - ML capabilities added
  - Smart automation prioritized
  - Traditional features deferred
```

### Scenario D: "Security breach in the industry"
```yaml
Vision Focus: Security & Compliance
Expected Changes:
  - Security audit critical
  - Encryption upgraded
  - Compliance features added
  - Access controls enhanced
```

---

## Time Expectations

| Step | Time | Who |
|------|------|-----|
| Define vision change | 5 min | You |
| Update vision document | 10 min | You |
| System analysis | 2 min | Automated |
| Review recommendations | 10 min | You |
| Select features | 10 min | You |
| Sprint plan generation | 2 min | Automated |
| Review & confirm | 5 min | You |
| **Total** | **44 min** | - |

---

## Commands Reference

```bash
# Start vision update
vision-agent update-vision

# See current alignment
vision-agent show-alignment

# Get recommendations
vision-agent recommend-features --sprint=7

# Generate sprint plan
vision-agent create-sprint --number=7 --capacity=15

# Override automation
vision-agent include-feature "dark-mode" --reason="CEO wants it"

# Defer features
vision-agent defer-feature "emoji-support" --to-sprint=8
```

---

## Success Metrics

Your vision → sprint plan is successful when:
- ✅ Sprint features align with your vision (>90%)
- ✅ ROI justifies the selection
- ✅ Team capacity is properly utilized
- ✅ Risks are identified and acceptable
- ✅ GitHub issues created automatically
- ✅ You feel in control of the process

---

## The Power of This Workflow

1. **Strategic Alignment**: Every sprint directly serves your vision
2. **Data-Driven**: ROI and scores guide decisions
3. **Flexible**: You can override anything
4. **Fast**: 45 minutes from vision to plan
5. **Traceable**: Everything linked and documented
6. **Collaborative**: Team sees the "why" behind priorities

This is how CPDM transforms your strategic vision into tactical execution automatically while keeping you in complete control.

---

*This workflow will be tested on Day 2 of Sprint 6*
*You define the vision scenario*
*System generates the sprint plan*
*You make the final decisions*