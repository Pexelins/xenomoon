// Automated onboarding test — proves a clean consumer can go from a fresh clone of the framework
// to a wired, runnable project, with the project staying PURE: a domain that installs in place
// writes NOTHING into the target (it binds via the framework's own .xenomoon.json). Bare-node, no
// test runner (same style as ui/reducer.check.js):
//   node ui/server/cli/onboarding.check.js
//
// Deterministic, no Claude/engine binary: export the framework EXACTLY as a forker receives it —
// `git archive` of the tracked tree, so node_modules, .xenomoon.json and logs are excluded and an
// un-committed file is invisible (the real "did we ship it?" test). Then run `forge new --domain
// webapp` into a fresh project carrying a package.json, and assert the framework binds it, the
// project stays pure, and doctor reports healthy.
//
// NOTE: new/edited framework files must be `git add`-ed before running locally — the archive sees
// TRACKED files only. CI runs post-commit, so HEAD has everything.
import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, rmSync, writeFileSync, readFileSync, existsSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parseJSON } from "../../lib/json.js";

const here = path.dirname(fileURLToPath(import.meta.url)); // ui/server/cli
const FRAMEWORK_DIR = path.join(here, "..", "..", "..");

let passed = 0;
/** @param {string} name @param {() => void} fn */
function check(name, fn) {
  fn();
  passed += 1;
  console.log(`ok  ${name}`);
}

const work = mkdtempSync(path.join(tmpdir(), "xeno-onboard-"));
try {
  // ---- Build the "as shipped" framework tree from TRACKED files only ----
  const stashRef = execFileSync("git", ["stash", "create"], { cwd: FRAMEWORK_DIR })
    .toString()
    .trim();
  const ref = stashRef || "HEAD";
  const fw = path.join(work, "framework");
  mkdirSync(fw, { recursive: true });
  const tarBuf = execFileSync("git", ["archive", "--format=tar", ref], {
    cwd: FRAMEWORK_DIR,
    maxBuffer: 256 * 1024 * 1024,
  });
  const tarFile = path.join(work, "framework.tar");
  writeFileSync(tarFile, tarBuf);
  execFileSync("tar", ["-xf", tarFile, "-C", fw]);

  check("framework ships the marketplace + the webapp domain pack (committed)", () => {
    assert.ok(
      existsSync(path.join(fw, ".claude-plugin", "marketplace.json")),
      "marketplace.json must ship (terminal install)",
    );
    assert.ok(
      existsSync(path.join(fw, "domains", "webapp", "domain.json")),
      "domains/webapp/domain.json must ship",
    );
    assert.ok(
      existsSync(path.join(fw, "domains", "webapp", "orchestrator.md")),
      "domains/webapp/orchestrator.md must ship",
    );
    assert.ok(
      existsSync(path.join(fw, "domains", "webapp", "plugin", ".claude-plugin", "plugin.json")),
      "domains/webapp/plugin manifest must ship",
    );
  });

  // ---- forge new --domain webapp → bind a fresh project IN PLACE (writes nothing into it) ----
  const project = path.join(work, "app");
  mkdirSync(project, { recursive: true });
  writeFileSync(
    path.join(project, "package.json"),
    JSON.stringify({ name: "onboard-app", version: "0.0.0", type: "module" }, null, 2) + "\n",
  );
  execFileSync(
    "node",
    [path.join(fw, "ui", "server", "cli", "new.js"), project, "--domain", "webapp"],
    { stdio: "pipe" },
  );

  check("forge new binds the project via the framework's .xenomoon.json", () => {
    const cfg = /** @type {{ domain?: string, projectDir?: string }} */ (
      parseJSON(readFileSync(path.join(fw, ".xenomoon.json"), "utf8"))
    );
    assert.equal(cfg.domain, "webapp", ".xenomoon.json domain must be webapp");
    assert.equal(
      path.resolve(cfg.projectDir ?? ""),
      path.resolve(project),
      ".xenomoon.json projectDir must point at the bound project",
    );
  });

  check("the project stays PURE — the framework writes nothing into it", () => {
    for (const p of [
      ".xenomoon-project.json", // no committed lock for a materialize-nothing domain
      "tools",
      "library",
      "x-shared-assets",
      ".xenomoon",
      path.join(".claude", "agents"),
      path.join(".claude", "skills"),
    ]) {
      assert.ok(!existsSync(path.join(project, p)), `${p} must NOT be written into the project`);
    }
  });

  // doctor already ran inside `forge new` (it throws on a hard failure, which would have failed the
  // new.js call above). Re-run explicitly as a belt-and-suspenders check.
  check("doctor reports a healthy webapp install", () => {
    execFileSync("node", [path.join(fw, "ui", "server", "cli", "doctor.js"), project], {
      stdio: "pipe",
    });
  });

  console.log(`\nonboarding: ${passed} checks passed.`);
} finally {
  rmSync(work, { recursive: true, force: true });
}
