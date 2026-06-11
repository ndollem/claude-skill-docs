---
name: init
description: >
  Bootstrap a full project documentation set from scratch.
  Use when starting a new project, or when an existing project has
  no docs/ folder and no structured documentation yet.
  Creates docs/01-prd.md, docs/02-erd.md, docs/03-architecture.md,
  docs/04-coding-standards.md, docs/05-decision-log.md, AGENTS.md,
  and .ai/project-definition.json by reading the codebase.
  Always previews the file list and asks for confirmation before writing.
argument-hint: "[optional: brief project description] [--scan docs|full] [--interactive] [--lang en|id|auto] [--yes]"
allowed-tools: Read Glob Grep Write AskUserQuestion Bash(doc-context *)
---

# init

You are a documentation engineer bootstrapping a project's standard documentation
set. Read the codebase, infer what you can, and generate the full `docs/` folder.
Be honest about what you inferred vs. what you know for certain — **never fabricate
business goals, user personas, or success metrics.**

## Arguments

Raw arguments: **$ARGUMENTS**

- Any free text (other than the flags below) is a **project description hint** — use it
  to guide generation, especially the PRD's Vision and Problem Statement.
- **`--scan <depth>`** controls how much of the project is read before generating docs.
  Existing human-written documentation (README, PRD, CHANGELOG, etc.) is **always** read
  first regardless of this flag — it only controls whether the **full codebase** is read too:
  - `docs` → read existing docs + manifests + the environment scan only. **Cheapest**
    (lowest token cost); best when the repo already documents itself well.
  - `full` → read existing docs **and** do the full codebase scan (Step 2). **Thorough**
    but higher token cost; best when existing docs are thin or you want code-verified detail.
  - If `--scan` is **omitted**: resolve interactively in Step 1.7 (ask after summarizing the
    existing docs). With **`--yes`** and no `--scan`, default to **`full`**.
- If the arguments contain **`--interactive`**, run the optional discovery interview
  (see Step 6) to fill business sections instead of flagging them.
- If the arguments contain **`--yes`** (or **`-y`**), skip the confirmation gate in
  Step 3.5 and write the files directly. Use this for non-interactive runs.
- **`--lang <code>`** sets the language of the **generated documentation prose**:
  - `en` (default) → write all docs in English.
  - `id` → write all docs in Bahasa Indonesia.
  - `auto` → match the dominant natural language already used in the repo's README and
    code comments; if unclear, fall back to English.
  - The flag controls **prose only**. Always keep template headings, section names,
    `{{DATE}}`, `⚠️ [Needs human input]` markers, `<!-- AI-generated -->` tags, and JSON
    keys in `project-definition.json` exactly as-is in English, so the other skills and
    `/docs:check` can still parse the files. Record the chosen language under
    `documentation_gaps`-adjacent metadata is not needed — instead note it in
    `LAST_REVIEWED` (see Step 5).

## Environment scan

```!
doc-context env
```

The block above gives you today's `DATE`, whether this is a git repo, the commit
count, the project root, which stack/config files exist, and the top-level tree.
Use the `DATE` value wherever a template contains `{{DATE}}`.

## Step 1 — Refuse to regenerate an existing docs set

If `docs/` already exists and contains any `.md` files, **STOP immediately** and tell
the user:

> `docs/` already exists. Use `/docs:update` to update existing documentation,
> or manually delete `docs/` if you want to regenerate from scratch.

Do not proceed. (Check via the tree in the scan above, or a quick Glob of `docs/*.md`.)

This guard only covers `docs/`. The **root-level** outputs (`AGENTS.md`, `CLAUDE.md`,
`.ai/project-definition.json`) can exist independently even when `docs/` does not — a
developer may have hand-written `CLAUDE.md`. Those collisions are handled safely in
Step 3.5; init **never overwrites** them. So it is fine to proceed past this step when
only root files (not `docs/`) already exist.

## Step 1.5 — Read existing documentation first (always)

Before reading any source code, discover and read whatever documentation the repo already
ships. This is the **authoritative human-written reference** — it captures intent that code
alone cannot, and grounds the generated docs at far lower token cost than a full code scan.

Run the helper to list existing docs:

```!
doc-context docs
```

Read each discovered file that looks relevant — typically `README*`, `PRD*`, `CHANGELOG*` /
release notes, `ARCHITECTURE*`, `DESIGN*`, `CONTRIBUTING*`, `ROADMAP*`, ADRs, and any
`docs/*.md`. Treat them as **primary sources**:

- Prefer existing-doc content over anything you would infer from code. Never silently
  contradict a human-written doc; if code clearly diverges, note it as a flag later rather
  than overwriting their intent.
- Build an internal **coverage map**: for each standard section (vision/problem, target
  users, business goals, tech stack, architecture, data model, coding standards, decisions),
  note whether the existing docs already cover it **well**, **partially**, or **not at all**.

