# PM Orchestrator + Phase Subagents — Design

**Date:** 2026-05-07
**Owner:** João
**Status:** Approved (design); pending implementation plan

## 1. Goal

Build a Claude Code orchestration system that lets João start any new project by talking to a single Project Manager (PM) skill. The PM:

- Runs the discovery conversation directly with the user (briefing, stack, integrations, keys, accounts, permissions).
- Dispatches specialized phase subagents to execute the work.
- Gates progress on user sign-off between phases.
- Produces a clickable UI mockup early so the user approves the direction before any real backend/frontend work begins.

The system layers on top of João's existing `phased-project-workflow` skill — it does not replace it. Subagents inherit the discipline of that skill (one milestone per phase, backend before frontend, dedicated hardening + deploy phases, exact commands handed to user, acceptance criteria written before implementation).

## 2. Non-goals

- Not a replacement for `phased-project-workflow` — that skill remains the source of truth for phase semantics.
- Not autonomous deployment. Human-required actions (account creation, key generation, paying for services, DNS) still flow through the user.
- Not a single-conversation experience. Sessions can span multiple compactions; `PLAN.md` + per-phase reports are the persistence layer.

## 3. Phase order

Ten phases. Phase 1 ("Planning & Demo") is the new gate that produces a clickable mockup before any real build.

| # | Phase | Owner |
|---|---|---|
| 0 | Discovery | **PM (conversational, not a subagent)** |
| 1 | Planning & Demo | `demo-builder` |
| 2 | Scaffolding & PLAN.md | `planner` |
| 3..K | Backend Milestones | `backend-builder` (re-invoked per milestone) |
| K+1 | Backend Local Testing | `backend-tester` |
| K+2..M | Frontend Milestones | `frontend-builder` (re-invoked per milestone) |
| M+1 | Frontend UI Testing | `frontend-tester` |
| M+2 | Bug Fixing & Security | `hardener` |
| M+3 | Staging Deploy | `deployer` (mode: `staging`) |
| M+4 | Custom Domain, Observability & Production Deploy | `deployer` (mode: `prod`) |

**Demo gate (between Phase 1 and Phase 2):** the user must explicitly approve the clickable mockup before `planner` is dispatched. This is the most important non-deploy gate in the system — it prevents wasted scaffolding + planning effort on a misunderstood direction.

## 4. PM responsibilities

PM is implemented as a Claude Code skill at `~/.claude/skills/project-manager/SKILL.md`. It runs in the main conversation and never delegates user-facing dialogue.

### 4.1 Phase 0 — Discovery (PM does this directly)

Before dispatching any subagent, PM runs a conversational briefing covering:

- **Persona** — real user, not "users".
- **Core flow** — single most important end-to-end action.
- **Out of scope** — explicit list to refer back to.
- **Hard constraints** — deadline, budget, team size.
- **Cloud / hosting platform** — Azure, AWS, GCP, Vercel, Netlify, Fly, Railway, Cloudflare, etc.
- **Integrations** — email (SendGrid, Resend, Postmark), Microsoft (Graph, Entra ID, Outlook), Google (OAuth, Workspace, Maps, Calendar), Stripe, Supabase, IoT / connected devices, third-party APIs, internal services.
- **Compliance** — GDPR, HIPAA, SOC2, PCI, regional data residency.
- **Stack preferences** — frameworks, languages, ORM, package manager.
- **Success metric** — how do we know this project succeeded?

Output: `docs/briefing.md` in the project repo. Append-only — revisions add a `Revision YYYY-MM-DD` block, never rewrite history.

### 4.2 Per-phase orchestration

For every phase 1..M+4, PM runs this loop:

1. **Propose phase** — state phase number, title, subagent assigned, draft acceptance criteria. Wait for user agreement.
2. **Collect inputs** — list and collect every key/account/decision the subagent will need. Add to `.env`, `.env.example`, or `PLAN.md`.
3. **Dispatch subagent** — call the `Agent` tool with `subagent_type: <role>` and the prompt template from §6.3.
4. **Handle response** — parse the subagent's structured JSON exit (see §6.4). Three branches:
   - `done` → walk user through verify steps; run acceptance checklist; on user approval, mark phase done in `PLAN.md` and proceed.
   - `needs_input` → collect the listed inputs from the user; re-dispatch with augmented prompt.
   - `blocked` → surface the blocker, discuss with user, decide whether to abort, re-scope, or escalate.
