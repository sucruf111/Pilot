#!/usr/bin/env node
// token-lint: fails if source files use raw color values not present in design-tokens.json.
// Consistency by construction — cheap grep instead of model judgment.
//
// Usage: node token-lint.mjs [--tokens design-tokens.json] [--src "src/**"] [file...]
// With explicit file args (e.g. from a diff), only those files are checked.

import { readFileSync, existsSync } from "node:fs";
import { globSync } from "node:fs";
import path from "node:path";

const args = process.argv.slice(2);
function opt(name, fallback) {
  const i = args.indexOf(name);
  return i >= 0 ? args.splice(i, 2)[1] : fallback;
}
const tokensPath = opt("--tokens", "design-tokens.json");
const srcGlob = opt("--src", "src/**");

if (!existsSync(tokensPath)) {
  console.error(`token-lint: ${tokensPath} not found — run Phase 2 first.`);
  process.exit(2);
}

// Collect every string value in the tokens file (hex colors, rgba, etc.), lowercased.
const allowed = new Set();
(function walk(node) {
  if (typeof node === "string") allowed.add(node.toLowerCase());
  else if (node && typeof node === "object") Object.values(node).forEach(walk);
})(JSON.parse(readFileSync(tokensPath, "utf8")));

const CHECK_EXT = new Set([".ts", ".tsx", ".js", ".jsx", ".swift", ".kt", ".css", ".scss", ".vue", ".svelte", ".dart"]);
const files = args.length
  ? args
  : globSync(srcGlob, { exclude: (f) => f.includes("node_modules") });

const HEX = /#[0-9a-fA-F]{3,8}\b/g;
let violations = 0;

for (const file of files) {
  if (!CHECK_EXT.has(path.extname(file)) || !existsSync(file)) continue;
  // The tokens file itself and the design-system layer may define raw values.
  if (path.resolve(file) === path.resolve(tokensPath)) continue;
  if (file.includes("design-system/tokens") || file.includes("DesignTokens")) continue;

  const lines = readFileSync(file, "utf8").split("\n");
  lines.forEach((line, i) => {
    for (const m of line.match(HEX) ?? []) {
      if (!allowed.has(m.toLowerCase())) {
        console.error(`${file}:${i + 1}: raw color ${m} not in ${tokensPath}`);
        violations++;
      }
    }
  });
}

if (violations) {
  console.error(`\ntoken-lint: ${violations} violation(s). Use values from ${tokensPath} via the design-system layer.`);
  process.exit(1);
}
console.log("token-lint: OK");
