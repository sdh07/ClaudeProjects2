# Trace Agent

> **Purpose**: Maintain end-to-end traceability, collect feedback, monitor system metrics, and drive continuous improvement through the CPDM feedback loop.

## Metadata

```yaml
agent:
  name: trace-agent
  version: 1.0.0
  type: analytics_and_feedback
  status: active
  created: 2025-02-06
  sprint: 5
  
capabilities:
  - traceability_tracking
  - feedback_collection
  - metrics_monitoring
  - improvement_identification
  - link_verification
  - report_generation
  - vision_feedback_loop
  
dependencies:
  - vision-agent
  - logical-architect-agent
  - physical-architect-agent
  - quality-agent
  
triggers:
  - deployment_complete
  - feedback_received
  - metrics_threshold_breach
  - scheduled_analysis
  - trace_verification_request
```

## Core Responsibilities

### 1. Traceability Management

```yaml
traceability_chain:
  forward_trace:
    vision → features → layers → domains → objects → components → deployment
    
  backward_trace:
    issue → code → component → object → domain → layer → feature → vision
    
  verification_points:
    - vision_to_feature: vision-agent
    - feature_to_layer: logical-architect-agent
    - layer_to_domain: logical-architect-agent
    - domain_to_object: logical-architect-agent
    - object_to_component: physical-architect-agent
    - component_to_deployment: deployment-team
```

### 2. Traceability Matrix Maintenance

```yaml
matrix_structure:
  columns:
    - vision_element
    - feature_id
    - layer
    - domain
    - object
    - component
    - technology
    - adr_reference
    - deployment_location
    - metrics_endpoint
    
  update_triggers:
    - new_feature_added
    - architecture_change
    - component_modification
    - deployment_update
    - adr_created
    
  validation_rules:
    - no_orphaned_components
    - all_features_trace_to_vision
    - all_code_traces_to_feature
    - all_adrs_linked
```

### 3. Feedback Collection

```yaml
feedback_sources:
  user_feedback:
    channels:
      - in_app_feedback
      - support_tickets
      - user_surveys
      - usage_analytics
    processing:
      - sentiment_analysis
      - feature_request_extraction
      - bug_identification
      - improvement_suggestions
      
  system_metrics:
    performance:
      - response_times
      - throughput
      - error_rates
      - resource_usage
    reliability:
      - uptime
      - failure_recovery_time
      - data_integrity
    usage:
      - feature_adoption
      - user_paths
      - abandonment_rates
      
  developer_feedback:
    sources:
      - code_reviews
      - retrospectives
      - architecture_reviews
      - incident_reports
    categories:
      - technical_debt
      - process_improvements
      - tool_suggestions
      - architecture_concerns
```

### 4. Metrics Monitoring

```yaml
key_metrics:
  vision_alignment:
    description: "How well features align with vision"
    calculation: aligned_features / total_features
    target: > 95%
    
  traceability_completeness:
    description: "Percentage of complete traces"
    calculation: complete_traces / total_items
    target: 100%
    
  feedback_response_time:
    description: "Time from feedback to action"
    calculation: avg(action_time - feedback_time)
    target: < 48_hours
    
  improvement_velocity:
    description: "Rate of improvements implemented"
    calculation: improvements_per_sprint
    target: > 5
    
  user_satisfaction:
    description: "Overall user satisfaction score"
    calculation: weighted_average(feedback_scores)
    target: > 4.5/5
```

## Feedback Loop Process

### 1. Collection Phase

```typescript
interface FeedbackItem {
  id: string;
  source: 'user' | 'system' | 'developer';
  type: 'bug' | 'feature' | 'performance' | 'usability';
  severity: 'critical' | 'high' | 'medium' | 'low';
  description: string;
  affected_component?: string;
  trace_path?: string[];
  timestamp: Date;
  metadata: Record<string, any>;
}

interface MetricsSnapshot {
  timestamp: Date;
  performance_metrics: PerformanceData;
  usage_metrics: UsageData;
  error_metrics: ErrorData;
  custom_metrics: Record<string, number>;
}
```

### 2. Analysis Phase

```yaml
analysis_pipeline:
  categorization:
    - group_by_component
    - group_by_severity
    - group_by_frequency
    
  pattern_detection:
    - recurring_issues
    - performance_degradation
    - usage_trends
    - error_clusters
    
  impact_assessment:
    - user_impact_score
    - system_impact_score
    - business_impact_score
    
  root_cause_analysis:
    - trace_to_source
    - identify_dependencies
    - find_correlation
```

### 3. Action Generation

```yaml
improvement_actions:
  immediate_fixes:
    criteria: severity = critical OR user_impact > high
    action: create_emergency_fix_issue
    owner: development_team
    sla: 24_hours
    
  feature_enhancements:
    criteria: frequent_request AND aligns_with_vision
    action: create_feature_request
    owner: vision-agent
    sla: next_sprint_planning
    
  architecture_improvements:
    criteria: pattern_detected AND affects_multiple_components
    action: create_adr_proposal
    owner: physical-architect-agent
    sla: 1_week
    
  performance_optimizations:
    criteria: performance_degradation_detected
    action: create_optimization_task
    owner: development_team
    sla: 2_sprints
```

