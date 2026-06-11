# Product Requirements Document
### doc-skills — Claude Code Documentation Skill Suite

**Version**: 1.3
**Date**: 2026-06-11
**Status**: Confirmed
**Packaging**: Distributed as a Claude Code plugin (`docs`) via the `ndollem-docs-tools` marketplace. Skills are namespaced: `/docs:init`, `/docs:update`, `/docs:check`.

---

## Vision

Give software developers a set of Claude Code skills that make project documentation a first-class, low-friction part of the development workflow — so that documentation is generated from the codebase, kept in sync as the code evolves, and audited proactively rather than left to decay.

---

## Problem Statement

Developer teams working in AI-assisted environments face a documentation paradox: AI coding agents need rich, structured project context to be effective, but creating and maintaining that context requires exactly the kind of repetitive, time-consuming writing that teams want to avoid.

The common result is one of two failure modes:

1. **Documentation never gets written.** AI agents operate on incomplete context and produce inconsistent code. Engineers spend time re-explaining decisions they've already made.
2. **Documentation gets written once and abandoned.** Docs describe a system that no longer exists. Engineers stop trusting them. The cycle repeats.

Neither outcome supports the goal of scalable, AI-first development.

---

## Business Goals

1. Eliminate the manual effort of bootstrapping project documentation from scratch.
2. Make documentation maintenance a lightweight, incremental habit rather than a periodic big-batch effort.
3. Improve AI agent output quality by ensuring agents always have accurate, structured project context.
4. Create a single, consistent documentation standard that works across multiple projects and teams.
5. Make documentation gaps visible and actionable, not invisible and accumulating.

---

## Target Users

### Primary — Individual Developer (Solo or Lead)
Works on one or more codebases, uses Claude Code daily, wants AI agents to produce higher-quality output without having to repeat context in every session. Does not want to spend time formatting documents manually.

### Secondary — Development Team
A team of 2–8 engineers sharing a repository. Wants documentation standards that are consistent across contributors and preserved in version control. May include junior engineers who benefit from a well-documented codebase.

### Tertiary — Engineering Manager / Tech Lead
Cares about documentation health at a project level. Wants a way to audit whether documentation is current without reading every file manually.

---

## User Roles

| Role | Description |
|---|---|
| Developer | Installs and invokes the skills, reviews AI-generated content, fills in human-only sections |
| Team Lead | Hosts the marketplace repo, manages plugin versions, sets documentation standards |
| AI Agent (Claude) | Executes skill instructions, reads codebase, writes and updates documentation |

---

## User Journeys

### Journey 1 — Retrofitting docs onto an existing project

A developer has a codebase with no documentation. They install the `docs` plugin (`/plugin install docs@ndollem-docs-tools`), open Claude Code in the project, and run `/docs:init`. Claude scans the codebase, generates the full `docs/` folder with all five standard documents, marks sections it cannot infer with `⚠️`, and prints a summary of what needs human review. The developer spends 20–30 minutes filling in business context, then commits the docs to git.

### Journey 2 — Keeping docs in sync during active development

A developer ships a new authentication module. After the feature is merged, they run `/docs:update auth-module`. Claude reads the changed code and git history, identifies which sections of the architecture, ERD, and coding standards docs are affected, and updates only those sections — tagging new content with `<!-- AI-generated -->`. The developer reviews the diff, approves it, and commits.

### Journey 3 — Auditing documentation health

A developer returns to a project after two months away, or a new team member joins. They run `/docs:check`. Claude compares the current codebase against the docs, checks the `LAST_REVIEWED` timestamp, counts unresolved `⚠️` flags, and produces a health report showing what is current, what has drifted, and a prioritised list of recommended actions.

### Journey 4 — Starting a brand new project

A developer is bootstrapping a new project from scratch. They run `/docs:init "SaaS app for managing restaurant reservations"`. Claude uses the description hint combined with any existing files (package.json, README, etc.) to produce an initial documentation set. Business sections that cannot be inferred are flagged for human input.

### Journey 5 — Team onboarding

A new engineer joins a project. They add the team marketplace and install the plugin (two commands: `/plugin marketplace add …` then `/plugin install docs@ndollem-docs-tools`), then have `/docs:update` and `/docs:check` available across every project. The `AGENTS.md` file the plugin generated tells them the documentation workflow.

---

## Features

---

### Feature 1 — `/docs:init`

**Description**
Bootstrap a complete standard documentation set for a project that has no existing `docs/` folder. Reads any documentation the repo already ships (README, PRD, CHANGELOG, release notes, ARCHITECTURE, ADRs, `docs/*.md`) as the authoritative reference first, then optionally scans the codebase to corroborate and fill gaps, flags what it cannot determine, and generates all documents in one pass.

**User Story**
As a developer starting a new project or retrofitting docs onto an existing codebase, I want to generate a full documentation set automatically so that I don't have to write templates from scratch or repeat myself across multiple documents.

