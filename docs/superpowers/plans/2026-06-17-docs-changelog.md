# docs:changelog Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the new `/docs:changelog` skill in the docs plugin, which automatically parses branch differences against main/master, extracts Jira or other task management ticket numbers, allows manual ticket/task overrides, drafts standard semantic Keep a Changelog notes, and writes them to a date-partitioned folder structure: `docs/changelog/YYYY/MM/DD/[feature-name].md`.

**Architecture:** Extend the portable shell environment utility `plugins/docs/bin/doc-context` with a secure `changelog-diff` mode to extract branch diffs, recent commit logs, and author metadata. Build a custom `/docs:changelog` skill that consumes this context, parses ticket references, prompts interactively for feature name and ticket confirmations, drafts the changelog using an optimized AI-generated template, and commits the output with proper ticket tracing.

**Tech Stack:** POSIX sh, Markdown/YAML Frontmatter (Claude Code Skill system).

## Global Constraints

- Never use raw Git commands inside the skill's execution prompt; delegate all Git operations to `doc-context` and enforce `allowed-tools: Read Glob Grep Edit Write AskUserQuestion Bash(doc-context *)`.
- Store the final changelog files exclusively in `docs/changelog/YYYY/MM/DD/[feature-name].md` where `[feature-name]` is slugified to lowercase kebab-case.
- Automatically scan the branch name and recent commit subjects for standard issue keys like upper-case alphanumeric IDs (e.g., `PROJ-123`, `JIRA-456`) and github issue numbers (e.g. `#123`).
- Mandatorily include a confirmation gate with a preview of the changelog and the target file path unless the `--yes` / `-y` flag is supplied.
- Maintain version consistency by bumping the plugin version from `1.3.0` to `1.4.0` in both `plugins/docs/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.

---

### Task 1: Extend `doc-context` with `changelog-diff` Mode

**Files:**
- Modify: `plugins/docs/bin/doc-context:190-204`

**Interfaces:**
- Consumes: Native git repository status (main branch, current HEAD commits).
- Produces: Structured stdout metrics and file list for `doc-context changelog-diff`.

- [ ] **Step 1: Read `plugins/docs/bin/doc-context`**

Use the Read tool to inspect the end of the file where case statements route different modes.

- [ ] **Step 2: Add `mode_changelog_diff` function**

Edit `plugins/docs/bin/doc-context` to add the `mode_changelog_diff()` function. It must output the base branch, current branch, author, recent commit subjects (used for ticket scanning), file diff stats, and detailed diffs:

```sh
# ── mode: changelog-diff ──────────────────────────────────────────────────────
# Emits git diff metrics between main and HEAD.
mode_changelog_diff() {
  if ! has_git; then
    echo "NO_GIT"
    echo "# Not a git repository (or git not installed)."
    return 0
  fi

  # Determine base branch (defaulting to main, fallback to master)
  base_branch="main"
  if ! git show-ref --verify --quiet refs/heads/main && ! git show-ref --verify --quiet refs/remotes/origin/main; then
    if git show-ref --verify --quiet refs/heads/master || git show-ref --verify --quiet refs/remotes/origin/master; then
      base_branch="master"
    else
      # If neither exists, use current HEAD~1 or empty tree fallback
      base_branch="HEAD~1"
    fi
  fi

  echo "BASE_BRANCH=$base_branch"
  echo "CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  echo "AUTHOR=$(git log -1 --pretty=format:'%an <%ae>' 2>/dev/null || echo unknown)"
  echo ""
  echo "RECENT_COMMITS:"
  git log "$base_branch...HEAD" --oneline 2>/dev/null | head -50
  echo ""
  echo "DIFF_STAT:"
  git diff --stat "$base_branch...HEAD" 2>/dev/null | head -40
  echo ""
  echo "DIFF_DETAILS:"
  git diff "$base_branch...HEAD" 2>/dev/null | head -500
}
```

- [ ] **Step 3: Route the `changelog-diff` argument in the case statement**

Modify the case routing block to include the new `changelog-diff` mode:

```sh
  env)          mode_env ;;
  diff)         mode_diff ;;
  changelog-diff) mode_changelog_diff ;;
  routes)       mode_routes ;;
```

- [ ] **Step 4: Verify `doc-context` changes locally**

Run the following command directly in the terminal:
```bash
./plugins/docs/bin/doc-context changelog-diff
```
Expected output:
```
BASE_BRANCH=main
CURRENT_BRANCH=feat/changelog-notes
AUTHOR=Ndollem <ndollem@gmail.com>

RECENT_COMMITS:
484ef4d docs: incorporate ticket/task tracing into /docs:changelog design
b18b773 docs: write and approve /docs:changelog skill design specification

DIFF_STAT:
 docs/superpowers/specs/2026-06-17-docs-changelog-design.md | 176 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 176 insertions(+)

