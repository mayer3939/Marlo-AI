# Marlo AI — Phased Project Orchestration for Claude Code

**Build complete projects from one-line prompts.** Marlo AI is a Claude Code system that orchestrates software delivery across 11 phases, with a Project Manager skill running in your conversation and specialized subagents executing each phase in isolation.

---

## What is Marlo AI?

Marlo AI solves a real problem: asking Claude to "build a SaaS app" either produces:
- An over-eager generator that scaffolds everything at once (usually wrong)
- A chatty assistant that asks every question every time (tedious)

Marlo splits the difference:

**In your conversation:** One **Project Manager skill** runs start-to-finish. It owns discovery (questions about your app, stack, integrations), quality gates (demo approval before building), and sign-off between phases.

**In the background:** Nine **specialized subagents** execute the work in isolation. Each agent handles one phase, exits with a structured report, and never talks to you directly. The PM relays everything.

**Result:** You get a complete, production-ready codebase with clear commit history — all tracked in git, all gated on your approval.

---

## Key Features

| Feature | Why It Matters |
|---------|---|
| **11-phase workflow** | Discovery → Demo → Plan → Backend → Frontend → Hardening → Security Audit → Deploy |
| **Demo gate** | You see a clickable mockup before any real coding starts. No wasted effort on wrong direction. |
| **Test-driven building** | Builders write tests first, implementation second. Security checks run at every phase. |
| **Security-first** | `SECURITY_RULES.md` enforces 17 non-negotiable requirements (secrets, auth, XSS, SQL injection, etc.) across all builders. |
| **AI Security Audit** (new) | Phase M+3 runs a comprehensive 17-category security review before deployment. |
| **Architectural discipline** (new) | L-GEVITY skills guide minimalism, modularity, resilience, and CI/CD reliability. |
| **Session recovery** | Session breaks? PM reads `PLAN.md` and resumes from the next pending phase. |
| **State persistence** | `docs/briefing.md` + `PLAN.md` + phase reports = full audit trail of your project. |

---

## Installation (5 Minutes)

### Prerequisites

- **Claude Code** (CLI, web at claude.ai/code, or IDE extension)
- **Git** (for version control)
- **Bash** (macOS, Linux) or **Git Bash** (Windows)

### Step 1: Clone Marlo AI

```bash
git clone https://github.com/mayer3939/Marlo-AI.git ~/Marlo-AI
cd ~/Marlo-AI
```

### Step 2: Run Installation Script

**Option A: Automated (recommended)**

```bash
bash bin/install.sh
```

The script will:
- Create `~/.claude/skills/` and `~/.claude/agents/` directories
- Copy all 6 skills and 9 agents
- Validate the installation
- Print a success summary

**Option B: Manual Setup**

```bash
# Create directories
mkdir -p ~/.claude/skills
mkdir -p ~/.claude/agents

# Copy skills (6 files)
cp -r skills/project-manager ~/.claude/skills/
cp -r skills/architecture-guidelines ~/.claude/skills/
cp -r skills/ci-cd-reliability-architecture ~/.claude/skills/
cp -r skills/defect-shift-left ~/.claude/skills/
cp -r skills/functionality-complexity-tradeoff ~/.claude/skills/
cp -r skills/structural-simplification ~/.claude/skills/

# Copy agents (9 files)
cp agents/*.md ~/.claude/agents/

# Verify
ls ~/.claude/skills/project-manager/SKILL.md
ls ~/.claude/agents/ | wc -l  # Should show 9
```

### Step 3: Verify Installation

```bash
# Check files exist
test -f ~/.claude/skills/project-manager/SKILL.md && echo "✅ PM skill installed"
test $(ls ~/.claude/agents/*.md 2>/dev/null | wc -l) -eq 9 && echo "✅ All 9 agents installed"

# Test in Claude Code
/project-manager  # Should appear in slash-command suggestions
```

### Step 4: Restart Claude Code

Close and reopen Claude Code (or restart the CLI session). The `/project-manager` command should now be available.