**Acceptance Criteria**
- Refuses to run if `docs/` already exists and contains `.md` files; directs the user to `/docs:update` instead.
- Reads existing human-written documentation first (via `doc-context docs`: README, PRD, CHANGELOG, release notes, ARCHITECTURE, CONTRIBUTING, ROADMAP, ADRs, `docs/*.md`) and treats it as the authoritative reference, never silently contradicting it.
- Reads project config files (package.json, pyproject.toml, go.mod, Cargo.toml, Dockerfile, docker-compose, .env.example) before writing anything.
- Supports an optional `--scan docs|full` flag controlling read depth: `docs` reads existing docs + manifests only (cheapest), `full` also scans the codebase (thorough, higher token cost). When omitted, asks the user interactively after summarizing existing-doc coverage; with `--yes` and no `--scan`, defaults to `full`. The resolved depth and the referenced docs are recorded in `docs/LAST_REVIEWED`.
- Generates the standard outputs: `docs/01-prd.md`, `docs/02-erd.md`, `docs/03-architecture.md`, `docs/04-coding-standards.md`, `docs/05-decision-log.md`, `AGENTS.md`, `CLAUDE.md` (imports `AGENTS.md` via `@AGENTS.md` so Claude Code loads the instructions), `.ai/project-definition.json`, and `docs/LAST_REVIEWED`.
- **Never overwrites an existing file.** Before writing, it classifies each target as Create / Skip (already exists — preserved) / Merge, and shows all three in the confirmation preview. The only non-create action is appending the `@AGENTS.md` import to a pre-existing `CLAUDE.md` that lacks it. This holds even with `--yes`, making `/docs:init` idempotent and safe to re-run.
- Marks every section it cannot infer with `> ⚠️ [Needs human input]` — does not fabricate business goals or user personas.
- Reports a confidence level (LOW / MEDIUM / HIGH) for business layer and technical layer separately.
- Prints a post-run summary listing files created, confidence levels, and sections needing human review.
- Can accept an optional plain-language description as an argument to guide generation.
- Works whether or not the project is a git repository — environment scanning goes through `doc-context`, which degrades gracefully when git is absent.
- Supports an optional `--interactive` flag: when passed, interviews the user (via AskUserQuestion) to fill Vision, Target Users, Business Goals, and Out-of-Scope instead of leaving `⚠️` markers. Default (no flag) stays passive.
- Supports an optional `--lang en|id|auto` flag controlling the language of generated documentation prose (default `en`; `id` = Bahasa Indonesia; `auto` = match the repo). Headings, `⚠️`/`<!-- AI-generated -->` markers, and JSON keys remain English so the other skills can parse them. The resolved language is recorded in `docs/LAST_REVIEWED` so `/docs:update` keeps subsequent edits in the same language.
- Invocable only by the user (`disable-model-invocation: true`) — Claude cannot trigger it automatically.

**Dependencies**
Claude Code with plugin support. Git is optional, not required.

**Future Enhancements**
- Support for monorepo setups with per-package documentation.

---

### Feature 2 — `/docs:update [area]`

**Description**
Update only the sections of existing documentation affected by a specific code change, feature, or refactor. Surgical by design — never rewrites whole documents, never overwrites human-written content.

**User Story**
As a developer who has just shipped a feature or refactored a module, I want to sync the documentation with my changes in a single command so that docs stay current without requiring me to manually find and edit the right sections.

**Acceptance Criteria**
- Requires a `docs/` folder to exist; stops and directs the user to `/docs:init` if absent.
- Reads all existing doc files before making any changes.
- Reads recent changes via `doc-context diff` (git-aware) and the files relevant to `$ARGUMENTS`. When the project has no git history, falls back to reading the files named in `$ARGUMENTS` directly.
- Consults relevant existing/external docs (via `doc-context docs`) when `$ARGUMENTS` relates to one — e.g. a release/version bump reconciles against the `CHANGELOG`/release notes — while still editing only files under `docs/`.
- Performs surgical edits with the `Edit` tool — changes only affected sections and never rewrites a whole document. `Write` is used only to create a file that does not yet exist.
- Updates only sections in documents that are logically affected by `$ARGUMENTS`.
- Never modifies business goals, vision, or product decisions — flags them for human confirmation if they appear to have changed.
- Tags all AI-generated additions with `<!-- AI-generated -->`.
- Adds an ADR entry to `docs/05-decision-log.md` if the change involved a significant technical decision (new library, pattern change, architectural choice).
- Updates `docs/LAST_REVIEWED` with the date, area updated, and files modified.
- Prints a summary of changes made, sections flagged, and sections intentionally skipped.
- Invocable only by the user (`disable-model-invocation: true`).

**Dependencies**
`/docs:init` must have been run first. Git is optional — recent-change detection uses it when present and falls back to direct file reads otherwise.

**Future Enhancements**
- Batch update mode: `/docs:update --since [date]` to catch up on multiple accumulated changes.
- PR integration: auto-suggest running `/docs:update` when a PR is merged.

---

### Feature 3 — `/docs:check`

**Description**
Read-only documentation health audit. Compares current docs against the codebase, checks freshness, counts unresolved gaps, detects drift, and produces a prioritised health report with recommended actions.

**User Story**
As a developer returning to a project or preparing for a release, I want a clear, honest report of the current documentation health so that I know exactly what is current, what has drifted, and what to fix first.

