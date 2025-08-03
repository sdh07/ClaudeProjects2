# ClaudeProjects2

A product management MVP for Claude-based projects using architecture-centric methodology.

## Overview

ClaudeProjects2 is an innovative project management system designed specifically for Claude-based development workflows. It integrates:
- Claude Code as the bedrock of our agents
- Obsidian for knowledge management
- Multiple MCP (Model Context Protocol) servers for enhanced functionality
- Architecture-centric software development methodology

## Architecture

### Physical Architecture Components
- **Claude Code**: Core agent infrastructure
- **Obsidian**: Knowledge management system
- **Context7 MCP**: Latest documentation access
- **Claude Code MCP**: Obsidian integration
- **Files and Obsidian MCP**: Claude Code integration
- **GitHub MCP**: Version control integration
- **Sequential MCP**: Workflow orchestration

## Project Structure

```
ClaudeProjects2/
├── .obsidian/          # Obsidian configuration
├── docs/               # Documentation
├── issues/             # Issue templates and tracking
├── src/                # Source code (future)
├── CLAUDE.md           # Claude-specific instructions
└── README.md           # This file
```

## Getting Started

1. Clone the repository
2. Open in Obsidian for knowledge management
3. Use Claude Code with the CLAUDE.md instructions
4. During work, use `#` to add learnings (e.g., `# Always run tests before commit`)

### Quick Tips for Claude Code
- Start any line with `#` to automatically update CLAUDE.md
- Use `/memory` to manually edit CLAUDE.md
- Run `./scripts/maintain-claude-md.sh` for health checks

## Development Methodology

We follow an architecture-centric approach:
1. Architect and research
2. Build
3. Test
4. Document
5. Commit

## Contributing

Please refer to our issue templates and development methodology documentation.