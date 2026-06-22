# Domain packs

A **domain pack** is what retargets this framework from one kind of work to another
(Node/web apps today; other domains next) without forking the spine. The spine
(`ui/`, `.claude/`) stays domain-agnostic and reads per-domain values from the active
pack via `ui/server/core/domain-resolver.js`. This whole directory is **additive** —
upstream owns nothing here, so it never causes a merge conflict on a sync.

The shipped packs are **`app`** and **`webapp`** — empty Node/web learning packs that ship
no pre-baked capabilities. (The upstream we track is a Godot framework, but Xenomoon ships
no godot domain, plugin, or engine binary.)

## Selecting the active domain

A project is bound to a domain deterministically at install time: `forge new --domain <name>`
writes a project lock (`.xenomoon-project.json`), which the spine reads as **authoritative**.
With no lock, the binding comes from `XENOMOON_DOMAIN` env → `.xenomoon.json` `"domain"` key.
There is **no privileged default**: with neither a lock nor an override, resolution throws —
a project is never silently driven as some fallback domain.

## What a pack declares (`domains/<name>/domain.json`)

| Field                                    | Used by                    | Meaning                                                             |
| ---------------------------------------- | -------------------------- | ------------------------------------------------------------------- |
| `engine.name` / `engine.projectFile`     | `config.js` (`ENGINE`)     | runtime name + on-disk project marker                               |
| `inventory.scenes` / `inventory.scripts` | `project-state.js`         | file extensions the live inventory scans                            |
| `plugin`                                 | `config.js` / `session.js` | the domain's capability plugin dir (relative to the framework root) |
| `orchestrator`                           | `config.js`                | the routing-prompt file (relative to the framework root)            |
| `commands`                               | `gen-manifest.js`          | build/verify/drive commands written into the manifest               |
| `starter`                                | `new.js`                   | starter folder to scaffold, or absent for install-in-place          |
| `materializeIntoProject`                 | `materialize.js`           | whether install writes working files INTO the project tree          |

Every per-domain value — capability plugin, orchestrator prompt, build/verify commands,
inventory extensions — comes from the pack, not hardcoded in the spine.
