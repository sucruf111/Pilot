# Pilot

A development pipeline where **Claude Fable 5** (via Claude Code) acts as team lead,
project manager, and reviewer, and **Codex CLI** acts as the coding agent.

Fable owns *what* and *whether it's right*. Codex owns *how*.

## What's in here

```
.claude/skills/pilot/
  SKILL.md                     the /pilot skill — the whole pipeline
  templates/                   PRODUCT_BRIEF, DESIGN_BRIEF, ROADMAP, TASK_SPEC, REVIEW,
                               design-tokens.example.json
  scripts/
    free-gate.sh               mechanical pre-review gate (build/test/lint/boundary)
    token-lint.mjs             rejects raw colors not in design-tokens.json
```

## Install into a project

Copy the skill folder into the target project:

```sh
mkdir -p <project>/.claude/skills
cp -R .claude/skills/pilot <project>/.claude/skills/pilot
```

Or make it available in every project (personal skill):

```sh
cp -R .claude/skills/pilot ~/.claude/skills/pilot
```

Then, inside a Claude Code session in the project, run `/pilot`.

## Pipeline at a glance

```
Phase 0  goal iteration with you            → docs/PRODUCT_BRIEF.md
Phase 1  design brief + Codex concepts      → docs/DESIGN_BRIEF.md   [human approval gate]
Phase 2  design system, tokens, roadmap     → DESIGN_SYSTEM.md, design-tokens.json, ROADMAP.md
Phase 3  autopilot loop, per task:
           JIT spec → codex exec → free gate (no tokens) → Fable diff review → PR
           → LESSONS.md updated → next task
```

Commands: `/pilot` (resume/run) · `/pilot status` · `/pilot next` (one cycle) ·
`/pilot estimate` (Fable-cost projection from the roadmap).

## Design principles

- **Consistency by construction** — design tokens + lint, not per-PR model judgment.
- **Just-in-time specs** — task detail written when dispatched, grounded in the real codebase.
- **Vertical slices** — data + UI + tests per task, not page-by-page.
- **Free gate before paid review** — a failing build never reaches Fable.
- **State on disk** — every phase resumable from files; context loss is harmless.
