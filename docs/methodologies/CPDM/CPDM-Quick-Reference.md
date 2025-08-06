# CPDM Quick Reference

## The Seven Phases

| Phase | Owner | Duration | Key Gate |
|-------|-------|----------|----------|
| **1. Vision** | vision-agent | 1 day | Triple Helix validation |
| **2. Design** | logical-architect-agent | 2-3 days | Domain completeness |
| **3. Decision** | physical-architect-agent | 1 day | ADR confirmation |
| **4. Implementation** | development-team | 3-5 days | Code review passed |
| **5. Quality** | quality-agent | 1 day | All tests passing |
| **6. Delivery** | deployment-team | 0.5 day | Deployment successful |
| **7. Feedback** | trace-agent | Ongoing | Metrics collected |

## Quick Commands

### Start New Feature
```bash
vision-agent validate-feature "Feature Name"
# Returns: Validation status, ROI, priority
```

### Check Phase Status
```bash
cpdm-status "Feature Name"
# Returns: Current phase, time in phase, blockers
```

### Force Gate Check
```bash
quality-agent check-gates --phase=current
# Returns: Gate status, failures, recommendations
```

## Gate Types

- **🔴 Mandatory**: Cannot proceed without passing
- **🟡 Recommended**: Should pass, override with justification
- **🟢 Optional**: Nice to have, log for improvement

## Workflow Patterns

### Standard (5-10 days)
```
Vision → Design → Decision → Implementation → Quality → Delivery → Feedback
```

### Fast Track (1-2 days)
```
Design → Decision → Implementation → Quality → Delivery
```

### Experimental (Variable)
```
Vision (hypothesis) → Design (prototype) → Implementation (spike) → Feedback (extensive)
```

## Common Gates

| Phase Transition | Mandatory Gates |
|-----------------|-----------------|
| Vision → Design | Triple Helix passed, ROI > 10x |
| Design → Decision | Domain model complete, boundaries clear |
| Decision → Implementation | ADRs confirmed, technologies selected |
| Implementation → Quality | Code reviewed, unit tests pass |
| Quality → Delivery | Integration tests pass, security clean |
| Delivery → Feedback | Deployment successful, monitoring active |

## Success Metrics

- **Cycle Time**: < 10 days standard feature
- **Gate Automation**: > 80%
- **Defect Escape**: < 5%
- **Traceability**: 100%

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Stuck at gate | Check `quality-agent diagnose-gate` |
| ADR pending | Run `physical-architect-agent list-pending-adrs` |
| Phase timeout | Use `cpdm-override --reason="justification"` |
| Missing trace | Run `trace-agent repair-links` |

## Emergency Overrides

**Use sparingly and document reason:**
```bash
cpdm-override --phase=current --gate=failing_gate --reason="Emergency fix for production"
```

---

*For full documentation see: [CPDM Complete Guide](./README.md)*
*Last Updated: 2025-02-06*