// Skill catalog — the ONE source of truth for the built-in Claude Code skill names and the
// workspace-skill reader. Kept deliberately dependency-light (only node:fs/os/path): it must NOT
// pull in core/config.js, whose import has load-time side effects (engine-bin probing that can
// write .xenomoon.json, process.exit on a bad --allow). That side-effect chain is fine for the
// server but wrong for the standalone `cli/skill-setup.js`, which is why the built-in list used to
// be duplicated there. Both skills.js (server feature) and cli/skill-setup.js import it instead, so
// the list lives in exactly one place and can't drift.
import { readdirSync, readFileSync, existsSync } from "node:fs";
import { homedir } from "node:os";
import path from "node:path";

/** Known Claude Code built-in skill names. Update when Claude Code ships new ones.
 * @type {string[]} */
export const BUILTIN_SKILLS = [
  "caveman",
  "claude-api",
  "code-review",
  "deep-research",
  "fewer-permission-prompts",
  "grill-me",
  "handoff",
  "init",
  "keybindings-help",
  "loop",
  "review",
  "run",
  "schedule",
  "security-review",
  "simplify",
  "update-config",
  "verify",
  "write-a-skill",
];

/** Framework-plugin skills the orchestrator / main session always sees — the always-on "floor",
 * cross-checked by gen-skill-scope.js against the active domain's plugin skills on disk. EMPTY
 * today: the spine ships no plugin skills of its own, and the current domains (webapp/app) are
 * empty learning packs that ship none. A domain — or a future shared core plugin — that ships
 * `orchestrator`-tagged skills repopulates this. @type {string[]} */
export const ORCHESTRATOR_FRAMEWORK_SKILLS = [];

/** Parse the first `name:` and `description:` values from YAML frontmatter.
 * @param {string} text @returns {{ name: string, description: string } | null} */
function parseFrontmatter(text) {
  const match = text.match(/^---\n([\s\S]*?)\n---/);
  if (!match?.[1]) return null;
  const block = match[1];
  const name = block.match(/^name:\s*(.+)$/m)?.[1]?.trim();
  const description = block.match(/^description:\s*(.+)$/m)?.[1]?.trim();
  if (!name) return null;
  return { name, description: description ?? "" };
}

/** Workspace skills found in ~/.claude/commands/ on this machine.
 * @returns {{ name: string, description: string }[]} */
export function getWorkspaceSkills() {
  const dir = path.join(homedir(), ".claude", "commands");
  if (!existsSync(dir)) return [];
  try {
    return readdirSync(dir)
      .filter((f) => f.endsWith(".md"))
      .flatMap((f) => {
        try {
          const text = readFileSync(path.join(dir, f), "utf8");
          const fm = parseFrontmatter(text);
          if (fm) return [fm];
          return [{ name: f.replace(/\.md$/, ""), description: "" }];
        } catch {
          return [];
        }
      });
  } catch {
    return [];
  }
}
