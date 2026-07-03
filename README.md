# Pilot

![Pilot — Fable leads, Codex builds](docs/assets/header.png)

**[→ Project page](https://sucruf111.github.io/Pilot/)**

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

Works on **new and existing projects** — for an existing repo, Phase A audits the
codebase, reverse-engineers the design system and tokens from what's actually there,
grandfathers old violations (the gate only lints changed files), and builds the
roadmap from where the project stands.

```
Phase A  (existing repos) audit & adopt     → briefs/tokens derived from the codebase
Phase 0  goal iteration with you            → docs/PRODUCT_BRIEF.md
Phase 1  design brief + Codex concepts      → docs/DESIGN_BRIEF.md   [human approval gate]
Phase 2  design system, tokens, roadmap     → DESIGN_SYSTEM.md, design-tokens.json, ROADMAP.md
Phase 3  autopilot loop, per task:
           JIT spec → codex exec → free gate (no tokens) → Fable diff review → PR
           → LESSONS.md updated → next task
```

Commands: `/pilot` (resume/run) · `/pilot status` · `/pilot next` (one cycle) ·
`/pilot estimate` (Fable-cost projection from the roadmap).

## Model & effort configuration

`docs/pilot/config.json` (created at preflight) controls who does what, at what depth:

```json
{
  "lead":   { "model": "fable-5", "planning_effort": "xhigh", "review_effort": "high" },
  "review": { "model": "inherit", "escalate_blockers_to_lead": true },
  "codex":  { "model": "gpt-5.5", "reasoning_effort": "xhigh", "extra_args": [] }
}
```

- **lead.model** — `fable-5` for the hardest projects, `opus-4.8` at half the price for
  most builds; the skill checks the running session model and asks you to switch on
  mismatch.
- **review.model** — `inherit`, or a cheaper model (`opus`, `sonnet`) to run routine
  diff reviews in a subagent, with blockers escalating back to the lead.
- **codex** — model/effort flags appended to every `codex exec` dispatch.

## Design principles

- **Consistency by construction** — design tokens + lint, not per-PR model judgment.
- **Just-in-time specs** — task detail written when dispatched, grounded in the real codebase.
- **Vertical slices** — data + UI + tests per task, not page-by-page.
- **Free gate before paid review** — a failing build never reaches Fable.
- **State on disk** — every phase resumable from files; context loss is harmless.
