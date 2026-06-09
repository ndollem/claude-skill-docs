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
argument-hint: "[optional: brief project description] [--interactive] [--lang en|id|auto] [--yes]"
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

## Step 1 — Refuse to overwrite existing docs

If `docs/` already exists and contains any `.md` files, **STOP immediately** and tell
the user:

> `docs/` already exists. Use `/docs:update` to update existing documentation,
> or manually delete `docs/` if you want to regenerate from scratch.

Do not proceed. (Check via the tree in the scan above, or a quick Glob of `docs/*.md`.)

## Step 2 — Read the codebase

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
- **confidence** — rate the **business layer** and **technical layer** each
  LOW / MEDIUM / HIGH based on how much real evidence you have.

## Step 3.5 — Confirm before writing (safety gate)

This skill **creates files**. Before writing anything, confirm intent — this is what
makes the skill safe to expose in the `/` menu and safe for Claude to invoke.

**Skip this gate only if** the arguments contained `--yes` / `-y`. Otherwise, present
the plan and wait for explicit approval:

- List every file you are about to create (the full set from Step 4, plus
  `docs/LAST_REVIEWED`), noting that `docs/` and `.ai/` will be created if absent.
- State the resolved doc language and mode (passive scan vs. interactive discovery).
- Use the `AskUserQuestion` tool to ask the user to **Proceed** or **Cancel**.

If the user cancels (or does not approve), **STOP** and write nothing. Do not partially
generate files. Only continue to Step 4 once the user has approved (or `--yes` was set).

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
| `.ai/project-definition.json` | `${CLAUDE_SKILL_DIR}/templates/project-definition.json` |

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
Doc-language: [en|id] (resolved from --lang; record the actual language used)
Sections needing human review: see ⚠️ markers in each file
```

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

Files created:
  docs/01-prd.md, docs/02-erd.md, docs/03-architecture.md,
  docs/04-coding-standards.md, docs/05-decision-log.md,
  AGENTS.md, .ai/project-definition.json, docs/LAST_REVIEWED

Confidence:
  Business layer: [LOW/MEDIUM/HIGH] — [reason]
  Technical layer: [LOW/MEDIUM/HIGH] — [reason]

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
