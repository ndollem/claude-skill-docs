---
name: check
description: >
  Audit project documentation health. Checks whether docs/ exists and is complete,
  compares docs against the actual codebase to find drift, surfaces gaps and
  sections needing human review. Safe to run anytime — read-only, never writes.
  Use after returning to a project, before a release, or when docs feel stale.
allowed-tools: Read Glob Grep Bash(doc-context *)
---

# check

You are a documentation auditor. Produce an honest, actionable health report on the
project's documentation. This skill is **read-only** — never modify any file.

## Environment scan

```!
doc-context env
```

## Step 1 — Check if docs/ exists

If there is no `docs/` folder (Glob `docs/*.md` returns nothing), report that `docs/`
does not exist, recommend running `/docs:init`, and **stop** — do not continue.

## Step 2 — Inventory existing docs

Compare what is present against what should be present:

Expected: `docs/01-prd.md`, `docs/02-erd.md`, `docs/03-architecture.md`,
`docs/04-coding-standards.md`, `docs/05-decision-log.md`, `docs/LAST_REVIEWED`,
`AGENTS.md`, `.ai/project-definition.json`.

Read `docs/LAST_REVIEWED` if it exists to get the last-review date.

## Step 3 — Read all existing docs

Read every doc file that exists — you need full content to detect gaps and drift.

## Step 4 — Read codebase signals

Use the environment scan above plus these helpers to compare docs against reality:

- `` !`doc-context routes` `` — API routes/endpoints currently in code
- `` !`doc-context models` `` — ORM models, migrations, schema files
- `` !`doc-context integrations` `` — env-var names and third-party SDK hints

Also read `package.json` / `pyproject.toml` / equivalent for the current dependency
list. If the scan reported `GIT=no`, note that freshness-by-commits cannot be measured
and rely on `LAST_REVIEWED` and drift instead.

## Step 5 — Run the audit

Produce PASS / WARN / FAIL for each check with a short reason.

### Completeness

| Check | Result | Notes |
|---|---|---|
| All expected files exist | | |
| PRD has no empty sections | | |
| ERD has tech stack documented | | |
| Architecture has component list | | |
| Coding standards has folder structure | | |
| Decision log has at least one ADR or note | | |
| AGENTS.md has read order defined | | |

### Freshness

| Check | Result | Notes |
|---|---|---|
| LAST_REVIEWED exists | | |
| Last reviewed within 30 days | | |
| Commits since last review (if git) | | |
| Unresolved ⚠️ flags present | | |

### Drift — docs vs code

| Area | Documented | Detected in code | Drift? |
|---|---|---|---|
| Tech stack (frontend) | | | |
| Tech stack (backend) | | | |
| Tech stack (database) | | | |
| Major API routes | | | |
| Database models/entities | | | |
| Third-party integrations | | | |
| Environment variables | | | |

Drift = something in code that is not in docs, or docs describing something no longer
in code.

### Quality

Count and list:
- `⚠️` markers across all docs (unresolved human input)
- `<!-- AI-generated -->` sections not yet confirmed by a human
- Empty or placeholder-only sections

## Step 6 — Produce the health report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 DOCUMENTATION HEALTH REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Overall health: [🟢 Good | 🟡 Needs attention | 🔴 Outdated]

Last reviewed: [date or UNKNOWN]
Commits since last review: [N or N/A — no git]

COMPLETENESS
  ✅ docs/01-prd.md — present
  ❌ docs/05-decision-log.md — missing
  ...

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

1. [Highest priority — e.g. "Run /docs:update auth (12 commits behind)"]
2. [Next — e.g. "Add missing API routes to docs/03-architecture.md"]
3. [Next — e.g. "Resolve 7 ⚠️ sections in PRD and ERD"]

Run `/docs:update [area]` to update specific sections.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Scoring logic

- 🟢 Good: no FAIL, fewer than 3 WARNs, last reviewed within 14 days.
- 🟡 Needs attention: 1–3 FAILs, or 4+ WARNs, or last reviewed 15–60 days ago.
- 🔴 Outdated: 4+ FAILs, or last reviewed 60+ days ago, or drift in core sections.
