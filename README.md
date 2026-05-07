# Marlo AI

A Claude Code orchestration system for shipping projects phase-by-phase. One Project Manager skill drives the conversation; eight phase-specialist subagents do the work; the user signs off between phases.

## Why

Building a real project from a one-line prompt is brittle. You either get an over-eager generator that scaffolds everything in one shot (and gets the direction wrong), or a chatty assistant that asks every question every time. Marlo splits the difference:

- A single **PM skill** runs in your conversation. It owns discovery, key/account collection, and sign-off gates — the things that need a human.
- Eight **phase subagents** do the execution work in isolation. They never talk to you directly; they exit with structured JSON the PM relays.
- A **clickable demo** is the first deliverable. You approve direction before any real backend or frontend work begins.

## Architecture

```
You ──► /project-manager (skill, runs in conversation)
                │
                │  Phase 0 — Discovery (PM does this directly)
                │  Phase 1 — demo-builder        (clickable Next.js mockup)
                │  Phase 2 — planner             (writes PLAN.md, scaffolds real repo)
                │  Phase 3..K  — backend-builder (one per backend milestone)
                │  Phase K+1   — backend-tester  (curl + DB verify, pre-frontend)
                │  Phase K+2..M — frontend-builder
                │  Phase M+1   — frontend-tester (browser walk-through)
                │  Phase M+2   — hardener        (bugs + security + dep audit)
                │  Phase M+3   — deployer (mode=staging)
                │  Phase M+4   — deployer (mode=prod, observability + domain)
                ▼
         dispatched via Agent tool with structured JSON contract
```

## Install

This is a Claude Code config drop-in. Copy the files into your `~/.claude/` tree:

```bash
git clone https://github.com/mayer3939/Marlo-AI.git
cd Marlo-AI

# Skill
mkdir -p ~/.claude/skills/project-manager
cp skills/project-manager/SKILL.md ~/.claude/skills/project-manager/

# Agents
mkdir -p ~/.claude/agents
cp agents/*.md ~/.claude/agents/

# Helper
mkdir -p ~/.claude/bin
cp bin/check-frontmatter.sh ~/.claude/bin/
chmod +x ~/.claude/bin/check-frontmatter.sh
```

Restart Claude Code if `/project-manager` doesn't appear in the slash-command list.

## Use

In any working directory:

```
/project-manager
```

The PM will run Phase 0 (discovery: persona, core flow, cloud, integrations, compliance, stack, success metric), save your answers to `docs/briefing.md` in your project, and dispatch `demo-builder` for Phase 1. After you approve the clickable demo, it walks through the rest of the phases, gating on your "approved" between each.

## State files (per project)

- `docs/briefing.md` — Phase 0 output, append-only.
- `PLAN.md` — phase-by-phase plan, PM keeps it current.
- `docs/phase-reports/phase-NN-name.md` — written by each subagent on exit.

## Contract

Every subagent exits with structured JSON the PM parses:

```json
{
  "status": "done | needs_input | blocked",
  "report_path": "docs/phase-reports/phase-NN-name.md",
  "needs_input": [{"name": "...", "why": "...", "how_to_get": "..."}],
  "blocker": "",
  "summary": "1-3 sentences for PM to relay"
}
```

If a subagent needs a key, account, or decision it doesn't have, it exits `needs_input` rather than asking you. The PM relays. No subagent ever talks to you directly.

## Critical gates

Three non-negotiable stop points:

- **Demo gate** (after Phase 1): user must approve the clickable mockup before any real build starts.
- **Backend testing gate** (after Phase K+1): no frontend until backend is verified standalone.
- **Staging gate** (after Phase M+3): no production deploy until staging is clean.

## Built on

- [Claude Code](https://claude.com/claude-code) — the CLI runtime
- [superpowers](https://github.com/obra/superpowers) — `phased-project-workflow`, `writing-plans`, `brainstorming`, `subagent-driven-development`

## Docs

- [`docs/design.md`](docs/design.md) — full architecture spec
- [`docs/plan.md`](docs/plan.md) — implementation plan used to build this

## License

MIT