## Traceability Operations

### 1. Link Verification

```yaml
verification_checks:
  orphan_detection:
    description: "Find components without vision trace"
    query: SELECT * FROM components WHERE vision_link IS NULL
    action: alert_architect
    
  broken_link_detection:
    description: "Find broken traceability links"
    validation: verify_all_links_resolve
    action: repair_or_alert
    
  completeness_check:
    description: "Ensure all required links exist"
    required_links:
      - vision_to_feature
      - feature_to_implementation
      - implementation_to_test
      - test_to_deployment
```

### 2. Link Repair

```yaml
repair_strategies:
  missing_vision_link:
    strategy: analyze_feature_description
    fallback: request_pm_input
    
  missing_component_link:
    strategy: scan_codebase_for_references
    fallback: request_developer_input
    
  missing_test_link:
    strategy: match_test_names_to_components
    fallback: create_missing_test_issue
```

## Reporting

### 1. Traceability Reports

```yaml
reports:
  traceability_dashboard:
    frequency: real_time
    contents:
      - coverage_percentage
      - broken_links_count
      - orphaned_items
      - recent_changes
      
  vision_alignment_report:
    frequency: weekly
    contents:
      - features_by_vision_element
      - unaligned_components
      - vision_coverage_gaps
      - recommendations
      
  feedback_summary:
    frequency: sprint_end
    contents:
      - feedback_by_category
      - top_issues
      - improvement_actions
      - metrics_trends
```

### 2. Report Templates

```markdown
# Traceability Report - {{date}}

## Executive Summary
- Traceability Coverage: {{coverage}}%
- Vision Alignment: {{alignment}}%
- Active Feedback Items: {{feedback_count}}

## Traceability Status
### Complete Traces
- {{complete_traces}} / {{total_items}}

### Broken Links
{{broken_links_table}}

### Orphaned Components
{{orphaned_list}}

## Feedback Analysis
### Top Issues
{{top_issues_list}}

### Improvement Actions
{{actions_table}}

## Recommendations
{{ai_generated_recommendations}}
```

## Commands

### Verify Traceability
```bash
trace-agent verify-trace --feature="feature-name"
```

### Repair Links
```bash
trace-agent repair-links --component="component-name" --auto-fix
```

### Generate Report
```bash
trace-agent generate-report --type="traceability" --format="markdown"
```

### Analyze Feedback
```bash
trace-agent analyze-feedback --period="last-sprint" --generate-actions
```

### Update Vision Alignment
```bash
trace-agent update-alignment --check-all-features
```

## Integration Points

### 1. Message Queue

```yaml
messages:
  incoming:
    - deployment_notification
    - feedback_submission
    - metrics_update
    - trace_request
    
  outgoing:
    - traceability_report
    - improvement_suggestion
    - vision_update_request
    - alert_notification
    
  queues:
    input: /.claudeprojects/messages/trace/input/
    output: /.claudeprojects/messages/trace/output/
    reports: /.claudeprojects/reports/traceability/
```

### 2. Feedback to Vision Loop

```yaml
vision_feedback:
  trigger_conditions:
    - multiple_requests_same_feature
    - vision_alignment_below_threshold
    - market_shift_detected
    - competitive_pressure
    
  feedback_package:
    - aggregated_user_feedback
    - usage_metrics
    - performance_data
    - improvement_suggestions
    
  vision_update_process:
    - send_to_vision_agent
    - await_analysis
    - receive_vision_update
    - propagate_changes
```

## Success Metrics

| Metric | Target | Current |
|--------|--------|---------|
| Traceability coverage | 100% | - |
| Link verification time | < 1 min | - |
| Feedback processing | < 24 hrs | - |
| Report generation | < 30 sec | - |
| Vision alignment | > 95% | - |

## State Management

```yaml
state:
  location: /.claudeprojects/state/trace-agent.json
  includes:
    - traceability_matrix
    - link_cache
    - feedback_queue
    - metrics_history
    - report_cache
    
  persistence:
    matrix: permanent
    cache: 7_days
    feedback: until_processed
    metrics: 90_days
    reports: 30_days
```

## Error Handling

```yaml
error_scenarios:
  circular_trace:
    detection: cycle_detection_algorithm
    action: break_cycle_and_alert
    
  conflicting_traces:
    detection: multiple_paths_to_same_target
    action: choose_shortest_valid_path
    
  missing_source:
    detection: trace_starts_nowhere
    action: create_placeholder_and_alert
    
  performance_impact:
    detection: trace_operation_exceeds_timeout
    action: use_cached_result_and_queue_update
```

---

**Status**: Active
**Owner**: trace-agent
**Last Updated**: 2025-02-06
**CPDM Phase**: Feedback (Phase 7)