DIFF_DETAILS:
...
```

- [ ] **Step 5: Commit changes**

```bash
git add plugins/docs/bin/doc-context
git commit -m "feat(doc-context): add changelog-diff mode for branch-to-main git analysis

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 2: Scaffold the Changelog Template and Skill Shell

**Files:**
- Create: `plugins/docs/skills/changelog/templates/changelog.md`
- Create: `plugins/docs/skills/changelog/SKILL.md` (Initial skeleton)

**Interfaces:**
- Consumes: None.
- Produces: The template file structure on disk.

- [ ] **Step 1: Create the Changelog Template file**

Write the file `plugins/docs/skills/changelog/templates/changelog.md` with Keep a Changelog semantic headers:

```markdown
# Changelog — {{NAME}}

**Date**: {{DATE}}
**Author**: {{AUTHOR}}
**Branch**: {{BRANCH}}
**Tickets**: {{TICKETS}}
<!-- AI-generated -->

## Overview
[Provide a clear, 2-3 sentence high-level summary of the changes made in this branch and their purpose.]

## [Standard Keep a Changelog Sections]

### Added
- [Details of new features, files, or capabilities introduced]

### Changed
- [Details of existing functionality or files that were modified]

### Fixed
- [Details of any bugs, issues, or hotfixes addressed]

### Removed
- [Details of any deprecated or removed features/files]

### Security
- [Details of any security-related enhancements or fixes]

---
*Generated by `/docs:changelog`*
```

- [ ] **Step 2: Create initial skeleton for `plugins/docs/skills/changelog/SKILL.md`**

Write `plugins/docs/skills/changelog/SKILL.md` containing only the frontmatter for verification of skill loading:

```markdown
---
name: changelog
description: >
  Create a changelog notes entry based on the updated code of the repo.
  Compiles a standard, keep-a-changelog style note from the branch changes
  and saves it in 'docs/changelog/YYYY/MM/DD/[feature/module/task name].md'.
argument-hint: "[feature, module, or task name] [--yes]"
allowed-tools: Read Glob Grep Edit Write AskUserQuestion Bash(doc-context *)
---

# changelog

You are a documentation engineer compiling a changelog notes entry based on the updated code of the repo.
```

- [ ] **Step 3: Verify skill is registered in Claude Code**

Start Claude Code with the local plugin dir:
```bash
claude --plugin-dir ./plugins/docs
```
Inside the session, run:
```
/reload-plugins
```
Then type `/docs` to see if `/docs:changelog` appears in the autocomplete suggestion list. Exit the session when verified.

- [ ] **Step 4: Commit templates and scaffold**

```bash
git add plugins/docs/skills/changelog
git commit -m "feat(changelog): scaffold changelog skill metadata and template

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 3: Implement Core Changelog Generation and Ticket Tracing

**Files:**
- Modify: `plugins/docs/skills/changelog/SKILL.md` (Add full execution instructions)

**Interfaces:**
- Consumes: Output of `doc-context env` and `doc-context changelog-diff`.
- Produces: The written file at `docs/changelog/YYYY/MM/DD/[name].md`.

- [ ] **Step 1: Write full skill instructions in `SKILL.md`**

Write the complete prompt logic to `plugins/docs/skills/changelog/SKILL.md`:

```markdown
---
name: changelog
description: >
  Create a changelog notes entry based on the updated code of the repo.
  Compiles a standard, keep-a-changelog style note from the branch changes
  and saves it in 'docs/changelog/YYYY/MM/DD/[feature/module/task name].md'.
argument-hint: "[feature, module, or task name] [--yes]"
allowed-tools: Read Glob Grep Edit Write AskUserQuestion Bash(doc-context *)
---

# changelog

You are a documentation engineer compiling a changelog notes entry based on the updated code of the repo.
Your job is to analyze code changes, trace relevant ticket numbers, and draft standard, Keep a Changelog semantic notes.

## Focus Area / Name
**$ARGUMENTS**

If the arguments contain **`--yes`** (or **`-y`**), skip the confirmation gates and apply the edits directly; treat the remaining text as the feature name.

## Environment Scan

```!
doc-context env
```

## Branch Differences

```!
doc-context changelog-diff
```

## Step 1 — Check docs exist
If there is no `docs/` folder, stop and tell the user to run `/docs:init` first. Do not proceed.

## Step 2 — Resolve Arguments & Ticket Numbers

1. **Feature/Module Name**:
   - Clean `$ARGUMENTS` to remove flags like `--yes` or `-y`.
   - If the name is still empty, use `AskUserQuestion` to ask the user: "What is the name of this feature, module, or task? (e.g. auth-migration)".
   - Convert the name into a lowercase, slugified kebab-case format (e.g. "auth-migration").

