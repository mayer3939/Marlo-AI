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

### Step 1: Clone Marlo AI

```bash
git clone https://github.com/mayer3939/Marlo-AI.git ~/Marlo-AI
cd ~/Marlo-AI
```

### Step 2: Copy to Claude Code Configuration

Copy the skill and agents to your Claude Code config directory:

```bash
# Create directories if they don't exist
mkdir -p ~/.claude/skills/project-manager
mkdir -p ~/.claude/agents
mkdir -p ~/.claude/bin

# Copy files
cp skills/project-manager/SKILL.md ~/.claude/skills/project-manager/
cp agents/*.md ~/.claude/agents/
cp bin/check-frontmatter.sh ~/.claude/bin/
chmod +x ~/.claude/bin/check-frontmatter.sh
```

### Step 3: Verify Installation

```bash
# Check if files were copied
ls -la ~/.claude/skills/project-manager/SKILL.md
ls -la ~/.claude/agents/ | grep -c "\.md"  # Should show 8

# Validate frontmatter
~/.claude/bin/check-frontmatter.sh ~/.claude/skills/project-manager/SKILL.md
```

### Step 4: Restart Claude Code

- **Web/Desktop:** Close and reopen Claude Code
- **CLI:** Run `/project-manager` in any working directory — it should appear in the slash-command list

If `/project-manager` doesn't appear, restart your Claude Code session completely.

---

## Quick Start (5-Minute Example)

### For New Projects

1. **Create a project directory:**
   ```bash
   mkdir my-saas-app && cd my-saas-app
   git init
   ```

2. **Start the project manager:**
   ```
   /project-manager
   ```

3. **Answer discovery questions** (Phase 0):
   - Persona: Solo developer building a note-taking app
   - Core flow: Login → Dashboard → Create/Edit/Delete notes
   - Stack: Next.js + TypeScript + Supabase
   - Integrations: None
   - Compliance: GDPR (data deletion)
   - Success metric: Deploy to production in 1 week

4. **Approve the clickable demo** (Phase 1):
   - PM dispatches `demo-builder`
   - You get a local dev server with mock screens
   - You approve: "Looks good!" to proceed

5. **Watch the phases execute** (Phases 2–M+4):
   - Planner: Creates `PLAN.md` with all phases
   - Backend-builder: Builds API + DB schema (test-driven)
   - Backend-tester: Verifies all endpoints work
   - Frontend-builder: Wires real UI to backend
   - Frontend-tester: Walks every user flow in browser
   - Hardener: Fixes bugs, audits security, runs dep scan
   - Deployer: Deploys to staging → you test → deploys to production

6. **Your project is ready:**
   - Real codebase on disk with all commits
   - `docs/briefing.md` — your answers
   - `PLAN.md` — phase-by-phase breakdown
   - `docs/phase-reports/` — detailed work per phase
   - App deployed to production

**Total time:** ~3 hours for a simple CRUD app

### For Existing Projects (Resume)

1. **Navigate to your project root** (where `PLAN.md` exists)
2. **Run in Claude Code:**
   ```
   /project-manager
   ```
3. **PM reads PLAN.md** and resumes from the next pending phase

---

## Implementation Status

| Component | Status | Version | Notes |
|-----------|--------|---------|-------|
| PM Skill | ✅ Complete | 1.0 | Fully functional, tested |
| Demo Builder | ✅ Complete | 1.0 | Builds clickable mockup |
| Planner | ✅ Complete | 1.0 | Scaffolds repo + PLAN.md |
| Backend Builder | ✅ Complete | 1.0 | TDD + security-first |
| Backend Tester | ✅ Complete | 1.0 | End-to-end API verify |
| Frontend Builder | ✅ Complete | 1.0 | Wires real backend |
| Frontend Tester | ✅ Complete | 1.0 | Browser walkthrough |
| Hardener | ✅ Complete | 1.0 | Bug fix + security audit |
| Deployer | ✅ Complete | 1.0 | Staging + production |
| SECURITY_RULES.md | ✅ Complete | 1.0 | Enforced all phases |

