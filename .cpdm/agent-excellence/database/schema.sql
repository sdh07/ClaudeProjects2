-- Agent Excellence Database Schema
-- Version: 1.0.0
-- Purpose: Track agent performance, improvements, and learning patterns

-- Agent registry
CREATE TABLE IF NOT EXISTS agents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    version TEXT NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'active' CHECK(status IN ('active', 'deprecated', 'testing')),
    parent_agent TEXT,
    improvement_count INTEGER DEFAULT 0
);

-- Performance metrics tracking
CREATE TABLE IF NOT EXISTS agent_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_name TEXT NOT NULL,
    task_id TEXT,
    execution_time_ms REAL,
    memory_usage_mb REAL,
    success BOOLEAN NOT NULL,
    error_message TEXT,
    error_type TEXT,
    task_context TEXT,
    input_size INTEGER,
    output_size INTEGER,
    tools_used TEXT, -- JSON array
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (agent_name) REFERENCES agents(name)
);

-- Improvement tracking
CREATE TABLE IF NOT EXISTS improvements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_name TEXT NOT NULL,
    version_before TEXT NOT NULL,
    version_after TEXT NOT NULL,
    improvement_type TEXT CHECK(improvement_type IN ('performance', 'reliability', 'capability', 'bugfix', 'refactor')),
    trigger_type TEXT CHECK(trigger_type IN ('technology', 'context', 'manual', 'scheduled')),
    description TEXT,
    performance_gain_percent REAL,
    success_rate_change REAL,
    applied_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    rollback_count INTEGER DEFAULT 0,
    status TEXT DEFAULT 'deployed' CHECK(status IN ('proposed', 'testing', 'deployed', 'rolled_back')),
    validation_score REAL,
    FOREIGN KEY (agent_name) REFERENCES agents(name)
);

-- Learning patterns repository
CREATE TABLE IF NOT EXISTS learning_patterns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pattern_name TEXT UNIQUE NOT NULL,
    pattern_type TEXT CHECK(pattern_type IN ('optimization', 'error_handling', 'integration', 'workflow')),
    pattern_description TEXT,
    applicability_criteria TEXT, -- JSON criteria
    improvement_template TEXT, -- Template for applying pattern
    success_rate REAL DEFAULT 0.0,
    usage_count INTEGER DEFAULT 0,
    avg_performance_gain REAL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_used DATETIME,
    confidence_score REAL DEFAULT 0.5
);

-- Technology updates tracking
CREATE TABLE IF NOT EXISTS technology_updates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    technology_name TEXT NOT NULL,
    version_before TEXT,
    version_after TEXT NOT NULL,
    update_type TEXT CHECK(update_type IN ('major', 'minor', 'patch', 'feature')),
    changes_summary TEXT,
    detected_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE,
    agents_affected TEXT, -- JSON array
    improvements_generated INTEGER DEFAULT 0
);

-- Agent failures for context learning
CREATE TABLE IF NOT EXISTS agent_failures (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_name TEXT NOT NULL,
    task_id TEXT,
    failure_type TEXT,
    error_message TEXT NOT NULL,
    stack_trace TEXT,
    context TEXT, -- JSON context
    frequency INTEGER DEFAULT 1,
    first_occurrence DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_occurrence DATETIME DEFAULT CURRENT_TIMESTAMP,
    resolved BOOLEAN DEFAULT FALSE,
    resolution_type TEXT,
    improvement_id INTEGER,
    FOREIGN KEY (agent_name) REFERENCES agents(name),
    FOREIGN KEY (improvement_id) REFERENCES improvements(id)
);

-- Agent templates
CREATE TABLE IF NOT EXISTS agent_templates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    template_name TEXT UNIQUE NOT NULL,
    template_type TEXT CHECK(template_type IN ('base', 'specialized', 'composite')),
    template_content TEXT NOT NULL, -- Full agent markdown template
    parameters TEXT, -- JSON parameters required
    usage_count INTEGER DEFAULT 0,
    success_rate REAL DEFAULT 0.0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Validation results
