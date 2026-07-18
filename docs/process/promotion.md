# Promotion — game-local → framework plugin

A capability (`skill`, `agent`, `tool`) starts **game-local** and is usable immediately:
`<game>/.claude/skills/…`, `<game>/.claude/agents/…`, or `<game>/tools/…`. When it proves broadly
useful — _not_ specific to one game — it can be **promoted** into the `xenomoon` plugin, which is the
single source of truth loaded into every game session.

Flow: an agent files `mcp__ui__promote { kind, name, reason }` → it lands on the promotions board
(`.xenomoon/promotions.json`) → the human approves → the human runs `npm run promote -- --pending`
(or `npm run promote -- <kind> <name>`). The file move is `promoteOne` in
`ui/server/features/promotions/promote-run.js`. Agents never move files themselves.

**Default to keeping things local.** Promote deliberately, so the framework stays scoped to game-dev.

## Tool domains — universal vs game

`tools/` is **materialized into every game** (`materializeTools`, `ui/server/cli/materialize.js`
copies the whole `plugin/tools/` directory in on server start / `doctor` / `forge new`). So a tool's
**domain** decides where it may live:

- **Universal** — hardcodes NO game-specific resource path. Its scene/inputs come from a parameter
  (`--scene`, the manifest) or it touches only paths every game shares: `res://main.tscn`,
  `res://assets/**`, `res://x-shared-assets/**`, `res://.godot/**`, `res://addons/**`. Universal tools
  live in `plugin/tools/` and materialize everywhere. Examples: `validate.sh`, `verify_scene.gd`,
  `verify_render.gd`, `capture_screenshot.gd`, `gen_textures.gd`, `gen_models.gd`, `forge-facts`.
- **Game** — hardcodes a resource only one game has (`res://levels/test_arena.tscn`,
  `res://entities/pushable_crate/…`). Typical of `play_*`/`verify_*` adversarial bots authored from a
  game's design Acceptance. **Game-domain tools stay in the game's `tools/` and are never promoted.**

**Why it matters:** a game-domain tool promoted into `plugin/tools/` is copied into _every_ game,
where the scene it references does not exist, so the gate (`playgrade.sh` runs the game's `play_*.gd`
bots; `validate.sh` lints/parses `tools/`) fails on the missing resource. This is how orphan tools
like `play_boss_render_windowed.gd` and `verify_arena_render.gd` accumulated and re-failed gates in
unrelated games. (Because materialize is **additive** — it never prunes — removing such a tool from
the plugin stops fresh copies but leaves a stale copy in already-materialized games; delete that game
copy once by hand.)

**The guard:** `promoteOne` rejects a `kind: "tools"` promotion whose source hardcodes a non-universal
`res://…(.tscn|.tres|.glb|…)` path — a deterministic backstop under the orchestrator's own judgement
(`orchestrator.md` → "Tool domains"). To promote a useful game bot, **parameterize its scene first**
(read it from `--scene`/the manifest so it has no hardcoded path), then re-promote.

## Updating an existing core file

`promote` only ADDS new capabilities — it never UPDATES a file already in the plugin. To improve a
materialized core tool/skill/agent, edit it in the plugin directly (it re-materializes to every game);
keep game-specific bits in a game-local extension that sources the core.
