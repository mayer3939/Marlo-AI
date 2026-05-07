# Rollback & Revert Strategies

How to back out of a phase and restart if needed.

---

## When to Rollback

**Rollback is needed if:**

- ❌ Phase completed but acceptance criteria not actually met
- ❌ Phase introduced a major bug that blocks subsequent phases
- ❌ You want to change acceptance criteria and re-run a phase
- ❌ Phase report missing or corrupted; want to re-execute for audit trail
- ❌ Backend test found critical issues; need backend-builder to re-work

**Don't rollback if:**

- ✅ You just want to fix a bug → use hardener (Phase M+2) instead
- ✅ You want to add a feature after a phase → add a new phase, don't revert
- ✅ You want to change stack → too late; proceed with current stack

---

## Rollback Levels

### Level 1: Revert to a Specific Commit

**Use case:** "I want the code before Phase 4 started"

**Commands:**

```bash
# View git log to find the commit you want to revert to
git log --oneline --all
# Example output:
# abc1234 feat: implement notes API (Phase 5)
# def5678 feat: implement auth endpoints (Phase 4)
# ghi9012 feat: create database schema (Phase 3)
# jkl3456 Initial commit: scaffolding (Phase 2)

# Revert to before Phase 5
git reset --hard def5678

# Verify you're at the right commit
git log --oneline -3
```

**Impact:**

