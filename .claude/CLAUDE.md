# Xenomoon Forge — framework spine rules

Rules for working **on the framework itself** (the Node/TS web UI and tooling under
`ui/`). The bound project's own rules live in the project, not here — see the active
domain pack's Claude Code plugin the framework loads into every project session.

> Scaffold — expand with your own conventions. The essentials below match what the repo
> already enforces.

## Always

- Prefix shell commands with `rtk` (a PreToolUse hook enforces it; see `.claude/settings.json`).
- Plain JS + JSDoc only — no `.ts` files. Types are checked via tsconfig `checkJs`.
- Node/CLI scripts live in `ui/server/` so eslint's node group + tsconfig type-check them.

## Before committing

- `npm run validate` (tsc + eslint, zero warnings) must pass.
- `npx prettier --write` keeps formatting clean (lint-staged also runs it on commit).

## Layout

- `ui/server/` — Node server + CLI scripts, grouped by area: `core/` (+ `core/http/`),
  `integrations/{hermes,codex}/`, `features/{tasks,promotions,transcripts,skills,autonomous}/`,
  `mcp-tools/` (the in-process `makeXTool` SDK tools), and `cli/` (`setup`, `new`, `promote`,
  `doctor`, `materialize`, `update-badges`, `release-*`). New files go in the matching area.
- `ui/client/` — browser modules, grouped by area: `core/` (state, transport, dom/render
  helpers, `main.js` entry) and `features/{chat,activity,tasks,approvals,agents,settings,
sessions,promotions,project,autonomous}/`. `ui/lib/` — shared JSDoc typedefs + helpers.
- `domains/<name>/` — the **domain packs**. Each ships its own Claude Code plugin (the domain's
  agents, skills, tools, hooks and knowledge base) plus a `domain.json` descriptor and orchestrator
  prompt. A plugin is the single source of truth for its domain, loaded into every project session
  via the SDK `plugins` option (`session.js`) so a project needs no copies; terminal use installs it
  once (`.claude-plugin/marketplace.json`). Capabilities namespace as `xenomoon:<name>`. The shipped
  domains (`app`, `webapp`) are empty Node/web learning packs.
- Never put project-specific files in the framework; it points at an external project (default
  `../game`), reads it in place, and the project stays pure.