### Known Limitations

- **Requires Claude Code** — CLI, web, or IDE extension; not pure API
- **Skill ecosystem** — needs `debugging`, `test-driven-development`, `writing-clearly-and-concisely` in your skill list
- **Tested stacks:**
  - ✅ Next.js 15+ + TypeScript + Supabase
  - ✅ Python 3.11+ Flask + PostgreSQL
  - ⚠️ Rails, Django, Vue — untested (feedback welcome)
- **Cloud-first** — assumes cloud deployment (Vercel, Fly, Railway); local-only projects need adaptation
- **Single user** — designed for one person or small team per project; no concurrent team workflows yet

---

## Project State Files

After you run `/project-manager`, you'll have:

- **`docs/briefing.md`** — Phase 0 discovery answers (append-only; never overwritten)
- **`PLAN.md`** — Phased plan with acceptance criteria + phase status
- **`docs/phase-reports/phase-NN-*.md`** — Detailed output from each phase
- **`.git/`** — All work committed with clear messages

Example directory after Phase 1:

```
my-saas-app/
├── docs/
│   ├── briefing.md              (your discovery answers)
│   └── phase-reports/
│       └── phase-01-demo.md     (demo builder output + preview URL)
├── PLAN.md                      (PM-maintained phase plan)
└── .git/                        (all commits tracked)
```

## Use

In any working directory:

```
/project-manager
```

The PM will run Phase 0 (discovery: persona, core flow, cloud, integrations, compliance, stack, success metric), save your answers to `docs/briefing.md` in your project, and dispatch `demo-builder` for Phase 1. After you approve the clickable demo, it walks through the rest of the phases, gating on your "approved" between each.

## Security

All code must follow [`SECURITY_RULES.md`](SECURITY_RULES.md) — a comprehensive set of non-negotiable security requirements covering:

- **Secrets** — no API keys, credentials, or tokens in code
- **Database** — Row Level Security, no unsafe deserialization
- **Authentication** — middleware checks, ownership verification, correct status codes
- **Input/Output** — parameterized queries, XSS sanitization, server-side validation
- **SSRF Prevention** — IP range blocking for user-provided URLs
- **Security Headers** — CSP, HSTS, X-Frame-Options, etc.
- **CORS** — no wildcards with credentials
- **Rate Limiting** — auth endpoints protected
- **Payments** — webhook verification and idempotency
- **Error Handling** — no stack trace leaks
- **Password Hashing** — bcrypt/Argon2/scrypt only
- **Dependencies** — version pinning and lock files

**All builders** (backend, frontend, demo) follow these rules from the start. **Phase M+2 (hardener)** performs a complete audit against all rules before staging deploy.

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

## Documentation & Resources

### Getting Started
- **[QUICK_START.md](QUICK_START.md)** — 5-minute walkthrough (fastest way to get started)
- **[bin/install.sh](bin/install.sh)** — Automated installation script (alternative to manual copy)

### Understanding the System
- **[docs/design.md](docs/design.md)** — Full architecture specification (all 10 phases, PM responsibilities, subagent contracts)
- **[docs/plan.md](docs/plan.md)** — Implementation plan (how Marlo itself was built)
- **[docs/DECISIONS.md](docs/DECISIONS.md)** — Architecture decisions (rationale for key design choices)

### For Improvement & Feedback
- **[REVIEW_AND_RECOMMENDATIONS.md](REVIEW_AND_RECOMMENDATIONS.md)** — Project review with recommendations for improvements
- **[SECURITY_RULES.md](SECURITY_RULES.md)** — Non-negotiable security requirements all projects must follow

### Troubleshooting & Rollback
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** — Common issues, solutions, and debugging tips
- **[ROLLBACK.md](ROLLBACK.md)** — How to revert phases and recover from mistakes

## License

MIT