**Troubleshooting?** See [Installation Issues](#troubleshooting) below.

---

## Quick Start (5 Minutes)

### For a New Project

```bash
mkdir my-app && cd my-app && git init
```

Then in Claude Code:

```
/project-manager
```

You'll go through:

1. **Phase 0 — Discovery** (PM asks you directly)
   - What are you building? (e.g., "note-taking app")
   - Who's using it? (e.g., "busy professionals")
   - Core flows? (e.g., "login → create note → search notes")
   - Stack? (e.g., "Next.js + TypeScript + Supabase")
   - Any integrations? (e.g., "Google Drive sync")
   - Compliance needs? (e.g., "GDPR data deletion")

2. **Phase 1 — Demo** (`demo-builder`)
   - You get a local dev server with a clickable mockup
   - **Gate:** You must approve the UI direction before building real code

3. **Phases 2–M+5 — Build & Deploy** (fully automated)
   - PM dispatches each subagent; they execute and report
   - You can pause between phases to review
   - Final result: production deployment with observability

**Total time:** ~3 hours for a simple CRUD app, ~5+ hours for more complex features.

### For Existing Projects (Resume)

If you have a `PLAN.md` file:

```bash
cd /path/to/existing/project
/project-manager
```

PM will read `PLAN.md`, see which phases are done, and resume from the next pending phase.

---

## The 11 Phases Explained

```
Phase 0:  Discovery              ← You answer questions (PM, conversational)
Phase 1:  Demo & Design          ← Clickable mockup (demo-builder)
Phase 2:  Planning & Scaffolding ← PLAN.md + project structure (planner)
─────────────────────────────────── DEMO GATE: Approve direction ───────────
Phase 3..K:   Backend            ← API + database, one milestone at a time
Phase K+1:    Backend Testing    ← Verify all endpoints work
Phase K+2..M: Frontend           ← UI wiring to backend API
Phase M+1:    Frontend Testing   ← Browser walkthrough of all flows
Phase M+2:    Hardening          ← Bug fixes, security audit, dep scan
Phase M+3:    AI Security Audit  ← 17-category comprehensive review (NEW)
─────────────────────────────────── SECURITY GATE: Fix CRITICAL issues ─────
Phase M+4:    Staging Deploy     ← Deploy to staging, manual testing
Phase M+5:    Production Deploy  ← Custom domain, observability, go live
```

### Phase Responsibilities

| Phase | Owner | Output |
|-------|-------|--------|
| 0 | PM (you answer) | `docs/briefing.md` |
| 1 | demo-builder | Clickable Next.js mockup + approval |
| 2 | planner | `PLAN.md`, git scaffold |
| 3..K | backend-builder | API endpoints, database schema |
| K+1 | backend-tester | Verification report |
| K+2..M | frontend-builder | UI wired to backend |
| M+1 | frontend-tester | E2E browser test report |
| M+2 | hardener | Bug fixes, security findings |
| M+3 | security-auditor | Comprehensive audit report (17 categories) |
| M+4 | deployer (staging) | Staging URL, test checklist |
| M+5 | deployer (prod) | Live domain, error tracking, monitoring |

---

## How It Works: The Architecture

```
┌─────────────────────────────────────────┐
│  You (in Claude Code)                   │
│  /project-manager                       │
└────────────────┬────────────────────────┘
                 │
                 ▼
        ┌─────────────────┐
        │  PM Skill       │  Runs in conversation
        │  (SKILL.md)     │  • Phase orchestration
        │                 │  • Discovery questions
        │                 │  • Gate enforcement
        │                 │  • State persistence
        └────────┬────────┘
                 │
        ┌────────┴────────────────────────┐
        │  Phase 1-2    (Demo, Plan)      │
        │  demo-builder, planner          │
        │                                 │
        │  Phase 3-M+1  (Build)           │
        │  backend-*, frontend-*          │
        │                                 │
        │  Phase M+2-3  (Hardening)       │
        │  hardener, security-auditor     │
        │                                 │
        │  Phase M+4-5  (Deploy)          │
        │  deployer (staging, prod)       │
        └─────────────────────────────────┘
                 │
                 ▼
    Each agent exits with JSON:
    { status, report_path, summary }
    (Agent tool + structured contract)
```

**Key insight:** The PM never delegates user-facing questions. Agents never ask you directly. All communication flows through the PM.

---

## Security First

Every line of code must follow [`SECURITY_RULES.md`](SECURITY_RULES.md) — 17 non-negotiable rules:

✅ **No hardcoded secrets** — OIDC/federated identity, no API keys in code  
✅ **Database hardening** — Row-Level Security, parameterized queries  
✅ **Auth discipline** — middleware checks, ownership verification  
✅ **Input validation** — XSS sanitization, CSRF protection  
✅ **Backend resilience** — SSRF prevention, rate limiting, proper error codes  
✅ **Payment safety** — webhook verification, idempotency keys  
✅ **Dependency security** — version pinning, lock files  

**How it works:**
- All builders (backend, frontend, demo) follow `SECURITY_RULES.md` from the start.
- Phase M+2 (hardener) performs a security audit against these rules.
- Phase M+3 (security-auditor) runs a comprehensive AI-powered review across 17 categories.
- Critical issues must be fixed before staging deploy.

---

## Architectural Discipline (L-GEVITY Skills)

Marlo includes five **L-GEVITY engineering skills** that guide clean architecture:

| Skill | Used In | Purpose |
|-------|---------|---------|
| **architecture-guidelines** | Phases 2-M+2 | Minimalism, modularity, resilience, naming |
| **functionality-complexity-tradeoff** | Phase 2 | Decide: BUILD / DEFER / DROP features |
| **structural-simplification** | Phase M+2 | Measure complexity; audit growth |
| **defect-shift-left** | Phases 3-M+2 | Move quality checks left (type system → lint → pre-commit → CI → tests) |
| **ci-cd-reliability-architecture** | Phases M+4-5 | Idempotency, self-contained, zero-downtime, zero-knowledge secrets |

These are optional but strongly recommended. They encode 30+ years of engineering discipline.

See [`docs/L-GEVITY-INTEGRATION.md`](docs/L-GEVITY-INTEGRATION.md) for phase-by-phase guidance.

---

## Project State Files

After running `/project-manager`, your project contains:

```
my-app/
├── docs/
│   ├── briefing.md              ← Your Phase 0 answers (append-only)
│   ├── phase-reports/
│   │   ├── phase-01-demo.md     ← Demo builder output
│   │   ├── phase-02-plan.md     ← Planner output
│   │   ├── phase-03-backend.md  ← Backend milestone 1
│   │   ├── phase-M3-security.md ← Security audit findings
│   │   └── ...
│   └── design.md                ← Reference architecture (symlink)
├── PLAN.md                      ← Your phased project plan (PM updates this)
├── SECURITY_RULES.md            ← Reference (symlink)
├── .git/                        ← All commits tracked
└── [Your actual project code]
```

**Key files:**
- `docs/briefing.md` — Your answers to discovery questions (never overwritten, append-only)
- `PLAN.md` — Current phase plan with acceptance criteria and status (PM updates)
- `docs/phase-reports/phase-NN-*.md` — Each subagent's detailed report

These files let you resume sessions, audit decisions, and understand how your project was built.

---

## Usage Examples

### Start a Fresh Project

```bash
mkdir notes-app && cd notes-app && git init
/project-manager
# → Answers discovery questions
# → Dispatches demo-builder
# → You approve mockup
# → Executes phases 2–M+5 automatically
```

### Resume After Session Break

```bash
cd notes-app
/project-manager
# → Reads PLAN.md
# → Sees phases 1-3 are done
# → Resumes from phase K (backend milestone 2)
```

### Run Specific Phase Manually

If a phase got stuck, PM can re-dispatch it:

```
/project-manager
Phase 4 failed. Let's restart it.
> Restart backend-builder for milestone 2
```

PM will dispatch backend-builder again with the same context.

---

## Troubleshooting

### `/project-manager` command not found

**Check:**
```bash
ls -la ~/.claude/skills/project-manager/SKILL.md
```

**If missing:**
```bash
bash ~/Marlo-AI/bin/install.sh
```

**Then:** Close and fully restart Claude Code.

### Agent says "needs_input"

The agent is waiting for something (API key, account name, decision). PM will tell you what's needed. Provide it in the chat; PM will re-dispatch the agent.

**Example:** "needs_input: GitHub OAuth secret"  
**Your response:** "Here's the secret: xxx"  
**Result:** PM re-dispatches; agent continues.

### Agent is "blocked"

The agent encountered a hard stop (missing file, failed test, syntax error). Check the phase report:

```bash
cat docs/phase-reports/phase-03-backend.md
# Look for: "blocker: ..."
```

Fix the issue, commit, and PM will re-dispatch.

### Backend tests are failing

Phase K+1 (backend-tester) will exit with the failing tests. Check:

```bash
cat docs/phase-reports/phase-04-backend-test.md
```

Either:
1. Fix tests in phase 3 (backend-builder)
2. Or manually fix in your editor and commit
3. Then PM re-dispatches phase K+1

### Missing dependencies or skills

Agents check for `debugging`, `test-driven-development`, `writing-clearly-and-concisely` skills at the start. If missing:

```bash
# In Claude Code
/skills add debugging
/skills add test-driven-development
```

Then re-run the phase.

### Full troubleshooting guide

See **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** for 70+ common issues and solutions.

---

## Documentation

### Getting Started
- **[QUICK_START.md](QUICK_START.md)** — 5-minute walkthrough with a complete example
- **[bin/install.sh](bin/install.sh)** — Automated installation (alternative to manual setup)

### Understanding the System
- **[docs/design.md](docs/design.md)** — Complete architecture specification (all 11 phases, PM logic, subagent contracts)
- **[docs/DECISIONS.md](docs/DECISIONS.md)** — 15 Architecture Decision Records explaining why we built it this way
- **[docs/L-GEVITY-INTEGRATION.md](docs/L-GEVITY-INTEGRATION.md)** — How to use architectural discipline skills in each phase

### Reference
- **[SECURITY_RULES.md](SECURITY_RULES.md)** — 17 non-negotiable security requirements all projects must follow
- **[AI-CHECKLIST.md](AI-CHECKLIST.md)** — Framework for Phase M+3 security audit (17 categories)
- **[docs/l-gevity-reference/](docs/l-gevity-reference/)** — 10 primer documents on architectural discipline

### Troubleshooting & Recovery
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** — 70+ common issues, solutions, debugging techniques
- **[ROLLBACK.md](ROLLBACK.md)** — How to revert phases and recover from mistakes

### Improvement & Feedback
- **[REVIEW_AND_RECOMMENDATIONS.md](REVIEW_AND_RECOMMENDATIONS.md)** — Project review with improvement roadmap
- **[IMPROVEMENTS_COMPLETED.md](IMPROVEMENTS_COMPLETED.md)** — Summary of enhancements made in recent session

---

## Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| PM Skill | ✅ Complete | Full orchestration, state recovery, gate enforcement |
| Demo Builder (Phase 1) | ✅ Complete | Next.js mockup with approval gate |
| Planner (Phase 2) | ✅ Complete | PLAN.md generation + project scaffold |
| Backend Builder (Phases 3..K) | ✅ Complete | TDD-driven, test-first API development |
| Backend Tester (Phase K+1) | ✅ Complete | Endpoint verification, database integrity |
| Frontend Builder (Phases K+2..M) | ✅ Complete | React component wiring to real backend |
| Frontend Tester (Phase M+1) | ✅ Complete | E2E browser walkthrough of all flows |
| Hardener (Phase M+2) | ✅ Complete | Bug fixing, security audit, dep scan |
| Security Auditor (Phase M+3) | ✅ Complete | AI-powered audit (17 categories) |
| Deployer (Phases M+4-5) | ✅ Complete | Staging + production deployment with observability |
| Code Reviewer (Optional) | ✅ Complete | Independent security-focused code review |
| L-GEVITY Skills Integration | ✅ Complete | Architecture, CI/CD, defect shift-left patterns |
| SECURITY_RULES.md | ✅ Complete | 17 non-negotiable requirements, all phases |

---

## Requirements & Known Limitations

### What You Need
- **Claude Code** (CLI, web, or IDE extension — not pure API)
- **Git** (for version control)
- **Node.js 18+** (for demo-builder and frontend)
- **Python 3.11+** (optional, for Python backends)

### Skill Dependencies
These Claude Code skills should be installed for best results:

```bash
/skills add test-driven-development
/skills add debugging
/skills add writing-clearly-and-concisely
```

(Optional but recommended.)

### Tested Stacks
- ✅ **Next.js 15+ + TypeScript + Supabase** (primary)
- ✅ **Python 3.11+ + Flask + PostgreSQL** (supported)
- ⚠️ **Rails, Django, Vue** (untested, but should work; feedback welcome)

### Known Limitations
- **Single-user per project** — not built for concurrent team workflows
- **Cloud-first** — assumes deployment to Vercel, Fly, Railway, or similar
- **Interactive gates only** — demo, staging, and prod approvals require a human
- **Not a replacement for `/phased-project-workflow`** — Marlo runs on top of that skill

---

## Architecture Overview

Marlo is built on three principles:

1. **Separation of concerns:** PM handles conversation + orchestration. Agents handle execution.
2. **Structured contracts:** Every agent exits with JSON the PM parses. No free-form output.
3. **State persistence:** PLAN.md + phase reports let you resume sessions and audit decisions.

For full architecture details, see **[docs/design.md](docs/design.md)**.

---

## License

MIT

---

## Questions?

- 📖 **Getting started?** → [QUICK_START.md](QUICK_START.md)
- 🔧 **Troubleshooting?** → [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- 🏗️ **Architecture questions?** → [docs/design.md](docs/design.md)
- 🔒 **Security details?** → [SECURITY_RULES.md](SECURITY_RULES.md)
- 💡 **Improvements?** → [REVIEW_AND_RECOMMENDATIONS.md](REVIEW_AND_RECOMMENDATIONS.md)

---

**Last updated:** May 7, 2026  
**Version:** 1.0 with L-GEVITY integration  
**Repository:** https://github.com/mayer3939/Marlo-AI
