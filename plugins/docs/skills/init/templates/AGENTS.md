# AGENTS.md

Instructions for AI coding agents working in this repository.

## Documentation Reading Order

Before implementing any feature, read docs in this order:
1. `docs/01-prd.md` — product requirements and user stories
2. `docs/02-erd.md` — engineering requirements and tech stack
3. `docs/03-architecture.md` — system design and patterns
4. `docs/04-coding-standards.md` — implementation standards
5. `docs/05-decision-log.md` — architectural decisions and their rationale

## Development Rules

**Always:**
- Follow the architecture described in docs/03-architecture.md
- Reuse existing patterns documented in docs/04-coding-standards.md
- Update the relevant docs section when you introduce something new
- Write tests for new functionality

**Never:**
- Introduce a new framework or library without updating docs/02-erd.md
- Duplicate existing functionality
- Change architectural patterns without adding an ADR to docs/05-decision-log.md

## After Completing a Feature

Run `/docs:update [feature-name]` to sync documentation with your changes.

## Documentation Skills Available

These commands come from the `docs` plugin. If the skills are installed
standalone (not via the plugin), drop the `docs:` prefix — e.g. `/init`.

| Command | When to use |
|---|---|
| `/docs:init` | Bootstrap docs from scratch (new projects only) |
| `/docs:update [module]` | Update docs after a feature or refactor |
| `/docs:check` | Audit documentation health and find gaps |