If `doc-context docs` reports `(none detected)`, record that there are no existing docs and
carry on — the codebase scan becomes the only source.

## Step 1.7 — Choose scan depth

Decide whether to also read the full codebase (Step 2), based on the `--scan` flag:

- **`--scan docs`** → skip Step 2. Generate from existing docs + `STACK_FILES` manifests +
  the environment scan only. (Cheapest.)
- **`--scan full`** → proceed through Step 2 (full codebase read) in addition to the existing
  docs already read. (Thorough.)
- **`--yes` with no `--scan`** → default to **full**; proceed through Step 2.
- **Neither flag** → use the `AskUserQuestion` tool to let the user choose. Summarize what
  the existing docs already cover (from the Step 1.5 coverage map), then ask:
  - **"Docs-only (cheaper)"** — generate from existing docs + manifests; skip the deep code
    read. Good when existing docs are solid.
  - **"+ Full codebase scan (thorough, higher token cost)"** — also read source to verify and
    fill gaps. Good when existing docs are thin.

  State the trade-off plainly (token cost vs. completeness) and honor the answer. Record the
  resolved depth for Steps 5 and 7.

## Step 2 — Read the codebase (full scan only)

**Only perform this step if Step 1.7 resolved to a full scan.** If the depth is `docs-only`,
skip straight to Step 3. When you do read code here, use it to **corroborate and fill gaps in**
the existing docs from Step 1.5 — not to override human-written intent.

Using the `STACK_FILES` list from the scan, read whichever exist:
- `package.json` / `pyproject.toml` / `requirements.txt` / `go.mod` / `Cargo.toml` /
  `composer.json` / `Gemfile` / `pom.xml` (dependencies, scripts, runtime versions)
- Any existing `README*`
- `.env.example` / `.env.sample` (integrations — names only, never values)
- `Dockerfile` / `docker-compose*` (infrastructure)

For deeper signal, you may also run any of these helpers:

- `` !`doc-context routes` `` — detected API routes/endpoints
- `` !`doc-context models` `` — ORM models, migrations, schema files
- `` !`doc-context integrations` `` — env-var names and third-party SDK hints

Then read the entry points and a representative sample of source files. Do **not**
recurse into `node_modules`, `.git`, `dist`, or `build`.

## Step 3 — Form an internal project definition

Before writing, summarize internally:
- **project_name** — from package manifest, folder name, or git remote
- **detected_stack** — languages, frameworks, databases from config files
- **entry_points**, **detected_patterns**, **integrations**
- **provenance** — for each major finding, track whether it came from an **existing doc**
  (Step 1.5), was **inferred from code** (Step 2), or is **unknown**. Prefer existing-doc
  content; use code only to corroborate or fill gaps.
- **confidence** — rate the **business layer** and **technical layer** each
  LOW / MEDIUM / HIGH based on how much real evidence you have. Existing docs raise the
  business-layer confidence; a docs-only scan typically lowers the technical-layer confidence.

## Step 3.5 — Detect collisions and confirm before writing (safety gate)

This skill **creates files**. Before writing anything, confirm intent **and guarantee no
existing file is overwritten** — this is what makes the skill safe to expose in the `/`
menu and safe for Claude to invoke.

### Classify every target

Build the full target list: every `docs/*` file, `docs/LAST_REVIEWED`, `AGENTS.md`,
`CLAUDE.md`, and `.ai/project-definition.json`. Check which already exist (Glob / Read),
and sort each into one of three buckets:

- **CREATE** — does not exist yet → will be written.
- **SKIP** — already exists → **preserved, never overwritten**. Applies to `AGENTS.md`,
  any stray `docs/*`, and `.ai/project-definition.json`.
- **MERGE** — `CLAUDE.md` only, and only if it already exists. Read it:
  - If it already imports AGENTS (`@AGENTS.md` appears anywhere) → treat as **SKIP**,
    leave it untouched.
  - If it exists but lacks the import → the only change offered is to **append**
    `@AGENTS.md` plus the short "Working in this repo with Claude Code" pointer to the
    **end** of the file, preserving all existing content. This is an `Edit` (append),
    never a `Write` (replace).

### Confirm

**Skip the prompt only if** the arguments contained `--yes` / `-y`. Otherwise present the
plan and wait for explicit approval:

- Show all three buckets — **Created**, **Skipped (already exists — preserved)**, and
  **Merged (CLAUDE.md append)** — so the user sees exactly what will and won't change.
- State the resolved doc language and mode (passive scan vs. interactive discovery).
- Use the `AskUserQuestion` tool to ask the user to **Proceed** or **Cancel**.

If the user cancels (or does not approve), **STOP** and write nothing.

### `--yes` does not bypass preservation

`--yes` skips the **prompt**, not the safety. Even with `--yes`: create missing files,
skip existing ones, and append-merge `CLAUDE.md` only when it lacks the import. **Never
overwrite an existing file under any flag.** This makes init idempotent and safe to
re-run on a populated repo.

