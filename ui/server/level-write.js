// Write a hand-drawn blockout grid from the "Draw Level" UI into the game's
// levels/drawn/current.json, where the dynamic_level scene reads it at runtime
// and extrudes walls + floor. Sibling to asset-write.js: narrow, validated, and
// confined to <project>/levels/drawn/. Cells are tile codes:
// 0 = floor, 1 = wall, 2 = door, 3 = window, 4–7 = item types (by colour). An
// optional `labels` array of { n, x, y } tags specific cells with numbers.
import { writeFileSync, mkdirSync } from "node:fs";
import path from "node:path";
import { PROJECT_DIR } from "./config.js";

const MAX_CELLS = 256 * 256; // generous cap; a sane "for an idea" grid is ~16–128/side
const MAX_TILE = 7; // 0 floor · 1 wall · 2 door · 3 window · 4–7 item types (by colour)

/**
 * Validate the optional numbered-marker list against the grid bounds.
 * @param {unknown} raw @param {number} width @param {number} height
 * @returns {{ n: number, x: number, y: number }[]}
 */
function parseLabels(raw, width, height) {
  /** @type {{ n: number, x: number, y: number }[]} */
  const out = [];
  if (!Array.isArray(raw)) return out;
  for (const item of /** @type {unknown[]} */ (raw)) {
    if (typeof item !== "object" || item === null) continue;
    const l = /** @type {{ n?: unknown, x?: unknown, y?: unknown }} */ (item);
    const n = Math.trunc(Number(l.n));
    const x = Math.trunc(Number(l.x));
    const y = Math.trunc(Number(l.y));
    const inBounds = x >= 0 && x < width && y >= 0 && y < height;
    if (Number.isFinite(n) && inBounds && out.length < 1000) out.push({ n, x, y });
  }
  return out;
}

/**
 * Validate a blockout grid and write it to <project>/levels/drawn/current.json.
 * Shape: { width, height, cell_size?, cells: number[], labels?: {n,x,y}[] } row-major, tile codes 0..7.
 * @param {unknown} grid
 * @returns {{ path: string, width: number, height: number, painted: number } | { error: string }}
 */
export function writeLevel(grid) {
  if (typeof grid !== "object" || grid === null) return { error: "no grid data" };
  const g =
    /** @type {{ width?: unknown, height?: unknown, cell_size?: unknown, cells?: unknown, labels?: unknown }} */ (
      grid
    );
  const width = Number(g.width);
  const height = Number(g.height);
  const cellSize = g.cell_size == null ? 2 : Number(g.cell_size);
  const { cells } = g;

  if (!Number.isInteger(width) || !Number.isInteger(height) || width < 1 || height < 1) {
    return { error: "width/height must be positive integers" };
  }
  if (width * height > MAX_CELLS) return { error: "grid too large" };
  if (!Array.isArray(cells) || cells.length !== width * height) {
    return { error: "cells length must equal width*height" };
  }
  if (!(cellSize > 0) || cellSize > 100) return { error: "cell_size out of range" };

  /** @type {number[]} */
  const norm = cells.map((c) => {
    const n = Math.trunc(Number(c));
    return Number.isFinite(n) && n >= 0 && n <= MAX_TILE ? n : 0;
  });

  const labels = parseLabels(g.labels, width, height);

  const dir = path.join(PROJECT_DIR, "levels", "drawn");
  const file = path.join(dir, "current.json");
  if (!file.startsWith(dir + path.sep)) return { error: "invalid path" }; // defense in depth
  mkdirSync(dir, { recursive: true });
  writeFileSync(
    file,
    JSON.stringify({ width, height, cell_size: cellSize, cells: norm, labels }) + "\n",
  );

  return {
    path: path.relative(PROJECT_DIR, file),
    width,
    height,
    painted: norm.reduce((a, b) => a + (b ? 1 : 0), 0),
  };
}
