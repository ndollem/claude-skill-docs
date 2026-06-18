# docs — Claude Code documentation plugin

[![validate](https://github.com/ndollem/claude-skill-docs/actions/workflows/validate.yml/badge.svg)](https://github.com/ndollem/claude-skill-docs/actions/workflows/validate.yml)
[![version](https://img.shields.io/badge/version-1.4.0-blue)](plugins/docs/.claude-plugin/plugin.json)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

A [Claude Code](https://claude.com/claude-code) **plugin** that makes project documentation a first-class, low-friction part of development. Instead of writing docs by hand and watching them decay, you get four commands that **generate docs from the codebase, keep them in sync as code evolves, audit them for drift, and record what changed in each branch**:

| Command | What it does | Writes files? |
|---|---|---|
| [`/docs:init`](#1-docsinit--bootstrap-documentation) | Bootstrap a full `docs/` set — reads existing docs first, then optionally scans the codebase | ✏️ Yes (confirm-gated) |
| [`/docs:update [area]`](#2-docsupdate--sync-docs-after-a-change) | Surgically update the sections affected by a feature or refactor | ✏️ Yes (confirm-gated) |
| [`/docs:check`](#3-docscheck--audit-documentation-health) | Audit doc health: completeness, freshness, drift vs. code | 🔒 Read-only |
| [`/docs:changelog [name]`](#4-docschangelog--record-what-changed-in-a-branch) | Draft Keep a Changelog notes from the branch diff vs. main, trace ticket numbers | ✏️ Yes (confirm-gated) |

This repository is also a **plugin marketplace** (`ndollem-docs-tools`), so the plugin installs and updates through Claude Code's native plugin system — no install script.

---

## Table of contents

- [Why this plugin](#why-this-plugin)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Usage guide](#usage-guide)
  - [1. `/docs:init` — bootstrap documentation](#1-docsinit--bootstrap-documentation)
  - [2. `/docs:update` — sync docs after a change](#2-docsupdate--sync-docs-after-a-change)
  - [3. `/docs:check` — audit documentation health](#3-docscheck--audit-documentation-health)
  - [4. `/docs:changelog` — record what changed in a branch](#4-docschangelog--record-what-changed-in-a-branch)
- [Command & flag reference](#command--flag-reference)
- [Recommended workflow](#recommended-workflow)
- [What gets generated](#what-gets-generated)
- [Design principles](#design-principles)
- [Updating the plugin](#updating-the-plugin)
- [Local development](#local-development)
- [Troubleshooting / FAQ](#troubleshooting--faq)
- [Repository layout](#repository-layout)
- [Contributing](#contributing)
- [License](#license)

---

## Why this plugin

Most teams have the same documentation problems:

- **No docs at all** — the project grew faster than anyone wrote things down.
- **Stale docs** — a `docs/` folder exists, but it describes the system as it was six months ago.
- **AI agents flying blind** — Claude Code (and other coding agents) work far better when the project ships an `AGENTS.md` / `CLAUDE.md` with real context, but nobody maintains one.

This plugin attacks all three: `init` retrofits a complete documentation set onto any codebase in minutes, `update` keeps it honest after every feature, and `check` tells you when it has drifted. Crucially, it **never fabricates business facts** — anything it cannot infer from code is flagged `⚠️ [Needs human input]` for you to fill in.

## Requirements

- **Claude Code** CLI, desktop app, or IDE extension (any recent version with plugin support).
- A POSIX shell (`sh`) for the bundled `doc-context` scanner — available out of the box on macOS, Linux, and WSL.
- **Git is optional.** The scanner detects non-git projects and degrades gracefully; every command works in a plain folder.

## Installation

Add the marketplace from GitHub, then install the plugin — two commands, run inside any Claude Code session:

```
/plugin marketplace add ndollem/claude-skill-docs
/plugin install docs@ndollem-docs-tools
```

Verify the install:

1. Run `/plugin` → **Installed** tab → you should see `docs@ndollem-docs-tools 1.4.0`.
2. Type `/docs` in the prompt — autocomplete should offer `/docs:init`, `/docs:update`, `/docs:check`, and `/docs:changelog`.

> Prefer to try it without installing? See [Local development](#local-development).

## Quick start

The 60-second version, on a project that has no docs yet:

```
# 1. Generate the full documentation set (you'll get a preview + confirm prompt)
/docs:init

# 2. Open the generated docs and fill in every ⚠️ [Needs human input] section

# 3. Commit docs/, AGENTS.md, CLAUDE.md and .ai/ so the whole team benefits

# 4. From now on, after each feature:
/docs:update <area-that-changed>

# 5. Anytime you're unsure whether docs still match the code:
/docs:check
```

---

## Usage guide

### 1. `/docs:init` — bootstrap documentation

Use this **once per project**: on a brand-new repo, or to retrofit documentation onto an existing codebase.

**Step by step, what happens when you run it:**

1. **Environment scan** — detects today's date, git status, project root, stack/config files, and the top-level tree (via the bundled `doc-context` scanner).
2. **Guard check** — if `docs/` already contains `.md` files, it stops and points you to `/docs:update` instead. Re-running init can never clobber an existing docs set.
3. **Existing-docs read** — discovers and reads whatever documentation the repo already ships (README, PRD, CHANGELOG, release notes, ARCHITECTURE, CONTRIBUTING, ROADMAP, ADRs, `docs/*.md`) and uses it as the **authoritative reference** before touching any source. This grounds the output in human-written intent at low token cost.
4. **Scan-depth choice** — decides whether to also read the full codebase. With `--scan docs` it stays docs-only (cheapest); with `--scan full` it also scans source (thorough); with neither flag it asks you, summarizing what the existing docs already cover so you can weigh token cost vs. completeness. `--yes` defaults to full.
5. **Codebase read** (full scan only) — reads your package manifest, `.env.example` (names only, never values), Dockerfiles, routes, models, and a representative sample of source, to corroborate and fill gaps in the existing docs.
6. **Preview + confirmation gate** — before writing anything, it shows exactly which files will be **Created**, which existing files will be **Skipped (preserved)**, and whether `CLAUDE.md` will be **Merged** (append-only). You approve or cancel.
7. **Generation** — fills the eight bundled templates with what it actually found.
Anything it cannot infer is marked `⚠️ [Needs human input]` — it never invents business goals, personas, or metrics.
8. **Summary** — prints what was created, a confidence rating, and your next steps.

**Basic usage:**

```
/docs:init
```

**With a project description hint** (improves the PRD's Vision / Problem Statement):

```
/docs:init SaaS app for managing restaurant reservations
```

**Scan depth** — control how much is read before generating. Existing docs are always read first; this only governs whether the full codebase is read too. `docs` is cheapest (existing docs + manifests); `full` is thorough (also scans source). Omit the flag to be asked interactively:

```
/docs:init --scan docs     # cheap, grounded in existing docs
/docs:init --scan full     # thorough, code-verified (higher token cost)
```

**Interview mode** — instead of leaving `⚠️` markers, it asks you about Vision, Target Users, Business Goals, and Out of Scope, and writes your answers into the PRD:

```
/docs:init "restaurant reservations SaaS" --interactive
```

**Doc language** — `en` (default), `id` (Bahasa Indonesia), or `auto` (match the repo).
Only the prose changes; headings, flags, and JSON keys stay in English so the other skills can still parse the files:

```
/docs:init --lang id
```

**Non-interactive / CI runs** — `--yes` skips the confirmation prompt (but still never overwrites existing files):

```
/docs:init --yes
```

<details>
<summary><strong>Example: expected output</strong></summary>

```
✅ /docs:init complete

Created:
  docs/01-prd.md
  docs/02-erd.md
  docs/03-architecture.md
  docs/04-coding-standards.md
  docs/05-decision-log.md
  docs/LAST_REVIEWED
  AGENTS.md
  .ai/project-definition.json

Skipped (already existed — preserved):
  none

Merged:
  CLAUDE.md — appended @AGENTS.md import

Confidence:
  Business layer: LOW — no PRD or business docs found; goals flagged for human input
  Technical layer: HIGH — stack, routes, and models inferred from package.json and src/

Scan depth: full
Existing docs used: README.md
Mode: passive scan
Doc language: English

Sections requiring human input:
  docs/01-prd.md → Vision, Business Goals, Target Users
  docs/02-erd.md → Non-functional requirements

Next steps:
  1. Review each ⚠️ section and fill in business context
  2. Run /docs:check to validate documentation health
  3. Commit docs/ to version control
  4. Run /docs:update [module] after each future feature
```

</details>

#### About `AGENTS.md` vs `CLAUDE.md`

`AGENTS.md` is the **single source of truth** for agent instructions (the cross-tool open standard, readable by any AI coding agent). Claude Code, however, reads `CLAUDE.md` — so init also generates a thin `CLAUDE.md` whose only job is to import it via `@AGENTS.md`. That import is what makes your agent instructions load automatically at session start. Edit `AGENTS.md`; never duplicate content into `CLAUDE.md`.

If your repo already has a hand-written `CLAUDE.md`, init **preserves it** and only appends the `@AGENTS.md` import if it's missing.

### 2. `/docs:update` — sync docs after a change

Run this **after shipping a feature, refactoring a module, changing the stack, or adding an integration**. Pass the area that changed:

```
/docs:update auth-module
/docs:update payment-integration
/docs:update database-schema
/docs:update "switched the queue from Redis to SQS" --yes
```

**Step by step, what happens when you run it:**

1. Checks `docs/` exists — if not, it stops and tells you to run `/docs:init` first.
2. Reads every existing doc **and** the recent git diff (or, in non-git projects, the source files relevant to the area you named).
3. Decides which documents the change logically affects — for example, a new API route touches `03-architecture.md`; a new library decision gets an ADR appended to `05-decision-log.md`. Unaffected docs are left alone.
4. **Preview + confirmation gate** — lists each file and section it intends to change before touching anything. You approve or cancel (`--yes` skips the prompt).
5. Applies **surgical edits only** — never whole-file rewrites. Human-written prose is preserved verbatim; new content is tagged `<!-- AI-generated -->` so you know what to review. If it suspects a *business* decision changed, it flags it `⚠️ [Needs human confirmation]` instead of editing it.
6. Refreshes `docs/LAST_REVIEWED` and prints a change summary.

<details>
<summary><strong>Example: expected output</strong></summary>

```
✅ /docs:update complete

Area updated: payment-integration

Changes made:
  docs/03-architecture.md → "External integrations" section (Edit)
  docs/02-erd.md → "Third-party services" table (Edit)
  docs/05-decision-log.md → ADR-004 "Adopt Stripe for payments" (Edit, appended)
  docs/LAST_REVIEWED → refreshed (Write)

Sections flagged for human review:
  docs/01-prd.md → pricing model may have changed (⚠️ flag added, not edited)

Sections NOT updated (and why):
  docs/04-coding-standards.md — no new patterns introduced

Suggested next step:
  Run /docs:check to validate overall documentation health.
```

</details>

### 3. `/docs:check` — audit documentation health

Run this **anytime** — after returning to a project, before a release, or whenever the docs feel stale. It is strictly **read-only**: it never writes or modifies a file, so it is also safe for Claude to invoke on its own when it notices missing or stale docs.

```
/docs:check
```

It audits four dimensions and scores each check PASS / WARN / FAIL:

- **Completeness** — are all expected files present, with no empty sections?
- **Freshness** — when was the last review, and how many commits have landed since?
- **Drift** — does the documented stack / routes / models / integrations still match what's actually in the code?
- **Quality** — unresolved `⚠️` flags and unconfirmed `<!-- AI-generated -->` sections.

<details>
<summary><strong>Example: expected output</strong></summary>

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 DOCUMENTATION HEALTH REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Overall health: 🟡 Needs attention

Last reviewed: 2026-05-18
Commits since last review: 12

COMPLETENESS
  ✅ docs/01-prd.md — present
  ✅ docs/03-architecture.md — present
  ❌ docs/05-decision-log.md — missing

FRESHNESS
  ✅ Reviewed within 30 days
  ⚠️  12 commits since last review — run /docs:update for recent changes

DRIFT (docs vs code)
  ✅ Tech stack matches
  ⚠️  3 routes in code not documented in architecture
  ❌ docs mention Redis but no Redis dependency detected in code

QUALITY
  ⚠️  7 unresolved ⚠️ sections still require human input
  ℹ️  3 AI-generated sections not yet confirmed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RECOMMENDED ACTIONS (priority order)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Run /docs:update auth (12 commits behind)
2. Add missing API routes to docs/03-architecture.md
3. Resolve 7 ⚠️ sections in PRD and ERD

Run `/docs:update [area]` to update specific sections.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Health scoring: 🟢 Good (no FAILs, reviewed within 14 days) · 🟡 Needs attention
(1–3 FAILs or reviewed 15–60 days ago) · 🔴 Outdated (4+ FAILs, 60+ days, or core drift).

</details>

### 4. `/docs:changelog` — record what changed in a branch

Run this **after finishing work on a feature branch**, before merging. It compares the current branch against `main` (or `master`), drafts standard [Keep a Changelog](https://keepachangelog.com/) notes from the diff, traces the ticket numbers behind the work, and saves a dated entry under `docs/changelog/YYYY/MM/DD/`:

```
/docs:changelog auth-migration
/docs:changelog "payment webhooks" --yes
```

Pass the feature, module, or task name as the argument — it becomes the file name (slugified to kebab-case). If you omit it, the skill asks for it.

**Step by step, what happens when you run it:**

1. Checks `docs/` exists — if not, it stops and tells you to run `/docs:init` first. It also needs git history with a base branch to diff against.
2. Reads the branch diff against `main`/`master` (via the `doc-context changelog-diff` scanner): the changed files, the commit subjects, and the author.
3. **Traces tickets** — scans the branch name and every commit subject for tracker keys (`PROJ-123`, `JIRA-456`) and GitHub issue numbers (`#123`), collecting **all** unique references. A branch carrying work for several tickets lists all of them. Unless you pass `--yes`, it asks you to confirm, edit, or add tickets.
4. Drafts the entry — classifies changes into **Added / Changed / Fixed / Removed / Security**, appends the relevant ticket key to each bullet for traceability (e.g. `- Add refresh-token rotation [PROJ-123]`), and writes a short overview. Empty sections are dropped.
5. **Preview + confirmation gate** — shows the full drafted Markdown and the destination path before writing. You approve or cancel (`--yes` skips the prompt).
6. Writes `docs/changelog/YYYY/MM/DD/[name].md` and refreshes `docs/LAST_REVIEWED`.

<details>
<summary><strong>Example: expected output</strong></summary>

```
✅ /docs:changelog complete

Entry written: docs/changelog/2026/06/18/auth-migration.md
Branch:        feat/auth-migration (vs main)
Tickets traced: PROJ-123, PROJ-130

Sections included:
  Added, Changed, Security

Suggested next step:
  Review the <!-- AI-generated --> entry, then commit docs/changelog/.
```

</details>

The entries are dated and ticket-tagged, so `docs/changelog/` becomes a browsable, traceable history of what shipped — each note links back to the task tracker. Like the other writers, the generated content is tagged `<!-- AI-generated -->` for review, and nothing is written without your confirmation (unless you pass `--yes`).

---

## Command & flag reference

| Command | Arguments & flags | Notes |
|---|---|---|
| `/docs:init` | `[description hint]` | Free text guides the PRD's Vision / Problem Statement |
| | `--scan docs\|full` | Read depth: `docs` = existing docs + manifests only (cheapest); `full` = also scan source (thorough). Omit to be asked; `--yes` defaults to `full` |
| | `--interactive` | Interview you to fill business sections instead of `⚠️` markers |
| | `--lang en\|id\|auto` | Language of generated prose (default `en`); structure stays English |
| | `--yes`, `-y` | Skip the confirmation prompt (never bypasses overwrite protection) |
| `/docs:update` | `<area>` (required) | Module, feature, or change to sync — e.g. `auth-module` |
| | `--yes`, `-y` | Skip the confirmation prompt |
| `/docs:check` | *(none)* | Read-only; takes no flags |
| `/docs:changelog` | `[name]` | Feature/module/task name → the entry's file name; asked for if omitted |
| | `--yes`, `-y` | Skip the ticket-confirmation and write-confirmation prompts |

## Recommended workflow

```
┌─────────────────────────────────────────────────────────────┐
│  Once per project                                           │
│    /docs:init  →  fill ⚠️ sections  →  commit docs/         │
├─────────────────────────────────────────────────────────────┤
│  Every feature / refactor                                   │
│    ship code  →  /docs:update <area>  →  review             │
│    <!-- AI-generated --> tags  →  commit                    │
├─────────────────────────────────────────────────────────────┤
│  Before merging a feature branch                            │
│    /docs:changelog <name>  →  review  →  commit             │
│    docs/changelog/YYYY/MM/DD/<name>.md                      │
├─────────────────────────────────────────────────────────────┤
│  Periodically (weekly, before releases, after time away)    │
│    /docs:check  →  follow the prioritized action list       │
└─────────────────────────────────────────────────────────────┘
```

Two habits that make this work well in a team:

- **Commit the generated docs** (`docs/`, `AGENTS.md`, `CLAUDE.md`, `.ai/`) to version control. They're for humans *and* for every AI agent that touches the repo.
- **Review the tags.** Anything the plugin wrote is marked `<!-- AI-generated -->`; anything it couldn't know is marked `⚠️`. Treat those like review comments.

## What gets generated

```
docs/
  01-prd.md               Product requirements (vision, users, features, scope)
  02-erd.md               Engineering requirements / tech stack
  03-architecture.md      System design, components, data flow, API surface
  04-coding-standards.md  Detected patterns, folder structure, conventions
  05-decision-log.md      Architecture Decision Records (ADRs)
  changelog/YYYY/MM/DD/   Dated Keep a Changelog entries from /docs:changelog
  LAST_REVIEWED           Freshness marker used by /docs:check
AGENTS.md                 Agent instructions — single source of truth (open standard)
CLAUDE.md                 Thin importer: @AGENTS.md (what Claude Code actually loads)
.ai/project-definition.json   Machine-readable project definition
```

## Design principles

- **Never overwrite.** Existing files are always preserved — init creates what's missing, skips what exists, and at most *appends* the `@AGENTS.md` import to a pre-existing `CLAUDE.md`. Re-running `/docs:init` is safe and idempotent, even with `--yes`.
- **Existing docs first.** `/docs:init` reads whatever documentation the repo already ships (README, CHANGELOG, ARCHITECTURE, ADRs, …) as the authoritative reference before scanning code, then lets you decide via `--scan` whether a full codebase read is worth the extra token cost. `/docs:update` and `/docs:check` consult these external docs too.
- **Never fabricate.** Business goals, personas, and metrics are flagged for human input, not invented. In `project-definition.json`, unknowns are `null`, never guesses.
- **Surgical updates.** `/docs:update` edits only affected sections and tags additions `<!-- AI-generated -->`; human prose is preserved verbatim.
- **Confirm before writing.** The file-writing commands preview their exact plan and ask for approval first (skippable with `--yes`). `/docs:check` is read-only by design.
- **Portable.** All environment scanning runs through `plugins/docs/bin/doc-context` (POSIX sh), which detects git vs. non-git and degrades gracefully — no raw `git` command ever errors out in a plain folder.
- **No surprise commits.** The skills write files but never run `git commit` — committing is always a human action.

> **Why a confirmation gate instead of `disable-model-invocation`?** An earlier version
> set that flag on `init`/`update`. It blocked auto-invocation, but Claude Code also
> dropped the commands from the `/` autocomplete menu, and plugin-skill visibility
> can't be restored from user settings (`skillOverrides` doesn't apply to plugin
> skills). Moving the safety into an explicit confirm-before-write step keeps the
> commands visible **and** safe.

## Updating the plugin

When a new version is published, refresh the marketplace catalog so Claude Code sees the new version:

```
/plugin marketplace update ndollem-docs-tools
```

Then upgrade the installed copy (third-party marketplaces do **not** auto-update by default):

- **Enable auto-update (recommended, one-time):** `/plugin` → **Marketplaces** tab →
  select `ndollem-docs-tools` → **Enable auto-update**. From then on, Claude Code refreshes the catalog and updates the plugin at startup, prompting you to run `/reload-plugins`.
- **Manual:** reinstall to pull the new version:
  ```
  /plugin uninstall docs@ndollem-docs-tools
  /plugin install docs@ndollem-docs-tools
  ```

Either way, **start a new session** (or run `/reload-plugins`) so the refreshed skills load, then confirm the version via `/plugin` → **Installed** tab.

## Local development

Try the plugin straight from a clone, without installing from the marketplace:

```bash
./scripts/dev-install.sh
# or directly:
claude --plugin-dir ./plugins/docs
```

Inside the session, `/help` lists `/docs:init`, `/docs:update`, `/docs:check`. After editing any `SKILL.md` or template, run `/reload-plugins` to pick up the change.

## Troubleshooting / FAQ

**`/docs:init` says `docs/` already exists and stops.**
That's the regeneration guard. Use `/docs:update <area>` to evolve existing docs, or delete `docs/` yourself if you genuinely want to start over. (Root files like a hand-written `CLAUDE.md` don't trigger the guard — they're simply preserved.)

**The `/docs:` commands don't show up after installing.**
Start a new session or run `/reload-plugins`. If they're still missing, clear the plugin cache and reinstall:

```bash
rm -rf ~/.claude/plugins/cache
```

**I updated, but the skills behave like the old version.**
Run `/plugin marketplace update ndollem-docs-tools`, then reinstall and start a new session. Confirm the version in `/plugin` → **Installed**.

**Does it work without git?**
Yes. The `doc-context` scanner reports `NO_GIT` and the skills fall back to reading source files directly instead of diffing history.

**Will it ever overwrite my hand-written `CLAUDE.md` / `AGENTS.md` / docs?**
No. Existing files are never overwritten under any flag, including `--yes`. The single exception is an *append*: a pre-existing `CLAUDE.md` that lacks the `@AGENTS.md` import gets the import added at the end, with all existing content preserved.

**Can Claude run these commands on its own?**
`/docs:check` yes (it's read-only). `/docs:init` and `/docs:update` can be suggested or started by Claude, but they always stop at the confirmation prompt before writing — nothing changes on disk without your approval (unless you passed `--yes`).

**Why are some generated sections in English when I used `--lang id`?**
By design: `--lang` controls prose only. Headings, `⚠️` markers,
`<!-- AI-generated -->` tags, and JSON keys stay in English so `/docs:update` and `/docs:check` can keep parsing the files.

## Repository layout

```
.claude-plugin/marketplace.json    # marketplace catalog (ndollem-docs-tools)
plugins/docs/
  .claude-plugin/plugin.json       # plugin manifest (name, version)
  bin/doc-context                  # shared, git-aware environment scanner (POSIX sh)
  skills/init/SKILL.md             # /docs:init
  skills/init/templates/           # the 8 doc templates
  skills/update/SKILL.md           # /docs:update
  skills/check/SKILL.md            # /docs:check
  skills/changelog/SKILL.md        # /docs:changelog
  skills/changelog/templates/      # the changelog entry template
  README.md                        # plugin-level readme
scripts/dev-install.sh             # local --plugin-dir launcher
.github/workflows/validate.yml     # CI: validates plugin + marketplace manifests
PRD.md                             # product requirements for this plugin
```

## Contributing

Issues and pull requests are welcome at
[ndollem/claude-skill-docs](https://github.com/ndollem/claude-skill-docs). A few ground rules for changes:

- **Version bumps are mandatory.** Claude Code only detects an update when the `version` field is bumped in **both** `.claude-plugin/marketplace.json` and `plugins/docs/.claude-plugin/plugin.json`. Every behavior change must bump both, or existing users will never receive it. The current version is **1.4.0**.
- Test changes locally with `claude --plugin-dir ./plugins/docs` before opening a PR.
- CI validates the plugin and marketplace manifests on every push.

## License

MIT © Agus Salim (ndollem). See [LICENSE](LICENSE).