2. **Ticket/Task Tracing**:
   - Automatically extract tracking ticket keys from the current branch name (e.g., `feat/JIRA-101-auth` -> `JIRA-101`) and the `RECENT_COMMITS` text.
   - Scan for:
     - Jira-style alphanumeric issue keys (e.g. `[A-Z]+-[0-9]+` like `PROJ-123`, `JIRA-456`).
     - GitHub-style issue numbers (e.g. `#123`).
   - If multiple ticket numbers exist across multiple commits, collect **all** unique ticket keys.
   - If `--yes` is **not** passed:
     - Use `AskUserQuestion` to ask the user to confirm the extracted tickets, or let them input manual comma-separated ticket numbers. E.g. "Confirmed task tracker tickets (e.g. JIRA-121, PROJ-233) or leave empty if none:".
     - If no tickets were found, prompt the user if they'd like to supply one.
   - If `--yes` is passed, use the automatically extracted tickets, defaulting to `N/A` if none were found.

## Step 3 — Analyze Diff and Synthesize Notes

1. Read the template file `${CLAUDE_SKILL_DIR}/templates/changelog.md` to get the structure.
2. Formulate Keep a Changelog notes:
   - Identify added, modified, fixed, or removed components from the `DIFF_STAT` and `DIFF_DETAILS`.
   - Draft bullet points under standard sections (`Added`, `Changed`, `Fixed`, `Removed`, `Security`). Include ONLY sections that actually contain changes.
   - **Traceability**: Append the relevant ticket key (e.g. `[PROJ-123]`) to individual bullet points corresponding to those changes. If a change covers multiple tickets, list all of them.
3. Map overall summary text to `## Overview`.
4. Replace placeholders in the template:
   - `{{NAME}}` -> The kebab-case name of the feature/module.
   - `{{DATE}}` -> The scanned date `YYYY-MM-DD`.
   - `{{AUTHOR}}` -> The parsed Git author.
   - `{{BRANCH}}` -> The current branch name.
   - `{{TICKETS}}` -> The comma-separated list of confirmed ticket numbers, or `N/A` if none.

## Step 4 — Safety Gate (Preview & Confirm)

1. Determine the destination path: `docs/changelog/YYYY/MM/DD/[name].md` where `YYYY/MM/DD` represents today's date.
2. Preview the full drafted Markdown content to the user in the terminal, stating the destination file path.
3. If `--yes` / `-y` is **not** supplied:
   - Use `AskUserQuestion` to prompt the user: "Write changelog entry to [path]?" (Options: "Proceed", "Cancel").
   - If the user cancels or declines, stop and write nothing.

## Step 5 — Write Files & Log Freshness

1. Write the full drafted content into the destination file.
2. Update `docs/LAST_REVIEWED`:
   - Append or edit the review date.
   - Add a line: `Latest changelog: docs/changelog/YYYY/MM/DD/[name].md`.

## Step 6 — Summarize Output

Print a clean confirmation summary:
```
✅ /docs:changelog entry created!

File written: docs/changelog/YYYY/MM/DD/[name].md
Branch: [branch]
Tickets traced: [tickets]

Sections included:
  [List mapped Keep a Changelog sections]
```
```

- [ ] **Step 2: Dry Run and Verify Generation**

Launch the local plugin:
```bash
claude --plugin-dir ./plugins/docs
```
Inside the session, execute:
```
/reload-plugins
/docs:changelog "changelog-notes"
```
Verify:
- It asks you to confirm or enter task tickets (input `JIRA-101, PROJ-202`).
- It previews the formatted markdown.
- It asks to Proceed or Cancel. Choose "Proceed".
- Verify that `docs/changelog/2026/06/17/changelog-notes.md` is successfully created, and matches the correct template formatting.
- Verify `docs/LAST_REVIEWED` is updated.

- [ ] **Step 3: Commit implementation**

```bash
git add plugins/docs/skills/changelog/SKILL.md
git commit -m "feat(changelog): implement changelog generation, interactive ticket prompt, and tracing

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 4: Version Bump & Release Manifest Update

**Files:**
- Modify: `plugins/docs/.claude-plugin/plugin.json:4`
- Modify: `.claude-plugin/marketplace.json:13`

**Interfaces:**
- Consumes: Current version state `1.3.0`.
- Produces: Updated version state `1.4.0` in both manifests.

- [ ] **Step 1: Read the plugin manifests**

Use the Read tool to inspect:
- `plugins/docs/.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`

- [ ] **Step 2: Update `plugin.json` version**

Edit `plugins/docs/.claude-plugin/plugin.json` to bump the version to `1.4.0`:

```json
  "version": "1.4.0",
```

- [ ] **Step 3: Update `marketplace.json` version**

Edit `.claude-plugin/marketplace.json` to bump the version of the `docs` plugin to `1.4.0`:

```json
      "version": "1.4.0"
```

- [ ] **Step 4: Verify marketplace integration**

Start local Claude Code:
```bash
claude --plugin-dir ./plugins/docs
```
Verify the installed plugin lists version `1.4.0` under the `/plugin` menu.

- [ ] **Step 5: Commit manifest bumps**

```bash
git add plugins/docs/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "chore: bump docs plugin and marketplace version to 1.4.0

Co-Authored-By: Claude <noreply@anthropic.com>"
```