**Acceptance Criteria**
- Purely read-only — modifies no files.
- Reports whether all expected doc files exist.
- Checks `LAST_REVIEWED` and reports days since last update, plus the number of git commits since then when the project uses git (reports N/A otherwise).
- Detects drift by comparing documented tech stack, integrations, API routes, and database models against what is currently present in the codebase.
- Inventories existing external docs (via `doc-context docs`) and flags when content they carry (e.g. CHANGELOG features, README stack) is not reflected in the standard `docs/` set.
- Counts and lists all unresolved `⚠️` markers across all docs.
- Counts `<!-- AI-generated -->` sections not yet confirmed by a human.
- Assigns an overall health score: 🟢 Good, 🟡 Needs attention, 🔴 Outdated.
- Produces a prioritised recommended-actions list.
- Can be auto-invoked by Claude when it detects docs are absent or the project has no `LAST_REVIEWED` file.

**Dependencies**
None required — works even if `docs/` is absent (reports that as the primary issue).

**Future Enhancements**
- `--fix` flag to auto-run `/docs:update` for the highest-priority drift items.
- CI integration: run as part of a pre-release checklist.

---

### Feature 4 — Plugin & marketplace packaging

**Description**
The suite is distributed as a single Claude Code plugin named `docs`, served from a git-hosted marketplace (`ndollem-docs-tools`) defined by `.claude-plugin/marketplace.json` at the repo root. This uses Claude Code's native plugin system for install, update, versioning, and removal — no custom install script.

**User Story**
As a developer (or a teammate) setting up the suite, I want to install all three skills with the standard plugin commands so that I get native versioning and updates and don't manage files by hand.

**Acceptance Criteria**
- The repo root contains a valid `.claude-plugin/marketplace.json` listing the `docs` plugin with a relative `source` of `./plugins/docs`.
- `plugins/docs/.claude-plugin/plugin.json` declares `name`, `description`, `version`, and `author`.
- Users install with `/plugin marketplace add ndollem/claude-skill-docs` then `/plugin install docs@ndollem-docs-tools`; the skills appear as `/docs:init`, `/docs:update`, `/docs:check`.
- `claude plugin validate ./plugins/docs` passes (runnable in CI before publishing).
- Local development works via `claude --plugin-dir ./plugins/docs` (wrapped by `scripts/dev-install.sh`); `/reload-plugins` picks up edits.
- An explicit `version` is set so teammates only receive updates on a deliberate bump.

**Dependencies**
Claude Code with plugin support; a git host (public or private) for the marketplace repository.

---

### Feature 5 — Standard documentation structure

**Description**
A defined, consistent set of documentation files that every project using doc-skills produces. This is not an interactive feature but a standard that the skills enforce.

**Files in the standard**

| File | Purpose |
|---|---|
| `docs/01-prd.md` | Product requirements — vision, goals, users, features, acceptance criteria |
| `docs/02-erd.md` | Engineering requirements — tech stack, functional/non-functional requirements, integrations |
| `docs/03-architecture.md` | System design — components, request flow, data flow, DB design, API overview |
| `docs/04-coding-standards.md` | Implementation standards — patterns, naming, testing, error handling, git workflow |
| `docs/05-decision-log.md` | Architecture Decision Records (ADRs) |
| `docs/LAST_REVIEWED` | Freshness tracking — when docs were last updated and by which skill |
| `AGENTS.md` | Instructions for AI coding agents — read order, development rules, available skills. Source of truth (cross-tool open standard) |
| `CLAUDE.md` | Thin importer (`@AGENTS.md`) so Claude Code, which reads `CLAUDE.md` not `AGENTS.md`, loads the agent instructions automatically |
| `.ai/project-definition.json` | Canonical machine-readable project definition used to generate and regenerate docs |

---

## Success Metrics

| Metric | Target |
|---|---|
| Time to generate initial docs on an existing codebase | Under 3 minutes |
| Time to update docs after a typical feature | Under 1 minute |
| Unresolved ⚠️ sections after a human review pass | 0 |
| Documentation health score before a release | 🟢 Good |
| Docs drift (items in code not in docs) | 0 critical items |
| Skill file size | All SKILL.md files under 500 lines |

---

## Out of Scope

- **Interactive discovery interviews.** The skills read the codebase passively. They do not ask questions during a structured multi-turn interview session. That is a separate Discovery Agent concept described in the parent framework document.
- **Diagram generation.** The skills generate Markdown text. Mermaid diagrams or architecture visuals are not in scope for v1.
- **CI/CD integration.** Automating `/docs:check` as part of a pipeline is a future enhancement, not a v1 requirement.
- **Google Docs, Notion, or Confluence export.** Output is Markdown files in the repository. External system sync is out of scope.
- **Multi-language skill instructions.** The skill instructions themselves (SKILL.md) are English-only. Generated *documentation* prose can be English or Bahasa Indonesia via `--lang`, but additional output languages and a localized skill UI are out of scope for v1.
- **Automatic git commits.** The skills write files but never run `git commit`. Committing is always a human action.
