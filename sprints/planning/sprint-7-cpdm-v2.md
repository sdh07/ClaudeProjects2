# Sprint 7: CPDM v2 Implementation

## Sprint Goal
Implement the CPDM improvements identified in Sprint 6 retrospective to make the process self-guiding and self-improving.

## Context
After Sprint 6's test drive, we identified critical gaps:
- PM needs guidance through the process
- Agents should self-verify their outputs
- Sprint artifacts need automatic management
- Feedback loops are missing

## Features to Implement

### Feature 1: PM Guide Agent
**What**: Interactive assistant that guides PM through CPDM phases
**Why**: Address confusion about process flow and next steps
**Deliverables**:
- `/agents/process/pm-guide-agent.md`
- Process state tracking
- Phase templates
- Context-aware guidance

### Feature 2: Sprint Cleanup Agent  
**What**: Automatic management of sprint artifacts
**Why**: Keep working directories clean and organized
**Deliverables**:
- `/agents/process/sprint-cleanup-agent.md`
- Archival automation
- Sprint summaries
- Directory maintenance

### Feature 3: Quality Gate Automation
**What**: Automated architecture compliance checking
**Why**: Reduce manual verification burden on PM
**Deliverables**:
- Enhanced quality-agent with auto-validation
- Architecture compliance checks
- Exception reporting

### Feature 4: Agent Self-Verification
**What**: Agents verify their own outputs match architecture
**Why**: Ensure consistency without manual checking
**Deliverables**:
- Update all agents with self-verification
- Add "verify_output" step to agent template
- Validation reports

### Feature 5: Feedback Integration
**What**: Systematic collection and application of feedback
**Why**: Enable continuous improvement
**Deliverables**:
- Feedback collection in retrospectives
- Agent performance metrics
- Auto-update mechanisms

## Sprint Schedule

### Day 1: Process Agents
- Create pm-guide-agent
- Create sprint-cleanup-agent
- Test basic functionality

### Day 2: Quality Automation
- Enhance quality-agent
- Implement compliance checks
- Add exception reporting

### Day 3: Self-Verification
- Update agent template
- Add verification to core agents
- Test verification flow

### Day 4: Feedback Loop
- Design feedback collection
- Implement metrics tracking
- Create improvement pipeline

### Day 5: Integration & Testing
- End-to-end CPDM v2 test
- Documentation updates
- Sprint retrospective

## Success Criteria
- [ ] PM can be guided through entire CPDM without confusion
- [ ] Sprint artifacts automatically archived
- [ ] Quality gates run without manual intervention
- [ ] Agents self-verify outputs
- [ ] Feedback systematically collected and applied

## Technical Approach

### pm-guide-agent Design
```yaml
triggers:
  - "start sprint"
  - "next phase"
  - "cpdm help"
capabilities:
  - Track current CPDM phase
  - Provide phase-specific templates
  - Suggest next actions
  - Validate phase completion
```

### sprint-cleanup-agent Design
```yaml
triggers:
  - "sprint complete"
  - "archive sprint"
  - Daily at midnight (current folder check)
capabilities:
  - Archive to /docs/archives/sprint-N/
  - Generate sprint summary
  - Clean working directories
  - Update sprint index
```

## Risk Mitigation
- Start with simple implementations
- Test each agent individually first
- Keep Sprint 6 learnings visible
- Get PM feedback at each step

## Definition of Done
- [ ] All 5 features implemented
- [ ] CPDM v2 documentation updated
- [ ] Agents deployed and tested
- [ ] PM successfully completes test run
- [ ] Retrospective captures improvements

---
*Sprint 7: Making CPDM self-guiding and self-improving*
*Next Sprint 8: Agent Excellence (proposed)*