CREATE TABLE IF NOT EXISTS validation_results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    improvement_id INTEGER NOT NULL,
    test_type TEXT CHECK(test_type IN ('unit', 'integration', 'performance', 'security')),
    test_name TEXT,
    passed BOOLEAN NOT NULL,
    score REAL,
    details TEXT,
    executed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (improvement_id) REFERENCES improvements(id)
);

-- Rollback history
CREATE TABLE IF NOT EXISTS rollback_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    improvement_id INTEGER NOT NULL,
    agent_name TEXT NOT NULL,
    reason TEXT NOT NULL,
    trigger_type TEXT CHECK(trigger_type IN ('automatic', 'manual')),
    performance_before REAL,
    performance_after REAL,
    rolled_back_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (improvement_id) REFERENCES improvements(id),
    FOREIGN KEY (agent_name) REFERENCES agents(name)
);

-- Metrics aggregation (materialized view simulation)
CREATE TABLE IF NOT EXISTS metrics_summary (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_name TEXT NOT NULL,
    period_start DATETIME NOT NULL,
    period_end DATETIME NOT NULL,
    total_executions INTEGER DEFAULT 0,
    successful_executions INTEGER DEFAULT 0,
    failed_executions INTEGER DEFAULT 0,
    avg_execution_time_ms REAL,
    avg_memory_usage_mb REAL,
    success_rate REAL,
    p95_execution_time_ms REAL,
    p99_execution_time_ms REAL,
    unique_errors INTEGER DEFAULT 0,
    computed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(agent_name, period_start, period_end)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_metrics_agent_timestamp ON agent_metrics(agent_name, timestamp);
CREATE INDEX IF NOT EXISTS idx_metrics_success ON agent_metrics(success);
CREATE INDEX IF NOT EXISTS idx_improvements_agent ON improvements(agent_name);
CREATE INDEX IF NOT EXISTS idx_improvements_status ON improvements(status);
CREATE INDEX IF NOT EXISTS idx_failures_agent ON agent_failures(agent_name, resolved);
CREATE INDEX IF NOT EXISTS idx_patterns_type ON learning_patterns(pattern_type);
CREATE INDEX IF NOT EXISTS idx_technology_processed ON technology_updates(processed);
CREATE INDEX IF NOT EXISTS idx_validation_improvement ON validation_results(improvement_id);

-- Triggers for auto-updating timestamps
CREATE TRIGGER IF NOT EXISTS update_agent_timestamp 
AFTER UPDATE ON agents
BEGIN
    UPDATE agents SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_template_timestamp 
AFTER UPDATE ON agent_templates
BEGIN
    UPDATE agent_templates SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- Views for common queries
CREATE VIEW IF NOT EXISTS v_agent_performance AS
SELECT 
    a.name,
    a.version,
    a.status,
    COUNT(m.id) as total_executions,
    AVG(m.execution_time_ms) as avg_execution_time,
    SUM(CASE WHEN m.success = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(m.id) as success_rate,
    MAX(m.timestamp) as last_execution
FROM agents a
LEFT JOIN agent_metrics m ON a.name = m.agent_name
WHERE m.timestamp > datetime('now', '-7 days')
GROUP BY a.name, a.version, a.status;

CREATE VIEW IF NOT EXISTS v_recent_improvements AS
SELECT 
    i.agent_name,
    i.improvement_type,
    i.trigger_type,
    i.performance_gain_percent,
    i.status,
    i.applied_at,
    COUNT(v.id) as validation_tests,
    AVG(v.score) as avg_validation_score
FROM improvements i
LEFT JOIN validation_results v ON i.id = v.improvement_id
WHERE i.applied_at > datetime('now', '-30 days')
GROUP BY i.id
ORDER BY i.applied_at DESC;

CREATE VIEW IF NOT EXISTS v_pattern_effectiveness AS
SELECT 
    pattern_name,
    pattern_type,
    usage_count,
    success_rate,
    avg_performance_gain,
    confidence_score,
    last_used
FROM learning_patterns
WHERE confidence_score > 0.7
ORDER BY success_rate DESC, usage_count DESC;