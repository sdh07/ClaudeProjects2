# Development Guide

This guide helps you set up and work with the ClaudeProjects2 development environment.

## Quick Start

```bash
# Clone and setup
git clone https://github.com/sdh07/ClaudeProjects2.git
cd ClaudeProjects2
npm install

# Install agents for Claude Code
./scripts/install-agents.sh

# Start development
npm run dev
```

## Environment Setup

### Required Tools
- **Node.js** >= 18.0.0 (use [nvm](https://github.com/nvm-sh/nvm) for version management)
- **npm** >= 9.0.0
- **Git** >= 2.25
- **Claude Code** (latest version)
- **Obsidian** (for knowledge management)

### Recommended Tools
- **VS Code** with extensions:
  - ESLint
  - Prettier
  - TypeScript and JavaScript Language Features
  - Mermaid Preview
- **Docker Desktop** (for containerized development)

### Environment Variables
Create a `.env.local` file:
```env
# Development settings
NODE_ENV=development
LOG_LEVEL=debug

# API Keys (if needed)
ANTHROPIC_API_KEY=your_key_here

# Feature flags
ENABLE_EXPERIMENTAL_FEATURES=true
```

## Project Structure

```
ClaudeProjects2/
├── src/                    # Source code
│   ├── main/              # Electron main process
│   ├── renderer/          # React UI
│   ├── cli/              # CLI tool
│   └── shared/           # Shared utilities
├── agents/               # AI agent definitions
├── docs/                # Documentation
├── tests/               # Test suites
└── scripts/             # Build and utility scripts
```

## Development Workflow

### 1. Daily Setup
```bash
# Update dependencies
npm install

# Update CLAUDE.md from main
git pull origin main

# Check agent updates
./scripts/install-agents.sh

# Run maintenance check
./scripts/maintain-claude-md.sh
```

### 2. Feature Development

#### Using Claude Code
```bash
# Start a new feature with architecture design
claude "Design architecture for [feature name] using architecture-designer agent"

# Generate implementation
claude "Implement [component] based on the architecture"

# Create tests
claude "Write tests for [component] with >80% coverage"
```

#### Manual Development
1. Create feature branch: `git checkout -b feature/name`
2. Design architecture (if needed)
3. Implement feature
4. Write tests
5. Update documentation
6. Update CLAUDE.md

### 3. Testing

```bash
# Run all tests
npm test

# Run specific test file
npm test -- path/to/test.spec.ts

# Run with coverage
npm test -- --coverage

# Run in watch mode
npm test -- --watch
```

### 4. Code Quality

```bash
# Run linting
npm run lint

# Fix linting issues
npm run lint -- --fix

# Type checking
npm run typecheck

# Format code
npm run format

# Check formatting
npm run format:check
```

## Common Tasks

### Adding a New Agent
1. Create agent markdown file in `/agents/category/`
2. Follow the agent template in docs
3. Test with Claude Code
4. Document in agent registry

### Creating a Component
```bash
# Use code generator agent
claude "Create a React component for [purpose] following our patterns"
```

### Updating Documentation
```bash
# Use documentation agent
claude "Update user guide for [feature] using user-guide-writer agent"
```

### Debugging

#### Electron Main Process
```javascript
// Add to main process code
import { app } from 'electron';
app.commandLine.appendSwitch('remote-debugging-port', '9222');
```

#### React DevTools
Install React Developer Tools browser extension and it will work with Electron.

#### Logging
```typescript
import { logger } from '@/shared/logger';

logger.debug('Debug information');
logger.info('General information');
logger.warn('Warning message');
logger.error('Error details', error);
```

## Git Workflow

### Branch Naming
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test additions/updates

### Commit Messages
Follow [Conventional Commits](https://www.conventionalcommits.org/):
```bash
git commit -m "feat: add semantic search capability"
git commit -m "fix: resolve memory leak in agent runtime"
git commit -m "docs: update API documentation"
```

### Pre-commit Hooks
Husky runs automatically before commits:
- Linting
- Type checking
- Test execution
- Commit message validation

## Performance Optimization

### Development Build
```bash
# Fast development build with HMR
npm run dev
```

### Production Build
```bash
# Optimized production build
npm run build

# Analyze bundle size
npm run build -- --analyze
```

### Profiling
1. Use Chrome DevTools Performance tab
2. React Profiler for component performance
3. Electron performance monitoring

## Troubleshooting

### Common Issues

#### Dependencies not installing
```bash
# Clear npm cache
npm cache clean --force

# Delete node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

#### TypeScript errors
```bash
# Restart TS server in VS Code
Cmd/Ctrl + Shift + P → "TypeScript: Restart TS Server"

# Clear TS cache
rm -rf node_modules/.cache/typescript
```

#### Agent not found
```bash
# Reinstall agents
./scripts/install-agents.sh

# Check agent location
ls ~/.claude/agents/
```

### Getting Help
1. Check existing documentation
2. Search GitHub issues
3. Ask in discussions
4. Use Claude Code for debugging help

## Advanced Topics

### Custom Agent Development
See [Agent Markdown Specification](./docs/specs/Agent-Markdown-Specification.md)

### Architecture Patterns
Review [Architecture Decisions](./docs/architecture/decisions/)

### Performance Tuning
- Use React.memo for expensive components
- Implement virtual scrolling for large lists
- Lazy load heavy components
- Optimize Electron IPC communication

## CI/CD

### Local CI Simulation
```bash
# Run same checks as CI
npm run ci:local
```

### GitHub Actions
- **CI**: Runs on every push
- **Release**: Runs on version tags
- **Security**: Daily vulnerability scans

## Useful Commands

```bash
# Install specific dependency
npm install --save package-name
npm install --save-dev dev-package-name

# Update dependencies
npm update

# Check for outdated packages
npm outdated

# Audit for vulnerabilities
npm audit

# Fix vulnerabilities
npm audit fix
```

## Resources

- [Project Documentation](./docs/)
- [Architecture Guide](./docs/architecture/)
- [Agent Development](./docs/specs/Agent-Markdown-Specification.md)
- [Contributing Guide](./CONTRIBUTING.md)