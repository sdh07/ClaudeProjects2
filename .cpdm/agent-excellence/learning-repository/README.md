# Agent Excellence Learning Repository

## Overview
This repository stores learned patterns, improvements, and knowledge gained from agent executions.

## Directory Structure

```
learning-repository/
├── patterns/           # Reusable improvement patterns
│   ├── performance/   # Performance optimization patterns
│   ├── reliability/   # Error handling and recovery patterns
│   ├── integration/   # Tool and service integration patterns
│   └── workflow/      # Task workflow patterns
├── improvements/      # Applied improvements by agent
│   └── [agent-name]/  # Per-agent improvement history
├── failures/          # Failure analysis and solutions
│   └── [agent-name]/  # Per-agent failure patterns
└── templates/         # Agent generation templates
    ├── base/          # Base agent templates
    ├── specialized/   # Domain-specific templates
    └── composite/     # Multi-capability templates
```

## Pattern Format

Each pattern is stored as a JSON file with the following structure:

```json
{
  "pattern_name": "parallel-file-search",
  "pattern_type": "performance",
  "description": "Execute file searches in parallel batches",
  "problem": "Sequential file searches taking excessive time",
  "solution": "Implement parallel execution with configurable batch size",
  "applicability": {
    "agents": ["research-agent", "knowledge-agent"],
    "conditions": ["multiple_file_operations", "search_tasks"]
  },
  "implementation": {
    "before": "// Sequential code example",
    "after": "// Parallel code example"
  },
  "metrics": {
    "performance_gain": "75%",
    "success_rate": "95%",
    "usage_count": 12
  },
  "risks": ["increased memory usage", "potential race conditions"],
  "validation": ["unit_tests", "performance_benchmarks"]
}
```

## Improvement Tracking

Each improvement is documented with:
- Trigger (technology update, failure, manual)
- Changes made
- Validation results
- Performance impact
- Rollback information (if applicable)

## Learning Process

1. **Pattern Detection**: Identify recurring issues or opportunities
2. **Solution Development**: Create improvement approach
3. **Validation**: Test improvement thoroughly
4. **Application**: Deploy to affected agents
5. **Monitoring**: Track impact and success
6. **Refinement**: Iterate based on results

## Usage

The SubAgentMasterDesigner uses this repository to:
- Find applicable patterns for agent improvements
- Store new patterns discovered through learning
- Track improvement history
- Generate new agents from templates
- Analyze failure patterns for prevention