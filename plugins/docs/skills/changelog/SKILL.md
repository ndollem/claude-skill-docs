---
name: changelog
description: >
  Create a changelog notes entry based on the updated code of the repo.
  Use after finishing work on a feature branch to record what changed.
  Compares the current branch against main (or master), traces ticket
  numbers from the branch name and commit messages, drafts standard
  Keep a Changelog notes, and saves them to
  'docs/changelog/YYYY/MM/DD/[feature/module/task name].md'.
  Previews the entry and asks for confirmation before writing; pass --yes to skip.
argument-hint: "[feature, module, or task name] [--yes]"
allowed-tools: Read Glob Grep Edit Write AskUserQuestion Bash(doc-context *)
---

# changelog

You are a documentation engineer compiling a changelog notes entry from the code
changes on the current branch. Your job: analyze the branch diff, trace the ticket
numbers behind the work, and draft accurate, standard
[Keep a Changelog](https://keepachangelog.com/) notes — then save them under a
date-partitioned path so the history is browsable and traceable.

## Focus area / name

**$ARGUMENTS**

If the arguments contain **`--yes`** (or **`-y`**), skip the confirmation gates in
Step 2 and Step 4 and write directly; treat the remaining text as the feature name.

## Environment scan

```!
doc-context env
```

The block above gives you today's `DATE` (use it for the `YYYY/MM/DD` path and the
`{{DATE}}` placeholder) and whether `docs/` already exists.

## Branch changes

```!
doc-context changelog-diff
```

This block reports the `BASE_BRANCH` compared against, the `CURRENT_BRANCH`, the
`AUTHOR`, the `RECENT_COMMITS` on this branch (your source for ticket numbers), and
the `DIFF_STAT` / `DIFF_DETAILS` (your source for the actual changes).

## Step 1 — Check docs exist

If there is no `docs/` folder (the env tree shows none, or Glob `docs/*.md` returns
nothing), **stop** and tell the user to run `/docs:init` first. Do not proceed.

If `doc-context changelog-diff` reported **`NO_GIT`** or **`NO_COMMITS`**, there is no
branch history to diff. Tell the user this skill needs git history to compare against a
base branch, and stop.

## Step 2 — Resolve the name and trace tickets

**Feature/module/task name:**
- Strip any `--yes` / `-y` flag from `$ARGUMENTS`; the remainder is the name.
- If the name is empty, use `AskUserQuestion` to ask: *"What is the name of this
  feature, module, or task? (e.g. auth-migration)"*.
- Slugify the final name to lowercase kebab-case (e.g. `Auth Migration` →
  `auth-migration`). This slug is both the `{{NAME}}` value and the file name.

**Ticket / task tracing:**
- Scan the `CURRENT_BRANCH` name and every line of `RECENT_COMMITS` for ticket
  references. Match two patterns:
  - Tracker issue keys — uppercase letters, a hyphen, then digits (e.g. `PROJ-123`,
    `JIRA-456`, `OPS-7`).
  - GitHub-style issue numbers — `#` then digits (e.g. `#123`).
- Collect **all unique** matches across the branch name and every commit — a branch
  may carry work for more than one ticket, and all of them must appear in the entry.
- If **`--yes` was not passed**, use `AskUserQuestion` to confirm:
  - If tickets were found, present them and let the user confirm, edit, or add more
    (comma-separated).
  - If none were found, ask whether they want to enter ticket numbers (they may leave
    it blank).
- If **`--yes` was passed**, use the auto-detected tickets as-is; if none were found,
  use `N/A`.

## Step 3 — Analyze the diff and synthesize notes

1. Read the template at `${CLAUDE_SKILL_DIR}/templates/changelog.md`.
2. From `DIFF_STAT` and `DIFF_DETAILS`, classify the real changes into the Keep a
   Changelog sections: **Added**, **Changed**, **Fixed**, **Removed**, **Security**.
   - Write concise, factual bullets describing what changed in the code. Do **not**
     invent business value — describe functional behavior only.
   - **Drop any section that has no changes** — do not leave placeholder bullets.
3. **Traceability:** append the relevant ticket key(s) in brackets to each bullet they
   correspond to, e.g. `- Add JWT refresh-token rotation [PROJ-123]`. If a change maps
   to several tickets, list all of them: `[PROJ-123, PROJ-130]`.
4. Write a 2-3 sentence high-level summary into the `## Overview` section.
5. Fill the template placeholders:
   - `{{NAME}}` → the kebab-case slug.
   - `{{DATE}}` → the scanned `DATE` (`YYYY-MM-DD`).
   - `{{AUTHOR}}` → the `AUTHOR` from the diff block.
   - `{{BRANCH}}` → the `CURRENT_BRANCH`.
   - `{{TICKETS}}` → the comma-separated confirmed tickets, or `N/A`.
   - Keep the `<!-- AI-generated -->` tag so humans know to review it.

## Step 4 — Preview and confirm (safety gate)

1. Build the destination path from today's `DATE`:
   `docs/changelog/YYYY/MM/DD/[slug].md`.
2. Preview the full drafted Markdown to the user, and state the destination path.
3. **Skip this gate only if `--yes` / `-y` was passed.** Otherwise use
   `AskUserQuestion` to ask the user to **Proceed** or **Cancel**. If they cancel (or
   do not approve), **STOP** and write nothing.

## Step 5 — Write the entry and update the freshness marker

1. Write the drafted content to `docs/changelog/YYYY/MM/DD/[slug].md`. The `Write` tool
   creates the `YYYY/MM/DD` parent directories automatically.
2. If `docs/LAST_REVIEWED` exists, update it (or create it if missing) with:

   ```
   Last changelog by /docs:changelog
   Date: {{DATE}}
   Entry: docs/changelog/YYYY/MM/DD/[slug].md
   Tickets: [comma-separated tickets, or N/A]
   ```

   Preserve any existing `Doc-language:` line if one is present.

## Step 6 — Print a summary

```
✅ /docs:changelog complete

Entry written: docs/changelog/YYYY/MM/DD/[slug].md
Branch:        [CURRENT_BRANCH] (vs [BASE_BRANCH])
Tickets traced: [tickets, or N/A]

Sections included:
  [list only the Keep a Changelog sections actually written]

Suggested next step:
  Review the <!-- AI-generated --> entry, then commit docs/changelog/.
```