5. **Hand-over commands** — give the user the literal `git`, migration, env, and deploy commands for this phase. Never describe them in prose.
6. **Sign-off gate** — wait for the user's explicit "approved" before proposing the next phase.

### 4.3 What PM never does

- PM never writes feature code. Implementation belongs to subagents.
- PM never lets subagents talk to the user. If a subagent needs input, it exits with `needs_input` and PM relays.
- PM never skips the demo gate or the staging gate.

## 5. Subagent roster

Eight subagent files at `~/.claude/agents/<name>.md`. Each has a frontmatter declaring `description`, `tools`, and (where useful) `model`.

| Subagent | Phase(s) | Tools (least-privilege + always Skill) |
|---|---|---|
| `demo-builder` | 1 | Read, Write, Edit, Bash, Skill, Glob, Grep |

`demo-builder` produces a clickable Next.js mockup running on mock data — every screen the user persona will encounter, with stub navigation between them. No real backend, no real auth, no API calls. Output is a runnable dev server URL the user clicks through to approve direction.
| `planner` | 2 | Read, Write, Edit, Bash, Skill |
| `backend-builder` | 3..K (N invocations) | Read, Write, Edit, Bash, Skill, WebFetch |
| `backend-tester` | K+1 | Read, Bash, Skill, WebFetch |
| `frontend-builder` | K+2..M (N invocations) | Read, Write, Edit, Bash, Skill, Glob, Grep |
| `frontend-tester` | M+1 | Read, Bash, Skill |
| `hardener` | M+2 | Read, Edit, Bash, Skill, Grep, Agent (for nested code-reviewer) |
| `deployer` | M+3 + M+4 | Read, Edit, Bash, Skill, WebFetch |

**Subagent contract — every worker:**

- Receives a single dispatch message containing the phase brief (see §6.3).
- May read any file, run commands, and edit code per its tool grant.
- May invoke superpowers skills via the `Skill` tool. The recommended skill mapping (§5.1) is a hint; subagents are instructed to scan available skills before each non-trivial action.
- Exits with the structured JSON in §6.4. Always writes a per-phase report to `docs/phase-reports/phase-<NN>-<name>.md`.

### 5.1 Recommended superpowers skill mapping

| Subagent | Skills it should consider invoking |
|---|---|
| `demo-builder` | `frontend-design`, `brainstorming` |
| `planner` | `writing-plans`, `phased-project-workflow` |
| `backend-builder` | `test-driven-development`, `debugging`, `writing-clearly-and-concisely` |
| `backend-tester` | `debugging`, verification-type skills |
| `frontend-builder` | `frontend-design`, `test-driven-development` |
| `frontend-tester` | `debugging`, browser-testing skills |
| `hardener` | `debugging`, security-review skills, dispatch `code-reviewer` agent |
| `deployer` | deployment / observability skills as available |

These mappings are documented in each subagent's instructions but **not hard-coded** — subagents check the live skill list before action so newly-added skills are picked up automatically.

## 6. State, contracts, and prompt templates

### 6.1 Three persistent artifacts (project repo)

- **`docs/briefing.md`** — Phase 0 output. Read by every subagent. Append-only.
- **`PLAN.md`** — canonical phase plan, structured per `phased-project-workflow`. PM updates after every phase. Each phase row tracks: title, subagent assigned, acceptance criteria, status (`pending` / `in_progress` / `done`), notes / decisions.
- **`docs/phase-reports/phase-<NN>-<name>.md`** — written by each subagent on exit. Contains: changed files, verification commands, decisions made inside the phase, follow-ups for later phases. Keeps PM context lean — PM trusts `PLAN.md` and reads reports only when needed.

### 6.2 Why three files instead of one

A single `PLAN.md` with embedded reports balloons fast and pollutes PM context every turn. Splitting per-phase reports out keeps the always-loaded artifact (`PLAN.md`) small while still preserving full per-phase detail for debugging and audit.

### 6.3 Subagent prompt template (PM constructs this for every dispatch)

