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

Anyone runs the same two commands. Updates ship when you bump `version` in
`.claude-plugin/marketplace.json` and the plugin's `plugin.json`; users pull them with
`/plugin marketplace update`.

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
.ai/project-definition.json
```

Sections it cannot infer are marked `⚠️ [Needs human input]`. It never fabricates
business goals or personas.

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

- **`/docs:init`** and **`/docs:update`** set `disable-model-invocation: true` — you
  type them manually. This prevents Claude from generating or overwriting docs without
  your intent.
- **`/docs:check`** can be auto-invoked by Claude when it notices the project has no
  docs or they seem stale.

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
