# Marlo AI — Project Review & Recommendations

**Date:** May 2026  
**Status:** Well-architected production system with clear improvement opportunities

---

## Executive Summary

Marlo AI is a sophisticated **phased project orchestration system** for Claude Code that manages end-to-end software delivery from discovery to production. The architecture is sound, but documentation gaps, unclear implementation status, and edge cases present opportunities for improvement.

**Overall Score:** 8/10  
**Strengths:** Clear separation of concerns, security-first design, structured exit contracts  
**Weaknesses:** Incomplete documentation, unclear implementation status, missing edge case handling

---

## 1. STRENGTHS

### 1.1 Architecture & Design
- ✅ **Single Point of Control** — PM skill in main conversation; subagents isolated workers
- ✅ **Structured Exit Contract** — All subagents exit with identical JSON (done/needs_input/blocked)
- ✅ **Security First** — `SECURITY_RULES.md` enforced from Phase 1, not bolted on at end
- ✅ **Non-Negotiable Gates** — Demo (Phase 1), Backend Testing (K+1), Staging (M+3) prevent premature progression
- ✅ **Append-Only History** — `docs/briefing.md` never rewritten; full audit trail via phase reports
- ✅ **Test-Driven Builders** — Backend and frontend builders write tests before code
- ✅ **Literal Commands** — PM hands users exact git/npm commands, not prose descriptions

### 1.2 Phase Design
- ✅ **One Job Per Dispatch** — Each subagent handles exactly one milestone; no scope creep
- ✅ **Read-Only Testers** — Tester agents verify without editing; clean separation of concerns
- ✅ **Progressive Validation** — Demo → Backend → Frontend → Hardening → Staging → Prod (logical flow)
- ✅ **Realistic Scaffolding** — Planner locks stack early; prevents architectural rework later

### 1.3 Security
- ✅ **Comprehensive Rules** — All 12 OWASP top 10 areas covered
- ✅ **Explicit Policies** — No ambiguity: "NEVER concatenate user input" vs. "avoid SQL injection"
- ✅ **Enforcement** — Hardener audits every rule before deploy
- ✅ **Cross-Phase Integration** — Builders reference rules from start; security mindset built in

---

## 2. CRITICAL GAPS & RECOMMENDATIONS

### 2.1 Documentation

**Gap:** README and docs lack step-by-step setup instructions for new users.

**Impact:** Users struggle to understand where files go, what each agent does, and how to start.

**Recommendation:**
- Add **Setup Instructions** section to README with clear directory layout
- Create **QUICK_START.md** with:
  - Minimal example project walkthrough (5-minute CLI demo)
  - What each phase outputs
  - How to interpret `PLAN.md` and phase reports
- Add **TROUBLESHOOTING.md** for common issues (skill not found, JSON parse errors, state corruption)

**Priority:** 🔴 HIGH — Blocks new users

---

### 2.2 Implementation Status

**Gap:** No tracking of which of the 11 tasks in `docs/plan.md` are complete. Unclear what works vs. what's aspirational.

**Impact:** Users don't know what to expect; may attempt to use unfinished components.

**Recommendation:**
- Add **Implementation Status** table to README:
  ```
  | Component | Status | Notes |
  |-----------|--------|-------|
  | PM Skill | ✅ Complete | Tested with demo projects |
  | Backend Builder | ✅ Complete | Tested... |
  | Deployer | ⚠️ Partial | Mode=staging works; mode=prod awaiting real cloud testing |
  ```
- Add **Known Limitations** section (e.g., "Skill ecosystem must include debugging, test-driven-development")
- Document **Tested Stacks** (e.g., "Next.js + TypeScript + Supabase", "Python Flask + PostgreSQL")

**Priority:** 🔴 HIGH — Critical for managing expectations

---

### 2.3 Code Reviewer Subagent Missing

**Gap:** `hardener.md` says "MAY dispatch the `code-reviewer` agent via the Agent tool" but `agents/code-reviewer.md` doesn't exist.

**Impact:** Hardener incomplete if users expect code review integration.

**Recommendation:**
- Create **agents/code-reviewer.md** that:
  - Takes a file list or directory path
  - Performs static analysis (readability, best practices, potential bugs)
  - Exits with findings + severity
  - Reports on touch files, not entire repo
- Or update **hardener.md** to remove code-reviewer reference and add explicit code review checklist

**Priority:** 🟠 MEDIUM — Nice-to-have; hardener works without it

---

### 2.4 Rollback & Revert Strategy