```
You are <subagent-name>, executing Phase <N>: <phase title>.

Briefing:        @docs/briefing.md
Project plan:    @PLAN.md  (read rows above this phase for context)
Prior reports:   @docs/phase-reports/  (read if you need detail on a prior phase)

Acceptance criteria for THIS phase (must all pass before you exit):
  - <criterion 1>
  - <criterion 2>
  - ...

Inputs already collected:
  - <key/decision name>: <value or env var name>

Hard rules:
  - If you need a key, account, or decision you don't have → exit with status
    "needs_input" and list exactly what you need. Do NOT ask the user yourself.
  - If you finish the work → write your report to
    docs/phase-reports/phase-<NN>-<name>.md and exit with status "done".
  - If you hit a real blocker → exit with status "blocked" and explain.
  - Use superpowers skills (Skill tool) liberally. Recommended for your role:
    <list from §5.1>. Always scan the live skill list before non-trivial work.

When you exit, your final message MUST be valid JSON matching the schema in §6.4.
```

### 6.4 Structured exit contract (every subagent)

```json
{
  "status": "done" | "needs_input" | "blocked",
  "report_path": "docs/phase-reports/phase-<NN>-<name>.md",
  "needs_input": [
    { "name": "AZURE_TENANT_ID", "why": "Required for MS Graph auth in Phase 4", "how_to_get": "Azure portal → AAD → Properties" }
  ],
  "blocker": "Optional free-form description if status=blocked",
  "summary": "1-3 sentences for PM to relay to the user"
}
```

PM parses this programmatically. Free-form replies break orchestration.

## 7. File layout

### 7.1 Files this design adds (under `~/.claude/`)

```
~/.claude/
├── skills/
│   ├── phased-project-workflow/SKILL.md         (existing, untouched)
│   └── project-manager/SKILL.md                 (NEW)
└── agents/
    ├── demo-builder.md                          (NEW)
    ├── planner.md                               (NEW)
    ├── backend-builder.md                       (NEW)
    ├── backend-tester.md                        (NEW)
    ├── frontend-builder.md                      (NEW)
    ├── frontend-tester.md                       (NEW)
    ├── hardener.md                              (NEW)
    └── deployer.md                              (NEW)
```

### 7.2 Per-project artifacts (created at runtime in the user's project repo)

```
<project>/
├── docs/
│   ├── briefing.md
│   └── phase-reports/
│       ├── phase-01-demo.md
│       ├── phase-02-scaffolding.md
│       └── ...
├── PLAN.md
└── .env / .env.example
```

## 8. Activation flow

1. User types `/project-manager` (or any phrase matching the PM skill's `description`, e.g., "build me a project").
2. PM skill activates in main conversation. Greets user, runs Phase 0 discovery.
3. PM writes `docs/briefing.md`, dispatches `demo-builder` for Phase 1.
4. `demo-builder` returns; PM walks user through clickable mockup; user approves direction.
5. PM dispatches `planner` for Phase 2; `planner` writes `PLAN.md` and scaffolds.
6. PM cycles through backend → backend-test → frontend → frontend-test → hardening → staging deploy → prod deploy, gating on user sign-off between each phase.
7. After Phase M+4, PM does a final summary and points the user to live URLs + observability dashboards.

## 9. Failure modes and mitigations

| Failure mode | Mitigation |
|---|---|
| Subagent returns malformed JSON | PM detects parse failure, surfaces raw output to user, asks user how to proceed. Never auto-retries blindly. |
| Subagent claims `done` but acceptance criteria not met | PM walks user through every criterion before sign-off. User has veto. |
| Subagent goes silent waiting on input | Hard rule: subagents must exit with `needs_input` rather than ask. Reinforced in prompt template. |
| User abandons mid-project, returns later | `PLAN.md` + briefing + per-phase reports = full state. PM re-reads on `/project-manager` invocation and resumes from the next pending phase. |
| Skill ecosystem changes (new skill added) | Subagents check live skill list before non-trivial work, so new skills are picked up without editing subagent files. |
| Phase scope balloons mid-execution | Subagent exits with `blocked` and "scope grew beyond acceptance criteria"; PM and user re-plan into multiple phases. |

## 10. Open questions (resolve before implementation plan)

None at design level. Implementation plan will need to decide:

- Exact wording of each subagent's `description` frontmatter (tuning auto-trigger).
- Whether the PM skill should auto-trigger on phrases like "build me a project" or only on `/project-manager`.
- Whether `deployer`'s staging-vs-prod mode is a runtime arg or two separate subagent files (proposed: one file with arg, but worth re-checking).

## 11. Approvals

- Design approved by user 2026-05-07.
- Implementation plan: pending — to be produced via `superpowers:writing-plans`.
