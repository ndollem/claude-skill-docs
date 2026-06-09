# docs — Claude Code documentation plugin

[![validate](https://github.com/ndollem/claude-skill-docs/actions/workflows/validate.yml/badge.svg)](https://github.com/ndollem/claude-skill-docs/actions/workflows/validate.yml)

A Claude Code **plugin** that makes project documentation a first-class, low-friction
part of development: docs are generated from the codebase, kept in sync as code evolves,
and audited proactively instead of left to decay.

It ships three skills, namespaced under `docs`:

| Command | What it does |
|---|---|
| `/docs:init` | Bootstrap full `docs/` from scratch by scanning an existing codebase |
| `/docs:update [area]` | Update specific docs sections after a feature or refactor |
| `/docs:check` | Audit documentation health and surface drift vs. the codebase |

This repository is also a **plugin marketplace** (`ndollem-docs-tools`) so the plugin can
be installed and updated through Claude Code's native plugin system — no install script.

---

## Install (from this marketplace)

Add the marketplace from GitHub, then install the plugin:

```
/plugin marketplace add ndollem/claude-skill-docs
/plugin install docs@ndollem-docs-tools
```

Anyone runs the same two commands.

### Update an existing install

When a new version is published, refresh the marketplace catalog so Claude Code sees the
new `version`:

```
/plugin marketplace update ndollem-docs-tools
```

Then upgrade the installed copy with one of these (third-party marketplaces do **not**
auto-update by default):

- **Enable auto-update (recommended, one-time):** run `/plugin` → **Marketplaces** tab →
  select `ndollem-docs-tools` → **Enable auto-update**. From then on Claude Code refreshes
  the catalog and updates the plugin at startup; you'll be prompted to run
  `/reload-plugins` when it does.
- **Manual:** if it didn't auto-update, reinstall to pull the new version:
  ```
  /plugin uninstall docs@ndollem-docs-tools
  /plugin install docs@ndollem-docs-tools
  ```

Either way, **start a new Claude Code session** (or run `/reload-plugins`) so the refreshed
skills load. Confirm the version with `/plugin` → **Installed** tab, which lists
`docs@ndollem-docs-tools` with its installed version.

> If skills still look stale after updating, clear the plugin cache:
> `rm -rf ~/.claude/plugins/cache`, restart Claude Code, and reinstall.

> **Maintainer note:** Claude Code only detects an update when the `version` field is
> bumped in **both** `.claude-plugin/marketplace.json` and
> `plugins/docs/.claude-plugin/plugin.json`. Every behavior change must bump both, or
> existing users will never receive it. The current version is **1.1.0**.

### Try it locally first (no install)

```bash
./scripts/dev-install.sh
# or directly:
claude --plugin-dir ./plugins/docs
```

Inside the session, `/help` lists `/docs:init`, `/docs:update`, `/docs:check`. After
editing a skill, run `/reload-plugins`.

---

## Usage

### Bootstrap docs (new project or retrofit onto an existing codebase)

```
/docs:init
```

With a description hint:

```
/docs:init SaaS app for managing restaurant reservations
```

Interview mode — fills business sections instead of leaving `⚠️` markers:

```
/docs:init "restaurant reservations SaaS" --interactive
```

Generated-doc language (`en` default, `id` for Bahasa Indonesia, `auto` to match the
repo). Headings, flags, and JSON keys always stay in English so the skills can parse
them; only the prose changes:

```
/docs:init --lang id
```

Generates:

```
docs/01-prd.md  02-erd.md  03-architecture.md  04-coding-standards.md
docs/05-decision-log.md  docs/LAST_REVIEWED
AGENTS.md
CLAUDE.md
.ai/project-definition.json
```

`AGENTS.md` is the source of truth for agent instructions (the cross-tool open standard).
`CLAUDE.md` is a thin file that imports it via `@AGENTS.md` — because Claude Code reads
`CLAUDE.md`, not `AGENTS.md`, this is what makes your agent instructions load
automatically at session start. Editing only ever happens in `AGENTS.md`; the two never
duplicate.

Sections it cannot infer are marked `⚠️ [Needs human input]`. It never fabricates
business goals or personas. **Existing files are never overwritten** — on a repo that
already has a hand-written `CLAUDE.md`, init preserves it and only appends the
`@AGENTS.md` import if missing; any other pre-existing target is skipped. Re-running
`/docs:init` is safe and idempotent.

### After shipping a feature

```
/docs:update auth-module
/docs:update payment-integration
/docs:update database-schema
```

Updates only the sections relevant to the area you name, using surgical edits (never
whole-file rewrites). New content is tagged `<!-- AI-generated -->` so you know what to
review.

### Audit doc health anytime

```
/docs:check
```

Produces a health report: missing docs, stale sections, drift vs. the codebase,
unresolved `⚠️` flags, and a prioritized action list. Read-only — never writes.

---

## How invocation works

All three commands appear in the `/` menu and can be invoked by you or by Claude. The
safety that matters for the file-writing commands lives in the workflow, not in
hiding them:

- **`/docs:init`** and **`/docs:update`** write to disk, so they **preview the exact
  files/sections they will change and ask for confirmation before writing**. Nothing is
  created or edited until you approve. Pass **`--yes`** (or `-y`) to skip the prompt for
  non-interactive runs.
- **`/docs:check`** is read-only and can be auto-invoked by Claude when it notices the
  project has no docs or they seem stale.

> **Why not `disable-model-invocation`?** An earlier version set that flag on `init` and
> `update`. It blocked Claude from auto-running them, but as a side effect Claude Code
> also dropped them from the `/` autocomplete menu (the skill showed as `user-only` /
> "locked by author"). Since plugin-skill visibility can't be toggled from user settings
> (`skillOverrides` does not apply to plugin skills), the safety was moved into a
> confirmation gate instead — so the commands stay visible **and** safe.

## Portability

All environment scanning runs through `plugins/docs/bin/doc-context`, which detects
whether the project uses git and degrades gracefully. The skills work in any project —
git or not, fresh repo or deep history — without raw `git` commands erroring out.

## Repository layout

```
.claude-plugin/marketplace.json   # marketplace catalog (ndollem-docs-tools)
plugins/docs/
  .claude-plugin/plugin.json       # plugin manifest
  bin/doc-context                  # shared, git-aware environment scanner
  skills/{init,update,check}/SKILL.md
  skills/init/templates/           # the 8 doc templates
  README.md
scripts/dev-install.sh             # local --plugin-dir launcher
PRD.md                             # product requirements for this plugin
```

## Notes

- Keep generated `docs/` committed to version control so the whole team benefits.
- `docs/LAST_REVIEWED` is how `/docs:check` measures staleness.
- The skills write files but never run `git commit` — committing is always a human action.

## License

MIT © Agus Salim (ndollem). See [LICENSE](LICENSE).