- ✅ Code reverted to that state
- ⚠️ All commits after that point are LOST (if you haven't pushed)
- ⚠️ Phase reports from later phases become stale
- ✅ You can now re-dispatch backend-builder for Phase 5 (it will re-work the same phase)

**Safety:**

```bash
# Before doing reset --hard, save your current state
git branch backup-before-rollback
# Now you can safely reset
git reset --hard <commit>
# If you change your mind, restore with:
git reset --hard backup-before-rollback
```

---

### Level 2: Revert PLAN.md to Earlier State

**Use case:** "I want to re-plan phases 5+ without losing code history"

**Why:** Sometimes acceptance criteria was wrong. You want to re-plan but keep the work.

**Commands:**

```bash
# View PLAN.md history
git log --oneline PLAN.md
# Example:
# aaa1111 PM: update PLAN.md after Phase 4 (Phase M+2)
# bbb2222 PM: write PLAN.md (Phase 2)

# Restore old PLAN.md but keep new commits
git show bbb2222:PLAN.md > PLAN.md.old
cat PLAN.md.old  # Review what the old plan was

# Manually edit PLAN.md to reset phase status
# Example: Change "Phase 5: status = done" to "status = pending"

git add PLAN.md
git commit -m "Revert PLAN.md to re-plan phases 5+"
```

**Impact:**

- ✅ Code history preserved
- ✅ Can re-run phases with updated criteria
- ⚠️ Phase reports become stale; you'll have duplicates (phase-05-v1, phase-05-v2)
- ✅ Full audit trail of changes

---

### Level 3: Keep Code, Wipe Phase Reports

**Use case:** "Code is good, but phase reports are corrupted. Let me re-execute the final phases for clean audit."

**Commands:**

```bash
# Remove phase reports from phase N onward
rm -f docs/phase-reports/phase-M*.md docs/phase-reports/phase-K*.md

# Update PLAN.md to mark phases as "pending" or "in-progress"
# Example:
# ## Phase M+1
# Status: pending
# (was: done)

git add docs/phase-reports/ PLAN.md
git commit -m "Reset phase reports for re-execution of testing phases"

# PM will now resume from the pending phase
```

**Impact:**

- ✅ Code preserved
- ✅ Audit trail exists in git commits
- ✅ Can re-run phases with clean reports
- ⚠️ Previous reports lost (but you can recover from git history if needed)

---

## Rollback Scenarios

### Scenario 1: Backend Test Found Critical Bugs

**Problem:**

Phase K+1 (backend-tester) exits with critical bugs in the API:

```
🔴 CRITICAL: Auth endpoint returns user password in response
🔴 CRITICAL: Notes RLS policy allows user A to read user B's notes
```

These can't be fixed by hardener; they need backend-builder to re-work the auth/schema.

**Solution:**

```bash
# Option A: Minimal rollback (revert just backend phases)
git log --oneline src/pages/api/
# Find the commit before the buggy phases started
git reset --hard <commit-before-backend>

# Update PLAN.md: mark Phase 3, 4, 5 as "pending"
# PM re-dispatches backend-builder to fix

# Option B: Start over from Phase 2
git reset --hard <commit-at-scaffolding>
# Same: mark Phase 3+ as pending in PLAN.md
```

**Impact:**

- Backend work redone (better second time: lesson learned)
- Frontend work can start fresh once backend is clean
- Timeline: +1–2 hours per backend phase

---

### Scenario 2: Staging Deploy Failed; Need to Re-hardening

**Problem:**

Phase M+3 deployed to staging. You test and find:

- Database migrations didn't run
- Error messages leak stack traces
- Missing rate limiting

Hardener should have caught these. You want to re-run hardener for a clean audit.

**Solution:**

```bash
# Don't revert code. Just reset phase M+2 report.
rm -f docs/phase-reports/phase-M2-hardening.md

# Mark in PLAN.md:
# Phase M+2 — Hardening
# Status: pending (was: done)

git add docs/phase-reports/ PLAN.md
git commit -m "Reset hardening for re-execution"

# PM resumes from Phase M+2
# Hardener runs again with fresh checks
```

**Impact:**

- Code unchanged
- Clean hardening report generated
- Timeline: +30–45 min

---

### Scenario 3: Wrong Stack Locked in Phase 2

**Problem:**

Phase 2 (planner) locked stack as "Next.js + Supabase" but you realize you need "Django + PostgreSQL" instead.

You can't change stack mid-project (too costly). But this was a planning error.

**Solution:**

**You CAN'T rollback stack.** Changing cloud platforms/frameworks mid-project is a reboot, not a rollback.

**Instead:**

1. **Archive current project:**
   ```bash
   git branch backup-nextjs-attempt
   git push origin backup-nextjs-attempt
   ```

2. **Start fresh with new stack:**
   ```bash
   cd ~/projects
   mkdir my-project-v2
   cd my-project-v2
   git init
   /project-manager  # Start over
   ```

3. **Learn from Phase 0 discovery:**
   - Better questions to lock stack earlier
   - Document decision rationale in `docs/briefing.md` Revision 2

---

### Scenario 4: Partial Phase Completion

**Problem:**

Frontend-builder was supposed to build "Dashboard + Notes CRUD" but only built "Dashboard" before exiting.

You want the partial work but need to re-dispatch for Notes CRUD.

**Solution:**

```bash
# Code is fine; just unclear on acceptance criteria

# Update PLAN.md
# Phase K+2: Frontend — Dashboard
# Status: done
# Phase K+3: Frontend — Notes CRUD (NEW)
# Status: pending

git add PLAN.md
git commit -m "Split Phase K+2 into two phases for clarity"

# PM re-dispatches frontend-builder for Phase K+3
```

**Impact:**

- Partial work kept (no lost effort)
- Clear phases now
- Audit trail shows the split
- Timeline: +45–75 min for notes CRUD phase

---

## Rollback Decision Tree

```
START: Do I need to rollback?

├─ Code is broken (security/critical bug)
│  └─ Revert git to last good commit (Level 1)
│  
├─ Phase report is stale/corrupted
│  └─ Delete report(s), mark phases as pending (Level 3)
│
├─ Wrong acceptance criteria
│  └─ Edit PLAN.md, update phase status (Level 2)
│
├─ Wrong stack chosen
│  └─ Archive project, start new one (no rollback)
│
├─ Just want to fix bugs
│  └─ DON'T rollback; use hardener (Phase M+2)
│
└─ Want to add features
   └─ DON'T rollback; add new phases
```

---

## Git Commands for Rollback

### Safe Rollback (Create New Branch)

```bash
# Before destructive changes, create a backup
git branch backup-<reason>
git push origin backup-<reason>

# Now you can safely rollback
git reset --hard <commit>
git push origin main --force-with-lease  # Only if you own the branch

# If you need to restore
git reset --hard backup-<reason>
```

### View What You're About to Lose

```bash
# See commits you'll lose with reset --hard
git log --oneline <current-branch>..<commit-to-reset-to>

# See files you'll lose
git diff --name-status <commit>..HEAD
```

### Recover Accidentally Deleted Commits

```bash
# See all commits ever, including deleted ones
git reflog
# Example:
# abc1234 HEAD@{0}: reset: moving to def5678
# def5678 HEAD@{1}: commit: feat: Phase 5
# ...

# Restore the commit you deleted
git reset --hard abc1234
```

---

## Prevention: Best Practices

1. **Commit frequently** — After each phase, commit `PLAN.md` and phase reports
   ```bash
   git add PLAN.md docs/phase-reports/phase-NN-*.md
   git commit -m "phase-NN: [title]"
   ```

2. **Backup before major changes**
   ```bash
   git branch backup-$(date +%Y%m%d-%H%M%S)
   ```

3. **Review acceptance criteria before each phase**
   - Read current phase row in PLAN.md
   - Clarify with PM if ambiguous
   - Don't start phase if criteria unclear

4. **Test staging before production**
   - Phase M+3 deploys to staging
   - You test yourself (critical)
   - Only then proceed to Phase M+4 (production)

5. **Keep phase reports**
   - They're your audit trail
   - Commit them to git
   - Don't delete unless intentional rollback

---

## When in Doubt

**Ask PM:**

"I want to rollback to Phase N. What's the safest way?"

PM will:
1. Check current state
2. List what will be lost
3. Confirm acceptance criteria for re-run
4. Re-dispatch the phase

Safer to ask than guess with `git reset --hard`! 🚀

---

## Appendix: Common Git Rollback Commands

| Goal | Command | Risk |
|------|---------|------|
| See history | `git log --oneline` | None |
| See what changed | `git show <commit>` | None |
| See branches | `git branch -a` | None |
| Backup current state | `git branch backup-<name>` | None |
| Undo last commit (keep changes) | `git reset --soft HEAD~1` | Low |
| Undo last commit (lose changes) | `git reset --hard HEAD~1` | 🔴 HIGH |
| Go to specific commit (keep changes) | `git reset <commit>` | Low |
| Go to specific commit (lose changes) | `git reset --hard <commit>` | 🔴 HIGH |
| Undo already-pushed commit | `git revert <commit>` | Low |
| Recover deleted commit | `git reflog` + `git reset` | None (read-only) |

---

**Key rule:** Always backup before using `--hard`. 🛡️