Only continue to Step 4 once the user has approved (or `--yes` was set).

## Step 4 — Create the structure and write each document

Create `docs/` and `.ai/` if absent. For each output, **read the matching template,
fill it in from your findings, and Write the result.** Replace `{{DATE}}` with the
scanned `DATE`. Templates live in this skill's directory:

| Output file | Template to read |
|---|---|
| `docs/01-prd.md` | `${CLAUDE_SKILL_DIR}/templates/01-prd.md` |
| `docs/02-erd.md` | `${CLAUDE_SKILL_DIR}/templates/02-erd.md` |
| `docs/03-architecture.md` | `${CLAUDE_SKILL_DIR}/templates/03-architecture.md` |
| `docs/04-coding-standards.md` | `${CLAUDE_SKILL_DIR}/templates/04-coding-standards.md` |
| `docs/05-decision-log.md` | `${CLAUDE_SKILL_DIR}/templates/05-decision-log.md` |
| `AGENTS.md` | `${CLAUDE_SKILL_DIR}/templates/AGENTS.md` |
| `CLAUDE.md` | `${CLAUDE_SKILL_DIR}/templates/CLAUDE.md` |
| `.ai/project-definition.json` | `${CLAUDE_SKILL_DIR}/templates/project-definition.json` |

**`AGENTS.md` vs `CLAUDE.md`:** `AGENTS.md` is the single source of truth for agent
instructions (the cross-tool open standard). Claude Code reads `CLAUDE.md`, not
`AGENTS.md`, so `CLAUDE.md` exists only to import it (`@AGENTS.md`). Copy the `CLAUDE.md`
template **verbatim** — it has no `{{DATE}}` or placeholders to fill.

**Honor the Step 3.5 classification — never overwrite:**
- Only **Write** a target that was classified **CREATE** (did not already exist).
- For every **SKIP** target, do nothing — leave the existing file exactly as-is.
- For a **MERGE** `CLAUDE.md`, **Edit** (append) the `@AGENTS.md` import + pointer to the
  end; never replace the file.

**Rules while filling templates:**
- Replace each bracketed `[instruction]` placeholder with real, inferred content.
- For any section you cannot determine from the codebase, leave the line
  `> ⚠️ [Needs human input] — could not be inferred from codebase.` Do not invent it.
- In `project-definition.json`, use `null` / empty arrays for unknowns — never fabricate.
- Keep all template structure and headings intact.

## Step 5 — Write the freshness marker

Write `docs/LAST_REVIEWED`:

```
Generated by /docs:init
Date: {{DATE}}
Mode: bootstrap (full generation from codebase scan)
Scan-depth: [docs-only | full] (resolved from --scan / the Step 1.7 choice)
Existing-docs-referenced: [comma-separated list of files read in Step 1.5, or none]
Doc-language: [en|id] (resolved from --lang; record the actual language used)
Sections needing human review: see ⚠️ markers in each file
```

The `Scan-depth` and `Existing-docs-referenced` lines let `/docs:update` and `/docs:check`
know how the docs were sourced.

The `Doc-language` line is how `/docs:update` and `/docs:check` know which language the
docs are written in. Always record the resolved language (resolve `auto` to `en` or
`id`).

## Step 6 — Optional discovery interview (only if `--interactive`)

If and only if the arguments contained `--interactive`, before finalizing the PRD use
the `AskUserQuestion` tool to fill the sections you would otherwise flag. Ask about:
- **Vision** — the one-sentence purpose of the project
- **Target Users** — who uses it and in what role
- **Business Goals** — what success looks like for the business
- **Out of Scope** — what this project deliberately does not do

Write the user's answers into `docs/01-prd.md` (and mirror into
`project-definition.json`) **instead of** the `⚠️` markers. Without the flag, skip this
step entirely and leave the markers in place.

## Step 7 — Print a summary

```
✅ /docs:init complete

Created:
  [the files actually written — from docs/01-prd.md … docs/05-decision-log.md,
   AGENTS.md, CLAUDE.md, .ai/project-definition.json, docs/LAST_REVIEWED]

Skipped (already existed — preserved):
  [any targets that already existed, or "none"]

Merged:
  [CLAUDE.md — appended @AGENTS.md import, if applicable; otherwise "none"]

Confidence:
  Business layer: [LOW/MEDIUM/HIGH] — [reason]
  Technical layer: [LOW/MEDIUM/HIGH] — [reason]

Scan depth: [docs-only | full]
Existing docs used: [list of files read as references, or "none found"]
Mode: [passive scan | interactive discovery]
Doc language: [English | Bahasa Indonesia]

Sections requiring human input:
  [list each ⚠️ section across all files, or "none — filled via interview"]

Next steps:
  1. Review each ⚠️ section and fill in business context
  2. Run /docs:check to validate documentation health
  3. Commit docs/ to version control
  4. Run /docs:update [module] after each future feature
```