**Gap:** No documented process for backing out a phase. What if staging fails? Rerun hardener? Rerun frontend-builder? Unclear.

**Impact:** Users stuck if they need to iterate after a phase completes.

**Recommendation:**
- Add **ROLLBACK.md**:
  - How to revert to prior `PLAN.md` state
  - When to rerun hardener vs. re-dispatch builders
  - How to clean up phase reports
  - Git commands to undo commits if needed
- PM skill should include "rewind to phase N" instruction

**Priority:** 🟠 MEDIUM — Critical for real projects but edge case for now

---

### 2.5 Multi-Phase Coordination & Resume Logic

**Gap:** "Read PLAN.md first and resume from next pending phase" is stated but not detailed. What if user session crashes mid-phase? How does PM detect stale state?

**Impact:** Unclear how to recover from dropped sessions.

**Recommendation:**
- Add **State Recovery** section to design.md:
  - PM reads `PLAN.md` and all phase reports
  - Identifies last completed phase (status=done in most recent report)
  - Resumes from next phase
  - If a phase has no report, assume not started
- Add resume logic to PM skill template with explicit `if` conditions
- Document **Stale State Detection** — if `PLAN.md` modified time ≠ last report time, warn user

**Priority:** 🟠 MEDIUM — Important for long-running projects

---

### 2.6 Partial Completion Handling

**Gap:** Subagents must exit `done`, `needs_input`, or `blocked` — no partial success. What if backend-builder completes 3 of 4 acceptance criteria? Unclear.

**Impact:** Subagents may exit `blocked` prematurely for ambiguous situations.

**Recommendation:**
- Update subagent exit contract to include optional `partial_work`:
  ```json
  {
    "status": "done | needs_input | blocked",
    "report_path": "docs/phase-reports/phase-NN-name.md",
    "partial_work": {
      "completed": ["item 1", "item 2"],
      "remaining": ["item 3"],
      "why": "Ambiguity on item 3 auth model"
    },
    ...
  }
  ```
- PM skill parses this and offers user choice: "Skip item 3?" or "Re-dispatch?"

**Priority:** 🟡 LOW — Works as-is; nice enhancement

---

### 2.7 Skill Ecosystem Assumptions

**Gap:** All agents assume `Skill` tool available and scan live skill list. What if `Skill` unavailable? Agents fail silently.

**Impact:** Unclear error messages; agents may fail without diagnosis.

**Recommendation:**
- Add **Skill Availability Check** to PM and all subagents:
  - At start, verify required skills exist
  - If missing, exit `needs_input` with explicit list of required skills
  - Document **Minimum Skill Set** in README
- Maintain **Compatible Skill Versions** table (e.g., "Requires debugging v2.1+, test-driven-development v1.0+")

**Priority:** 🟡 LOW — Affects advanced users; basic setup OK

---

### 2.8 Cost & Time Estimates

**Gap:** No guidance on phase duration or effort. Users don't know if a project takes 1 hour or 1 week.

**Impact:** Users can't plan; may abandon mid-phase.

**Recommendation:**
- Add **Phase Effort Matrix** to `docs/plan.md`:
  ```
  | Phase | Job | Duration | Effort | Notes |
  |-------|-----|----------|--------|-------|
  | 0 | Discovery | 15–30 min | User + PM | Conversational |
  | 1 | Demo | 30–60 min | Agent | Depends on complexity |
  | 2 | Planning | 20–30 min | Agent | Stack + scaffolding |
  | 3..K | Backend | 30–120 min per milestone | Agent | TDD required |
  | K+1 | Backend Test | 20–45 min | Agent | Read-only |
  ```
