# Architecture Decisions (ADR)

Record of key design decisions and their rationales.

---

## ADR-001: PM Skill in Main Conversation (Not as Subagent)

**Decision:** Project Manager runs directly in the user's main conversation thread, not dispatched as a subagent.

**Rationale:**
- PM needs continuous context (discovery answers, user approvals, state management)
- User needs immediate feedback ("next step is X, approve?") — not isolated agent exit
- PM orchestrates the entire workflow; running in conversation keeps user in the loop
- Subagents are fire-and-forget workers; PM is the conductor

**Consequence:**
- PM cost higher (runs for duration of entire project)
- PM skill must be highly reliable (bugs block entire pipeline)
- PM must track state carefully (PLAN.md is the source of truth)

**Alternatives Considered:**
- ❌ PM as subagent too — loses real-time feedback loop
- ❌ CLI wrapper around Agent tool — limits interactivity
- ✅ PM in main conversation — best UX and reliability

---

## ADR-002: Structured JSON Exit Contract

**Decision:** Every subagent exits with identical JSON structure, not free-form text.

```json
{
  "status": "done | needs_input | blocked",
  "report_path": "docs/phase-reports/phase-NN-name.md",
  "needs_input": [...],
  "blocker": "",
  "summary": "..."
}
```

**Rationale:**
- PM must parse responses programmatically (can't read prose)
- Enforces discipline: agents think in terms of outcomes, not process
- Prevents ambiguous exits ("mostly done" — not an option)
- Three states (done/needs_input/blocked) map to PM actions:
  - `done` → move to next phase
  - `needs_input` → ask user, re-dispatch
  - `blocked` → halt, surface issue to user

**Consequence:**
- Agents must exit with JSON; can't chat
- Reduces flexibility (no "almost done" states)
- Clear error messages when JSON malformed

**Alternatives Considered:**
- ❌ Free-form text exits — PM can't reliably parse
- ❌ Five-state contract (add "partial" state) — encourages half-baked work
- ✅ Three-state JSON — clean, parseable, disciplined

---

## ADR-003: Append-Only Briefing (Never Rewritten)

**Decision:** `docs/briefing.md` is append-only. New discovery adds a `Revision` block; never overwrites.

**Rationale:**
- Audit trail of decisions and changes
- Prevents accidental data loss (old answers still visible)
- User can see evolution of project (Phase 0, then Phase N revisions)
- Git history backs up every revision

**Consequence:**
- Briefing can get long (20+ pages for long projects)
- Requires manual organization (Revision blocks)
- Can't use briefing for "current state only" (read Revision N)

**Alternatives Considered:**
- ❌ Overwrite briefing each discovery → lose history
- ✅ Append-only with Revision blocks → full audit trail
- ❌ Separate files per revision → clutters docs/ directory

---

## ADR-004: One Job Per Dispatch

**Decision:** Each subagent handles exactly one milestone. Never bundles two phases into one dispatch.

**Rationale:**
- Clear responsibility (agent can focus on one job)
- Easier to rollback (revert one phase, not two)
- Easier to parallelize later (if needed)
- Forces clear acceptance criteria (can't hide ambiguity across two phases)

**Consequence:**
- More agent dispatches for large projects
- Longer overall timeline (more context-switching)
- Cleaner phase reports (each focused on one milestone)

**Alternatives Considered:**
- ❌ Bundle multiple milestones per agent → complex, hard to debug
- ✅ One job per dispatch → clean separation of concerns
- ❌ Variable job size per agent → unpredictable exits

---

## ADR-005: Test-Driven Building (TDD Required)

**Decision:** backend-builder and frontend-builder MUST write tests before code.

**Rationale:**
- Reduces bugs (test failure catches issues immediately)
- Refactoring safe (tests verify behavior is preserved)
- Documents intended behavior (test assertions = spec)
- Supports confidence in hardening phase (tests are there for hardener to verify)

**Consequence:**
- Slower initial build (write test, then code, then verify)
- Requires test infrastructure (Jest, pytest, etc.)
- Tests are permanent (team maintains them)

**Alternatives Considered:**
- ❌ No tests → risks bugs, hard to refactor
- ❌ Tests after code → tests become documentation, not design
- ✅ TDD → tests drive design and catch bugs early

---

## ADR-006: Read-Only Testers

**Decision:** backend-tester and frontend-tester are read-only. They verify but don't fix.

**Rationale:**
- Separation of concerns (builders build; testers verify)
- Prevents scope creep (tester doesn't accidentally fix bugs, adding work)
- Clear audit trail (test report documents what was found)
- Hardener phase owns all fixes (single responsible agent)

**Consequence:**
- Bugs found in testing require re-dispatch of builder
- Extra phase (testing phase) added to timeline
- Hardener must fix all reported bugs

**Alternatives Considered:**
- ❌ Builders test themselves → miss edge cases, less rigorous
- ❌ Testers auto-fix bugs → scope creep, unclear responsibility
- ✅ Read-only testers → clear separation, rigorous verification

---

## ADR-007: Three Non-Negotiable Gates

**Decision:** Three phases are gates; user must explicitly approve before proceeding:
1. **Demo gate (after Phase 1)** — Approve UI direction
2. **Backend testing gate (after Phase K+1)** — Verify backend works standalone
3. **Staging gate (after Phase M+3)** — Verify staging deployment is clean

**Rationale:**
- Prevents cascading failures (catch issues early)
- User controls direction (approves at key milestones)
- Staging forced before prod (no direct-to-production deploys)

**Consequence:**
- Longer project timeline (explicit approval points)
- PM must implement gate enforcement logic
- User responsible for timely decisions (delays block pipeline)

**Alternatives Considered:**
- ❌ No gates → ship unvetted code
- ❌ One gate at end → issues propagate far
- ✅ Three gates → catch issues early, user stays in control

---

## ADR-008: Security Rules Enforced from Phase 1

**Decision:** All builders follow `SECURITY_RULES.md` from Phase 1. Hardener audits against all rules before deploy.

**Rationale:**
- Security-by-design, not bolt-on
- Builders learn rules early (no surprises in hardening phase)
- Hardener phase is audit + fix, not massive rewrite
- Rules are non-negotiable (no exceptions)

**Consequence:**
- Builders must know security rules (SECURITY_RULES.md is required reading)
- Hardener can focus on bugs + final checks, not security rework
- No "ship now, secure later" temptation

**Alternatives Considered:**
- ❌ Security only in hardening phase → too late, expensive fixes
- ✅ Security from Phase 1 → right from start
- ❌ Optional security rules → breed vulnerabilities

---

## ADR-009: Markdown + YAML (No Database, No Build)

**Decision:** Marlo AI is pure Markdown + YAML files. No backend, no database, no build/compile step.

**Rationale:**
- Zero dependencies (copy files, done)
- Git-friendly (all text; diffs are readable)
- Portable (works on any system with Claude Code)
- Transparent (user can read all instructions)

**Consequence:**
- No dynamic state (can't track "jobs in progress" in real-time)
- Manual state management (PM reads/writes files)
- Limited validation (YAML parsing is basic)

**Alternatives Considered:**
- ❌ Backend service → deployment overhead, vendor lock-in
- ❌ Database → overkill for file-based state
- ✅ Markdown + YAML → simple, portable, transparent

---

## ADR-010: Separate Staging from Production Deploy

**Decision:** Phase M+3 (staging) and Phase M+4 (prod) are two separate phases. No skipping staging.

**Rationale:**
- Catch integration issues before prod (DNS, env vars, SSL)
- User can test real deployment (smoke tests on real platform)
- Confidence in prod deploy (staging already proved it works)
- Rollback option (revert to staging if prod issues appear)

**Consequence:**
- Timeline longer (one more phase)
- Requires staging environment setup (usually free tier)
- User must explicitly approve prod after staging

**Alternatives Considered:**
- ❌ Staging optional → teams skip it, prod breaks
- ❌ Single deploy phase → no safety net
- ✅ Mandatory staging before prod → proven pattern in industry

---

## ADR-011: PM Hands Literal Commands, Never Runs Them

**Decision:** PM never executes deploy/migration/infrastructure commands itself. Always hands the literal command to the user, waits for confirmation.

**Rationale:**
- User maintains control (no autonomous code execution)
- Audit trail (user confirms each action)
- Reversible (user can decline and try differently)
- Safety (no accidental destructive commands)

**Consequence:**
- Slower deploys (user must copy-paste commands)
- User responsible for execution
- Clear accountability (user confirms each step)

**Alternatives Considered:**
- ❌ Agent executes commands directly → risky, no audit trail
- ✅ Agent hands literal commands → user in control
- ❌ Hybrid (some auto, some manual) → inconsistent, confusing

---

## ADR-012: Subagent Isolation (No Cross-Agent Communication)

**Decision:** Subagents don't talk to each other. All communication flows through PM.

**Rationale:**
- Clear dependencies (no hidden agent-to-agent coupling)
- Easier to debug (if phase fails, it's the phase's fault, not unknown agent)
- Parallel execution possible later (agents don't block on each other)
- PM is the source of truth (no divergent state across agents)

**Consequence:**
- PM carries all context (must read + pass all inputs to each agent)
- Agents can't directly ask questions (must go through PM)
- More explicit PM dispatch logic

**Alternatives Considered:**
- ❌ Agents talk directly → hidden dependencies, hard to debug
- ✅ All through PM → clear, auditable, isolated
- ❌ Agents share files → risky, race conditions possible

---

## ADR-013: Phase Numbers Allow for Flexibility

**Decision:** Phases are numbered Phase 0, 1, 2, 3..K, K+1, K+2..M, M+1, M+2, M+3, M+4.

The schema:
- Phase 0 = Discovery
- Phases 1–2 = Demo + Planning
- Phases 3–K = Backend milestones (N phases; depends on complexity)
- Phase K+1 = Backend testing
- Phases K+2–M = Frontend milestones (M phases; depends on complexity)
- Phase M+1 = Frontend testing
- Phase M+2 = Hardening
- Phases M+3–M+4 = Staging + Production

**Rationale:**
- K and M are variables (project complexity determines how many backend/frontend phases)
- Simple projects: K=5, M=7 (3 backend milestones, 2 frontend)
- Complex projects: K=10, M=15 (8 backend milestones, 5 frontend)
- Schema scales without redefining phase numbers

**Consequence:**
- Phase numbers are context-dependent (Phase K ≠ Phase 5 universally)
- Requires PLAN.md to define what K and M are
- User must track which phase is which

**Alternatives Considered:**
- ❌ Fixed phase numbers (Phase 1–20) → wastes numbers, confusing
- ❌ Named phases only ("backend-3", "frontend-2") → harder to order
- ✅ Dynamic K and M → flexible, scalable

---

## ADR-014: PM Skill, Not Agent

**Decision:** Project-manager is a skill (loaded once in session), not a subagent (dispatched per phase).

**Rationale:**
- PM maintains session state (remembers user answers across phases)
- Skill can persist for entire project (agent exits after each task)
- User talks to PM directly (/project-manager command)
- PM calls Agent tool to dispatch subagents

**Consequence:**
- PM must be robust (crashes lose all session state)
- PM must be conservative (any bug blocks entire project)
- PLAN.md + briefing.md act as external state backup

**Alternatives Considered:**
- ❌ PM as agent too → loses session context, harder to resume
- ✅ PM as persistent skill → keeps user in conversation

---

## ADR-015: No Partial Work States

**Decision:** Subagent exit status is one of three: `done`, `needs_input`, `blocked`. No `partial` or `in_progress` states.

**Rationale:**
- Forces clear acceptance criteria (you either meet it or you don't)
- Prevents vague situations ("60% done, should we proceed?")
- PM logic is simple (just three branches)
- Discipline (agents can't skip hard requirements)

**Consequence:**
- Agents must complete or clearly exit
- If acceptance criteria are ambiguous, agent exits `blocked`
- PM can't proceed on partial work

**Alternatives Considered:**
- ❌ Allow partial states → lazy acceptance criteria, unclear outcomes
- ✅ Three states only → disciplined, clear

---

## Future Decisions (Not Yet Made)

These are open questions for future versions:

1. **Web UI for PLAN.md + Reports** — Should we build a dashboard for viewing/managing phases?
2. **Parallel Backend/Frontend Phases** — Can builders work on phases K+2 and 3 simultaneously?
3. **Agent Plugins** — Can users provide custom agents (e.g., for specific integrations)?
4. **Rollback Automation** — Should PM auto-rollback failed phases?
5. **Cost Estimation** — Should PM estimate timeline + effort per project?

---

## Document Maintenance

- **ADR Addition Process:** When making a major architectural decision, add an ADR with rationale and alternatives
- **ADRs are immutable:** Never edit old ADRs; create new ones if decision changes
- **Link from code/docs:** Reference ADRs in agent docs / README when design depends on them

---

**Last updated:** May 2026  
**Version:** 1.0 (Initial release)
