# Contributing to ClaudeProjects2

Thank you for your interest in contributing to ClaudeProjects2! This document provides guidelines and instructions for contributing.

## Code of Conduct

We are committed to providing a welcoming and inclusive environment. Please be respectful and constructive in all interactions.

## Getting Started

### Prerequisites
- Node.js >= 18.0.0
- npm >= 9.0.0
- Git
- Claude Code CLI (recommended)
- Obsidian (for knowledge management)

### Development Setup
```bash
# Clone the repository
git clone https://github.com/sdh07/ClaudeProjects2.git
cd ClaudeProjects2

# Install dependencies
npm install

# Install agent definitions
./scripts/install-agents.sh

# Run development mode
npm run dev
```

## How to Contribute

### 1. Architecture-First Approach
Before implementing any feature:
1. Review existing architecture in `/docs/architecture/`
2. Propose changes via an ADR if needed
3. Get architectural approval before coding

### 2. Issue Selection
1. Check [open issues](https://github.com/sdh07/ClaudeProjects2/issues)
2. Look for issues labeled `good-first-issue` or `help-wanted`
3. Comment on the issue to claim it
4. Wait for assignment before starting work

### 3. Development Workflow
```bash
# Create a feature branch
git checkout -b feature/your-feature-name

# Make changes following our methodology
# 1. Design/Update architecture if needed
# 2. Implement changes
# 3. Write/Update tests
# 4. Update documentation
# 5. Update CLAUDE.md if needed

# Run quality checks
npm run lint
npm run typecheck
npm test

# Commit with conventional commits
git commit -m "feat: add new feature"
# or
git commit -m "fix: resolve bug"
```

### 4. Pull Request Process
1. **Before Creating PR**:
   - Ensure all tests pass
   - Run `npm run lint` and fix issues
   - Update documentation
   - Add/Update tests for new features
   - Update CLAUDE.md if behavior changes

2. **PR Description**:
   - Link related issues
   - Describe changes clearly
   - Include screenshots for UI changes
   - List any breaking changes

3. **PR Checklist**:
   - [ ] Tests pass
   - [ ] Lint passes
   - [ ] Documentation updated
   - [ ] CLAUDE.md updated (if needed)
   - [ ] ADR created (if architectural change)
   - [ ] Follows our code style

## Coding Standards

### TypeScript
- Use strict mode
- Prefer functional programming
- Use explicit types (avoid `any`)
- Document complex functions

### React
- Functional components only
- Use hooks appropriately
- Memoize expensive computations
- Follow component structure guidelines

### Testing
- Aim for >80% coverage
- Write meaningful test descriptions
- Test edge cases
- Use data-testid for E2E tests

## Using AI Agents

We encourage using our specialized agents:

```bash
# For architecture design
# Use architecture-designer agent

# For documentation
# Use user-guide-writer agent

# For implementation
# Use code-generator-enhanced agent
```

## Commit Message Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes
- `refactor:` Code refactoring
- `test:` Test additions/changes
- `chore:` Build process/auxiliary tool changes

## Documentation

### Where to Document
- **Architecture decisions**: `/docs/architecture/decisions/`
- **User guides**: `/docs/guides/`
- **API documentation**: `/docs/api/`
- **Technical specs**: `/docs/specs/`

### Documentation Style
- Use clear, concise language
- Include examples
- Add diagrams (Mermaid preferred)
- Keep it up-to-date

## Review Process

1. **Automated Checks**: CI runs tests, linting, and type checking
2. **Code Review**: At least one maintainer review
3. **Architecture Review**: For significant changes
4. **Documentation Review**: For user-facing changes

## Release Process

We use semantic versioning and automated releases:
- Patch: Bug fixes
- Minor: New features (backward compatible)
- Major: Breaking changes

## Need Help?

- Check existing [documentation](./docs/)
- Ask in [GitHub Discussions](https://github.com/sdh07/ClaudeProjects2/discussions)
- Review [open issues](https://github.com/sdh07/ClaudeProjects2/issues)
- Contact maintainers

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Given credit in relevant documentation

Thank you for helping make ClaudeProjects2 better!