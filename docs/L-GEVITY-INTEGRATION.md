# L-GEVITY Skills Integration with Marlo AI

This document shows how the L-GEVITY engineering skills integrate with Marlo AI phases for architectural discipline, quality assurance, and deployment reliability.

---

## Overview

Marlo AI orchestrates phased software delivery. The L-GEVITY skills add architectural and quality discipline at key phases:

```
Phase 0: Discovery
    ↓
Phase 1-2: Demo & Planning
    ↓ (use: architecture-guidelines, functionality-complexity-tradeoff)
Phases 3-M: Build (Backend + Frontend)
    ↓ (use: architecture-guidelines, defect-shift-left)
Phase M+2: Hardening
    ↓ (use: structural-simplification, defect-shift-left)
Phase M+3: Security Audit
    ↓
Phase M+4-5: Staging & Production Deploy
    ↓ (use: ci-cd-reliability-architecture)
```

---

## Skill-by-Phase Integration

### Phase 2: Planner — Scaffolding & PLAN.md

**Use: `architecture-guidelines` + `functionality-complexity-tradeoff`**

**Why:** Lock in architectural decisions before building.

**How:**
1. Use `architecture-guidelines` to validate module structure:
   - Minimalism: Is this the smallest viable solution?
   - Modularity: Clear separation of concerns?
   - Dependency discipline: No cycles? DAG structure?
   - Naming: Do names reveal architectural intent?

2. Use `functionality-complexity-tradeoff` to decide:
   - What features to BUILD in this version
   - What to DEFER for later phases
   - What to DROP entirely

**Output:** PLAN.md reflects disciplined architecture decisions, not just feature list.

---

### Phase 3..K: Backend-Builder — API & Schema

**Use: `architecture-guidelines` + `defect-shift-left`**

**Why:** Build with architectural discipline; shift quality checks left.

**How:**

1. Use `architecture-guidelines` when building:
   - Pure domain logic at the core (I/O at edges)
   - Functional purity (testable without mocks)
   - Resilience patterns (idempotency, failure classification)
   - Fail-fast validation at boundaries

2. Use `defect-shift-left` to decide:
   - Where type system should catch errors (TypeScript, Python types)
   - Where linting should catch issues (eslint, ruff)
   - What should be pre-commit hooks
   - What requires CI gates
   - What is better caught in tests

**Output:** Code is architecturally clean + quality checks shift left (earlier = cheaper to fix).

---

### Phase K+2..M: Frontend-Builder — UI & Flows

**Use: `architecture-guidelines` + `defect-shift-left`**

**Why:** Frontend has its own architectural concerns (state, component hierarchy, side effects).

**How:**

1. Use `architecture-guidelines` for:
   - Component modularity (SoC: one concern per component)
   - Pure vs. side-effect code separation
   - State localization (no prop drilling)
   - Consistent naming patterns

2. Use `defect-shift-left` for:
   - TypeScript strict mode (type system shifts left)
   - ESLint rules for component safety
   - Pre-commit hooks for common pitfalls
   - Unit tests for business logic before integration tests

---

### Phase M+2: Hardener — Bug Fixing & Security

**Use: `structural-simplification` + `defect-shift-left`**

**Why:** Before deploying, audit complexity and ensure quality checks are automated.

**How:**

1. Use `structural-simplification` to audit:
   - **Diversity:** How many different patterns/abstractions?
   - **Coupling:** How interdependent are modules?
   - **Depth:** How deep is the call stack / class hierarchy?
   - **Parts:** How many components/files total?
   
   Compare to baseline or similar systems. Complexity growth signals over-engineering.

2. Use `defect-shift-left` to:
   - Ensure CI gates exist for the bugs you found
   - Add linting rules to prevent recurrence
   - Add pre-commit hooks for common mistakes
   - Verify type system catches edge cases

