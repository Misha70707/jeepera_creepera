# CLAUDE.md - AI Assistant Guide

This document provides comprehensive guidance for AI assistants working with the `tweny_fo_seven_trees_ixty_five` repository.

## Repository Overview

**Name:** tweny_fo_seven_trees_ixty_five
**Description:** Top Secret
**License:** Apache License 2.0
**Status:** Early stage - minimal structure established

## Project Type

Based on the `.gitignore` configuration, this repository appears to be set up for a **JetBrains MPS (Meta Programming System)** project. MPS is a language workbench for creating domain-specific languages (DSLs).

### Key Indicators:
- Ignores MPS-specific directories: `classes_gen`, `source_gen`, `test_gen`
- Ignores MPS workspace configuration: `workspace.xml`
- Ignores MPS build artifacts and JUnit test results

## Repository Structure

```
tweny_fo_seven_trees_ixty_five/
├── .git/                 # Git version control
├── .gitattributes        # Git text normalization (LF line endings)
├── .gitignore           # JetBrains MPS exclusions
├── LICENSE              # Apache License 2.0
├── README.md            # Project description
└── CLAUDE.md            # This file
```

### Current State
- **No source code yet** - repository contains only configuration files
- **Single commit** - "Initial commit" (5dec970)
- **Clean working directory** - no uncommitted changes

## Development Workflow

### Git Branch Strategy

**CRITICAL:** This repository uses a specific branch naming convention for AI assistant development:

**Current Development Branch:**
```
claude/claude-md-mhy3268tuaj600yz-013AKvQszRVaxYTr5bqk47FN
```

**Branch Naming Pattern:**
- Must start with `claude/`
- Must end with the session ID
- Format: `claude/<descriptive-name>-<session-id>`

### Git Operations Best Practices

#### Pushing Changes
```bash
# Always use -u flag for first push to set upstream
git push -u origin claude/claude-md-mhy3268tuaj600yz-013AKvQszRVaxYTr5bqk47FN

# CRITICAL: Branch must follow naming convention or push will fail with 403
```

**Retry Logic for Network Failures:**
- Retry up to 4 times with exponential backoff: 2s, 4s, 8s, 16s
- Applies to: `git push`, `git fetch`, `git pull`

#### Fetching/Pulling
```bash
# Fetch specific branch
git fetch origin claude/claude-md-mhy3268tuaj600yz-013AKvQszRVaxYTr5bqk47FN

# Pull specific branch
git pull origin claude/claude-md-mhy3268tuaj600yz-013AKvQszRVaxYTr5bqk47FN
```

### Commit Guidelines

**Format:**
```
<type>: <short description>

<optional detailed explanation>
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `refactor:` - Code restructuring without behavior change
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks
- `build:` - Build system changes

**Example:**
```bash
git commit -m "$(cat <<'EOF'
feat: Add initial MPS language definition

Created base language structure for domain-specific language.
Includes basic syntax and type system definitions.
EOF
)"
```

### Workflow Steps

1. **Ensure you're on the correct branch:**
   ```bash
   git checkout claude/claude-md-mhy3268tuaj600yz-013AKvQszRVaxYTr5bqk47FN
   ```

2. **Make changes and stage:**
   ```bash
   git add <files>
   ```

3. **Commit with descriptive message:**
   ```bash
   git commit -m "$(cat <<'EOF'
   <commit message>
   EOF
   )"
   ```

4. **Push to remote:**
   ```bash
   git push -u origin claude/claude-md-mhy3268tuaj600yz-013AKvQszRVaxYTr5bqk47FN
   ```

## AI Assistant Conventions

### Task Management

Use the TodoWrite tool for:
- Complex multi-step tasks (3+ steps)
- Non-trivial implementations
- Multiple user requests
- Tracking progress on ongoing work

**Mark tasks:**
- `pending` - Not started
- `in_progress` - Currently working (ONE at a time)
- `completed` - Finished

### Code Quality Standards

1. **Security First:**
   - Avoid OWASP Top 10 vulnerabilities
   - No command injection, XSS, SQL injection
   - Immediately fix any security issues discovered

2. **File Operations:**
   - Use specialized tools (Read, Edit, Write) over bash commands
   - Prefer editing existing files over creating new ones
   - Don't create documentation files unless explicitly requested

3. **Tool Usage:**
   - Use Task tool with `subagent_type=Explore` for codebase exploration
   - Run independent commands in parallel when possible
   - Use specific tools instead of bash when available

### Communication Guidelines

- **Concise responses** - This is a CLI environment
- **No emojis** unless explicitly requested
- **Technical accuracy** over validation
- **Direct, objective** technical information
- **Reference code** with `file_path:line_number` pattern

### File References

When referencing code, use this format:
```
The function is in src/main/Example.java:42
```

## Expected Project Development

Given the MPS-focused `.gitignore`, future development will likely include:

### Potential Directory Structure
```
tweny_fo_seven_trees_ixty_five/
├── languages/           # MPS language definitions
├── solutions/           # MPS solutions (application code)
├── models/              # MPS models
├── classes_gen/         # Generated Java classes (gitignored)
├── source_gen/          # Generated source files (gitignored)
├── test_gen/            # Generated test code (gitignored)
└── build/              # Build outputs
```

### MPS-Specific Patterns

**Generated Files (gitignored):**
- `classes_gen/` - Compiled Java bytecode
- `source_gen/` - Generated Java source
- `source_gen.caches/` - MPS caches
- `test_gen/` - Generated test code
- `test_gen.caches/` - Test caches

**Build Artifacts (gitignored):**
- `TEST-*.xml` - JUnit test results
- `junit*.properties` - JUnit configuration
- `workspace.xml` - IDE workspace settings
- `build.properties` - Build configuration

## GitHub CLI Note

The `gh` CLI tool is **not available** in this environment. For GitHub operations, request information directly from users.

## Environment Details

- **Platform:** Linux 4.4.0
- **Working Directory:** `/home/user/tweny_fo_seven_trees_ixty_five`
- **Git Status:** Clean working directory
- **Current Branch:** `claude/claude-md-mhy3268tuaj600yz-013AKvQszRVaxYTr5bqk47FN`

## Quick Reference

### Check Repository Status
```bash
git status
git log --oneline -10
ls -la
```

### Common Operations
```bash
# View all files including hidden
ls -la

# Search for pattern in files
# Use Grep tool, not bash grep

# Read file contents
# Use Read tool, not cat

# Edit files
# Use Edit tool, not sed/awk
```

## Notes for AI Assistants

1. **Repository is minimal** - Only configuration files exist currently
2. **MPS project expected** - Based on gitignore configuration
3. **Branch naming is strict** - Must follow `claude/<name>-<session-id>` pattern
4. **No main branch specified** - This is a feature branch workflow
5. **Apache 2.0 licensed** - Open source, commercial use allowed

## Future Development Checklist

When adding MPS language definitions:
- [ ] Create language structure in `languages/` directory
- [ ] Define language aspects (structure, editor, typesystem, etc.)
- [ ] Add solutions in `solutions/` directory
- [ ] Configure build scripts
- [ ] Add tests
- [ ] Update this CLAUDE.md with project-specific conventions

## Questions to Clarify

If you're developing this repository, consider documenting:
1. What is the specific DSL being created?
2. What is the domain/problem being solved?
3. Are there specific MPS version requirements?
4. What build system is being used (Ant, Gradle)?
5. What are the testing requirements?

---

**Last Updated:** 2025-11-13
**Document Version:** 1.0.0
**Branch:** claude/claude-md-mhy3268tuaj600yz-013AKvQszRVaxYTr5bqk47FN