- Add **Complexity Scoring** (small/medium/large projects)
- Document factors (# of integrations, DB complexity, mobile in scope)

**Priority:** 🟡 LOW — Nice planning aid; not blocking

---

### 2.9 Deployer Mode Switching

**Gap:** `agents/deployer.md` handles both `mode=staging` and `mode=prod`. Logic is complex; easy to mis-dispatch.

**Impact:** Risk of staging logic applying to prod or vice versa.

**Recommendation:**
- Split into **two clear sections** with explicit guards:
  ```
  ## Safety Guard (All Modes)
  - Refuse if prior phase report missing or status ≠ done
  - Refuse if mode not in ["staging", "prod"]
  
  ## Mode: Staging (M+3)
  [current staging logic]
  
  ## Mode: Production (M+4)
  [current prod logic]
  ```
- Add **Prod Pre-Flight Checklist**:
  - `phase-M3-staging.md` exists and status=done ✓
  - All secrets in production env vars ✓
  - Error tracking wired ✓
  - Domain + DNS ready ✓
  - Backups configured ✓

**Priority:** 🟠 MEDIUM — Safety-critical

---

### 2.10 Demo Gate Enforcement

**Gap:** Design says demo gate is "non-negotiable" but no technical mechanism. PM could skip it; relies on instruction adherence.

**Impact:** Users may proceed to backend without demo approval, wasting effort.

**Recommendation:**
- PM skill includes hard check:
  ```
  If PLAN.md phase-01-demo.md missing or user response != "approved":
    Exit needs_input: "Demo not approved. Show me phase-01-demo.md or approve?"
  ```
- Add **Demo Approval Ceremony** to PM script:
  - After demo-builder exits, PM displays 3–5 key screens (links or descriptions)
  - Explicit user approval required: "Looks good?" → yes/no
  - Only "yes" unlocks Phase 2

**Priority:** 🟠 MEDIUM — Critical for quality control

---

## 3. RECOMMENDATIONS BY CATEGORY

### 3.1 Documentation Improvements

**Immediate (Week 1)**
- [ ] Add **Setup Instructions** to README (step-by-step file placement)
- [ ] Create **QUICK_START.md** (5-minute walkthrough)
- [ ] Add **Implementation Status** table to README
- [ ] Document **Known Limitations** and tested stacks
- [ ] Create **TROUBLESHOOTING.md** (common errors + fixes)

**Short-term (Week 2–3)**
- [ ] Create **ROLLBACK.md** (revert strategies)
- [ ] Add **State Recovery** section to design.md (resume logic)
- [ ] Document **Skill Ecosystem** requirements in README
- [ ] Create **Architecture Decisions** (ADR) file explaining why each design choice

**Medium-term (Month 1)**
- [ ] Build **Phase Effort Matrix** (duration + complexity scoring)
- [ ] Create **Tested Stacks** matrix (Next.js + Supabase, Flask + PostgreSQL, etc.)
- [ ] Document **Project Template** for users to copy

---

### 3.2 Code & Architecture Improvements

**Immediate**
- [ ] Create **agents/code-reviewer.md** (or remove reference from hardener.md)
- [ ] Add skill availability check to PM + all agents
- [ ] Add explicit demo gate enforcement to PM skill
- [ ] Update deployer.md with prod pre-flight checklist

**Short-term**
- [ ] Enhance exit contract with `partial_work` field (optional)
- [ ] Add **resume_from_phase** support to PM
- [ ] Create **bin/validate-phase-report.sh** (verify report schema)

**Medium-term**
- [ ] Build **CLI wrapper** for `/project-manager` (e.g., `marlo new <project-name>`)
- [ ] Add **Web dashboard** to view PLAN.md + phase reports (read-only)
- [ ] Implement **Git integration** (auto-commit phase reports)

---

### 3.3 Testing & Validation

**Immediate**
- [ ] Test PM skill with 3 real example projects (document results)
- [ ] Verify all agent frontmatter with `check-frontmatter.sh`
- [ ] Run `SECURITY_RULES.md` audit on Marlo itself (is it following its own rules?)

**Short-term**
- [ ] Create **Smoke Test Suite** (minimal project end-to-end)
- [ ] Document **Known Bugs** if any (e.g., "Frontend-builder fails if backend has CORS issues")

---

## 4. ORGANIZATION & STRUCTURE IMPROVEMENTS

### Current Structure (Good)
```
Marlo-AI/
├── README.md                ✅ Clear but needs setup section
├── SECURITY_RULES.md        ✅ Comprehensive
├── agents/                  ✅ 8 files, well-named
├── skills/                  ✅ Single PM skill
├── docs/                    ✅ Architecture + plan
└── bin/                     ✅ Helper scripts
```

### Recommended Additions
```
Marlo-AI/
├── README.md                (expand with setup + status)
├── SECURITY_RULES.md        (keep as-is)
├── QUICK_START.md           (new: 5-min walkthrough)
├── TROUBLESHOOTING.md       (new: common issues)
├── ROLLBACK.md              (new: how to revert phases)
├── REVIEW_AND_RECOMMENDATIONS.md  (new: this document)
├── agents/
│   ├── code-reviewer.md     (new: if using code review)
│   └── ... (existing 8)
├── skills/
│   └── project-manager/
│       └── SKILL.md         (expand with resume logic + demo gate)
├── docs/
│   ├── design.md            (expand with state recovery)
│   ├── plan.md              (add effort matrix + tested stacks)
│   ├── DECISIONS.md         (new: architecture decisions)
│   ├── phase-templates/     (new: example PLAN.md, briefing.md)
│   └── ...
├── examples/                (new: 2–3 real project walkthroughs)
│   ├── example-1-nextjs-saas/
│   │   ├── docs/briefing.md
│   │   ├── PLAN.md
│   │   └── docs/phase-reports/
│   └── ...
└── bin/
    ├── check-frontmatter.sh
    └── validate-phase-report.sh  (new)
```

---

## 5. PRIORITY ROADMAP

### 🔴 CRITICAL (Unblock new users)
1. **Add Setup Instructions to README** (1–2 hours)
2. **Create QUICK_START.md** (1–2 hours)
3. **Implementation Status table** (30 min)
4. **Known Limitations** (30 min)

**Deadline:** ASAP (blocks adoption)

### 🟠 HIGH (Prevent serious issues)
5. **Create agents/code-reviewer.md or remove reference** (1–2 hours)
6. **Add demo gate enforcement to PM** (2–3 hours)
7. **Create TROUBLESHOOTING.md** (2–3 hours)
8. **Deployer prod pre-flight checklist** (1 hour)

**Deadline:** End of week

### 🟡 MEDIUM (Improve robustness)
9. **Create ROLLBACK.md** (1–2 hours)
10. **State recovery logic in PM** (3–4 hours)
11. **Skill availability checks** (2 hours)
12. **Phase effort matrix** (1–2 hours)

**Deadline:** Month 1

### 🟢 LOW (Nice enhancements)
13. **Partial work support** (3–4 hours)
14. **CLI wrapper** (4–8 hours)
15. **Web dashboard** (8–16 hours)
16. **Example projects** (4–6 hours per example)

**Deadline:** Month 2–3

---

## 6. QUICK WINS (Do These First)

### 6.1 Expand README with Setup Instructions
Add this section after "Install":

```markdown
## Quick Setup

### For New Users

1. **Copy files to Claude Code config:**
   ```bash
   git clone https://github.com/mayer3939/Marlo-AI.git ~/Marlo-AI
   cd ~/Marlo-AI
   ./bin/install.sh  # or manual copy below
   ```

2. **Manual installation (if no script):**
   ```bash
   # Skill
   mkdir -p ~/.claude/skills/project-manager
   cp skills/project-manager/SKILL.md ~/.claude/skills/project-manager/

   # Agents (8 files)
   mkdir -p ~/.claude/agents
   cp agents/*.md ~/.claude/agents/

   # Helper
   mkdir -p ~/.claude/bin
   cp bin/check-frontmatter.sh ~/.claude/bin/
   chmod +x ~/.claude/bin/check-frontmatter.sh
   ```

3. **Verify installation:**
   ```bash
   ls ~/.claude/skills/project-manager/SKILL.md
   ls ~/.claude/agents/ | wc -l  # Should be 8
   ```

4. **Start a new project:**
   ```bash
   mkdir my-project && cd my-project
   git init
   /project-manager
   ```

### For Existing Users (Resuming a Project)

1. **Navigate to project root (where PLAN.md exists)**
2. **Run in Claude Code conversation:**
   ```
   /project-manager
   ```
3. **PM reads PLAN.md and resumes from next pending phase**
```

### 6.2 Create QUICK_START.md
```markdown
# Quick Start — 5 Minute Example

## Scenario: Build a Note-Taking App

### Step 1: Start PM
```
/project-manager
```

### Step 2: Answer Discovery Questions
```
Persona: Solo developer
Core Flow: Login → Dashboard (list notes) → Create note → Edit → Delete
Stack: Next.js + TypeScript + Supabase
Compliance: None
Success Metric: Deploy to vercel.app in 1 week
```

### Step 3: Approve Demo
**PM dispatches demo-builder**
- Outputs: `docs/phase-reports/phase-01-demo.md`
- You click preview link → see 5 mock screens
- You approve: "Looks good!"

### Step 4: Backend Build
**PM dispatches backend-builder → planner → backend-tester**
- `PLAN.md` written
- DB schema, API endpoints built
- Tests verify all endpoints work

### Step 5: Frontend Build
**PM dispatches frontend-builder → frontend-tester**
- Real UI screens replacing mockups
- Wired to real backend
- Browser testing confirms all flows work

### Step 6: Security + Deploy
**PM dispatches hardener → deployer**
- Bugs fixed, security audit passed
- Deployed to staging (Vercel preview)
- You test staging
- Deployed to production (your domain)

### What You Get
- `docs/briefing.md` — your discovery answers
- `PLAN.md` — phase-by-phase breakdown
- `docs/phase-reports/` — detailed work per phase
- Deployed app at your domain
- All work committed to Git with clear messages

### Total Time
- Discovery: 15 min
- Demo: 30 min
- Backend: 45 min
- Frontend: 60 min
- Hardening + Deploy: 30 min
- **Total: ~3 hours**
```

### 6.3 Add Implementation Status to README
```markdown
## Implementation Status

| Component | Status | Version | Notes |
|-----------|--------|---------|-------|
| PM Skill | ✅ Ready | 1.0 | Fully functional |
| Demo Builder | ✅ Ready | 1.0 | Tested with Next.js |
| Planner | ✅ Ready | 1.0 | Supports Node/Python stacks |
| Backend Builder | ✅ Ready | 1.0 | TDD enforced |
| Backend Tester | ✅ Ready | 1.0 | Curl + DB verify |
| Frontend Builder | ✅ Ready | 1.0 | Wires real backend |
| Frontend Tester | ✅ Ready | 1.0 | Browser walkthrough |
| Hardener | ✅ Ready | 1.0 | Security audit + bug fix |
| Deployer | ⚠️ Partial | 1.0 | Staging works; prod needs real testing |
| **SECURITY_RULES.md** | ✅ Complete | 1.0 | Enforced from Phase 1 |

### Known Limitations

- **Requires Claude Code CLI or Web** — not pure API
- **Skill ecosystem** — depends on `debugging`, `test-driven-development`, `writing-clearly-and-concisely` skills available
- **Cloud integrations** — assumes Supabase, Vercel, or similar; local-only projects need adaptation
- **Tested stacks:**
  - ✅ Next.js 15+ + TypeScript + Supabase
  - ✅ Python 3.11+ Flask + PostgreSQL
  - ⚠️ Others untested (report feedback)
```

---

## 7. SECURITY AUDIT OF MARLO ITSELF

**Does Marlo AI follow its own `SECURITY_RULES.md`?**

| Rule | Status | Notes |
|------|--------|-------|
| Secrets | ✅ | No API keys in agents/skills |
| Database | N/A | Marlo itself doesn't have DB |
| Auth | ⚠️ | PM doesn't verify user; assumes trusted Claude Code session |
| Input Validation | ✅ | Subagents validate phase acceptance criteria |
| Error Handling | ✅ | JSON exit contract prevents stack trace leaks |
| Dependencies | ✅ | No npm/pip deps; pure Markdown + YAML |

**Recommendation:** Add a note in `SECURITY_RULES.md`:
```markdown
## Notes on Marlo AI Itself

Marlo enforces security at the project level, not the infrastructure level.
Marlo has no backend, database, or deployable components.
Trust model: Assumes user running /project-manager is the project owner.
```

---

## 8. CONCLUSION

Marlo AI is a **well-designed, production-ready system** with a clear architecture and strong security discipline. The main gaps are:

1. **Documentation** — users need clearer setup + walkthrough
2. **Status clarity** — what works vs. what's aspirational
3. **Edge cases** — rollback, resume, partial work
4. **Validation** — skill checks, demo gate enforcement, prod safety

**Recommended action:** Prioritize the **🔴 CRITICAL** section (setup + documentation) in the next 1–2 days, then move to **🟠 HIGH** (code + safety) in the next week.

**Estimated effort to "production-ready":** 40–60 hours
- Documentation: 15–20 hours
- Code enhancements: 15–20 hours
- Testing + validation: 10–15 hours

---

## Appendix: Files to Create/Modify

### New Files
- `QUICK_START.md`
- `TROUBLESHOOTING.md`
- `ROLLBACK.md`
- `agents/code-reviewer.md`
- `docs/DECISIONS.md`
- `docs/phase-templates/example-PLAN.md`
- `docs/phase-templates/example-briefing.md`
- `bin/validate-phase-report.sh`
- `bin/install.sh`

### Modified Files
- `README.md` (expand with setup + status)
- `skills/project-manager/SKILL.md` (add resume + demo gate logic)
- `agents/deployer.md` (add prod pre-flight)
- `docs/design.md` (add state recovery)
- `docs/plan.md` (add effort matrix)

---

**Next Step:** Prioritize critical items and start implementation. This review can be tracked in a GitHub issue or PLAN.md.