**Output:** Code is simpler, quality checks are automated (won't regress).

---

### Phase M+4-5: Deployer — Staging & Production Deploy

**Use: `ci-cd-reliability-architecture`**

**Why:** Pipelines must be reliable: idempotent, self-contained, zero-downtime.

**How:**

1. **Idempotency:** Pipeline safe to run 0, 1, or N times
   - Use `npm ci` not `npm install`
   - Artifact promotion (build once, deploy everywhere)
   - Conditional DB writes

2. **Self-Contained:** Each job declares inputs/outputs
   - No implicit state
   - Explicit artifact passing
   - Namespace jobs uniquely

3. **Immutable Artifacts:** Build once, configure at deploy time
   - No per-environment builds
   - Secrets + config at deploy time, not build time

4. **Self-Healing:** Transient failures retry; permanent failures fail fast
   - Timeouts on stuck jobs
   - Graceful degradation

5. **Zero-Downtime:** Never touch production directly
   - Always use staging first
   - Preview environments
   - Atomic promotion

6. **Zero-Knowledge:** Minimal seed secrets
   - Use OIDC/STS for dynamic tokens
   - No credential exchange

**Output:** Deployments are safe, reliable, repeatable.

---

## When to Invoke Each Skill

### `architecture-guidelines`

**Trigger when:**
- Introducing a new module/service/abstraction
- Refactoring across module boundaries
- Applying SOLID principles
- Reviewing PR for architectural concerns (purity, idempotency, naming)

**Skip when:**
- Bug fixes within existing module
- Content/copy changes
- CSS-only changes
- Dependency version bumps
- Trivial renames

### `structural-simplification`

**Trigger when:**
- Phase M+2 hardening (complexity audit before deploy)
- Evaluating major refactors
- Deciding between two design approaches
- Code review flagging "this is getting complicated"

### `defect-shift-left`

**Trigger when:**
- Building new features (decide where checks belong)
- Phase M+2 hardening (ensure checks are automated)
- Bugs escape to production (prevent recurrence via earlier checks)

### `functionality-complexity-tradeoff`

**Trigger when:**
- Phase 2 planner (what features to include)
- Mid-project deciding to BUILD / DEFER / DROP a feature
- Code review suggesting simplification / deletion / obsolescence

### `ci-cd-reliability-architecture`

**Trigger when:**
- Designing deployment pipeline (Phase M+4-5)
- Debugging deployment failures
- Auditing pipeline for reliability issues
- Any new job/workflow/step added

---

## Example: Full Build with L-GEVITY Discipline

```
Phase 2 Planner:
  - Use architecture-guidelines to validate module structure
  - Use functionality-complexity-tradeoff to lock feature set
  - Output: PLAN.md reflects both
  ✓ Ready to build

Phase 3-5 Backend:
  - Use architecture-guidelines: pure core, resilient edges
  - Use defect-shift-left: where should checks live?
  - Output: Architecturally clean, quality checks automated
  ✓ Ready to test

Phase K+2-3 Frontend:
  - Use architecture-guidelines: component hierarchy, state discipline
  - Use defect-shift-left: TypeScript strict, ESLint rules
  - Output: Clean components, type-safe, linted
  ✓ Ready to test

Phase M+2 Hardening:
  - Use structural-simplification: audit complexity growth
  - Use defect-shift-left: ensure CI gates exist for bugs found
  - Output: Simpler code, no regressions
  ✓ Ready to deploy

Phase M+4 Deployer:
  - Use ci-cd-reliability-architecture: pipeline reliability rules
  - Output: Safe, repeatable deployments
  ✓ Live
```

---

## How the Skills Compose

The L-GEVITY skills are designed to work together:

```
architecture-guidelines (HOW to build cleanly)
         ↓
structural-simplification (WHETHER result is too complex)
         ↓
system-optimization (HOW to improve operations)
```

For Marlo, the composition is:

```
Phase 2: architecture-guidelines + functionality-complexity-tradeoff
         ↓ (design locked)
Phase 3-M: architecture-guidelines + defect-shift-left
         ↓ (code built, checks automated)
Phase M+2: structural-simplification + defect-shift-left
         ↓ (complexity audited, regressions prevented)
Phase M+4: ci-cd-reliability-architecture
         ↓ (pipeline reliable)
SHIPPED
```

---

## File Locations

**Skills:**
```
~/.claude/skills/
├── project-manager/
├── architecture-guidelines/
├── ci-cd-reliability-architecture/
├── defect-shift-left/
├── functionality-complexity-tradeoff/
└── structural-simplification/
```

**Documentation:**
```
docs/l-gevity-reference/
├── READ-architecture-guidelines.md
├── READ-ci-cd-reliability-architecture.md
├── READ-defect-shift-left.md
├── READ-functionality-complexity-tradeoff.md
└── READ-structural-simplification.md
```

---

## Credit

These skills are from **[L-GEVITY](https://l-gevity.nl)** — an open-source repository of 30+ years of software engineering expertise.

**License:** MIT  
**Repository:** https://github.com/l-gevity/l-gevity-skills

---

## Using These Skills

1. **In your project's CLAUDE.md:**
   ```markdown
   ## Architectural Discipline
   - [architecture-guidelines](./.claude/skills/architecture-guidelines/)
   - [structural-simplification](./.claude/skills/structural-simplification/)
   - [ci-cd-reliability-architecture](./.claude/skills/ci-cd-reliability-architecture/)
   - [defect-shift-left](./.claude/skills/defect-shift-left/)
   - [functionality-complexity-tradeoff](./.claude/skills/functionality-complexity-tradeoff/)
   ```

2. **During phases:**
   - Reference the skill name to trigger it (e.g., "use architecture-guidelines to audit this module")
   - Or invoke via `/` prefix in Claude Code

3. **Read primers first:**
   - Each skill has a `READ-*.md` in `docs/l-gevity-reference/`
   - These explain the skill in plain English before diving into operational details

---

**Last Updated:** May 7, 2026  
**Integrated Skills:** 5 (architecture-guidelines, ci-cd-reliability-architecture, defect-shift-left, functionality-complexity-tradeoff, structural-simplification)
