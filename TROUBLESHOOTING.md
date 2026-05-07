# Troubleshooting Guide

Common issues and how to resolve them.

---

## Installation & Setup

### `/project-manager` doesn't appear in slash commands

**Problem:** You've installed Marlo AI but the `/project-manager` skill isn't showing up in Claude Code.

**Causes:**
- Files not copied to correct location
- Claude Code not restarted after installation
- Frontmatter syntax error in SKILL.md

**Solution:**

1. **Verify file location:**
   ```bash
   ls -la ~/.claude/skills/project-manager/SKILL.md
   # Should exist and be readable
   ```

2. **Verify frontmatter:**
   ```bash
   ~/.claude/bin/check-frontmatter.sh ~/.claude/skills/project-manager/SKILL.md
   # Should output: OK project-manager — name=project-manager
   ```

3. **Restart Claude Code completely:**
   - Close Claude Code window
   - Wait 10 seconds
   - Reopen Claude Code
   - Try `/project-manager` again

4. **Check agent files too:**
   ```bash
   for file in ~/.claude/agents/*.md; do
     ~/.claude/bin/check-frontmatter.sh "$file"
   done
   # All 8 should show OK
   ```

---

### Agents didn't copy correctly

**Problem:** Only 5 agents showing when you check `~/.claude/agents/`; should be 8.

**Solution:**

```bash
# Check what's missing
ls ~/.claude/agents/ | wc -l

# Should be 8:
# 1. backend-builder.md
# 2. backend-tester.md
# 3. demo-builder.md
# 4. deployer.md
# 5. frontend-builder.md
# 6. frontend-tester.md
# 7. hardener.md
# 8. planner.md

# If missing, copy manually:
cp ~/Marlo-AI/agents/*.md ~/.claude/agents/

# Verify again
ls ~/.claude/agents/ | wc -l
```

---

## During Project Execution

### Agent exited with JSON parse error

**Problem:** Agent exited and PM couldn't parse the response.

**Cause:** Subagent didn't exit with valid JSON (the exit contract).

**Solution:**

1. **Read the agent's full output** — there should be an error message before the malformed JSON
2. **Identify which agent failed** — check the phase report directory:
   ```bash
   ls -lt docs/phase-reports/
   # Most recent file shows which phase ran last
   ```
3. **Check hard rules** — re-read the agent's documentation (e.g., `agents/hardener.md`)
   - Did agent have all required inputs?
   - Did agent violate a hard rule? (e.g., "one milestone per dispatch")
4. **Re-dispatch the agent** — PM will try again

---

### Agent exited with status `needs_input`

**Problem:** Agent stopped and asked for something before proceeding.

**Why:** Agent couldn't proceed without a missing piece:
- API key or credentials (database, cloud service)
- Ambiguous acceptance criteria
- Design decision or user preference

**Solution:**

Read the `needs_input` array in the exit JSON. Example:

```json
{
  "status": "needs_input",
  "needs_input": [
    {
      "name": "Supabase Project URL",
      "why": "Backend builder needs to create migrations",
      "how_to_get": "From Supabase dashboard → Project Settings → API URL"
    },
    {
      "name": "Clarify: Should notes be shareable with other users?",
      "why": "Affects RLS policies and API design",
      "how_to_get": "Discuss with PM or check docs/briefing.md"
    }
  ]
}
```

**Action:**
1. Gather the missing item(s)
2. Tell PM: "I have the Supabase URL: `https://abc.supabase.co`. Proceed."
3. PM re-dispatches the agent with the info

---

### Agent exited with status `blocked`

**Problem:** Agent hit a hard blocker and can't continue.

**Why:** Something prevents the agent from completing:
- Acceptance criteria are ambiguous or span two milestones
- Need a decision that only the user can make
- Infrastructure issue (e.g., can't reach cloud platform)

**Solution:**

Read the `blocker` field in the exit JSON. Examples:

```
"blocker": "Acceptance criteria span two milestones: both 'API endpoints' AND 'auth flows' should be Phase 4. Please split into separate phases."
```

**Action:**
1. Address the blocker (clarify criteria, split phases, fix infrastructure)
2. PM re-dispatches the agent

---

### Agent is taking too long (>30 minutes)

**Problem:** Agent is still running; no response after 30 minutes.

**Causes:**
- Agent hit an infinite loop (rare)
- Agent is waiting for external service (database migration, build, etc.)
- Claude Code session timeout

**Solution:**

1. **Wait longer** — some operations (Supabase migrations, npm installs) can take 10–20 min legitimately
2. **Check for output** — look at local files:
   ```bash
   ls -lt docs/phase-reports/
   tail -f docs/phase-reports/phase-*.md  # Watch for updates
   ```
3. **If truly stuck** — press `Ctrl+C` to interrupt the agent, then:
   - PM will ask you to retry
   - Possible data loss if agent was mid-write; check git status

---

## Project State Issues

### My PLAN.md got corrupted / overwritten

**Problem:** PLAN.md has broken formatting or lost data.

**Solution:**

1. **Check git history:**
   ```bash
   git log --oneline PLAN.md
   # See who changed it and when
   
   git show <commit-hash>:PLAN.md
   # View old version
   ```

2. **Revert to last good version:**
   ```bash
   git checkout <commit-hash> -- PLAN.md
   # Restore from specific commit
   ```

3. **Prevent future corruption:**
   - Don't edit PLAN.md manually; let PM manage it
   - Always commit before running phases
   - Back up PLAN.md before risky operations

---

### docs/briefing.md was rewritten (violated append-only)

**Problem:** briefing.md was overwritten instead of appended.

**Why:** This shouldn't happen if PM is working correctly; may indicate PM skill bug or user manual edit.

**Solution:**

1. **Check git to recover:**
   ```bash
   git log --oneline docs/briefing.md
   git show <old-commit>:docs/briefing.md
   ```

2. **Restore and append new info:**
   ```bash
   # Get old version
   git show <commit-hash>:docs/briefing.md > /tmp/old-briefing.md
   
   # Manually append changes:
   cat /tmp/old-briefing.md > docs/briefing.md
   cat >> docs/briefing.md << EOF

## Revision 2 (Phase N)
[New discovery or changes]
EOF
   ```

3. **Commit fix:**
   ```bash
   git add docs/briefing.md
   git commit -m "Fix: restore briefing.md append-only property"
   ```

---

### Phase reports missing; don't know what happened

**Problem:** Agent exited `done` but no report was written.

**Causes:**
- Agent crashed before writing report
- Report written to wrong path
- Git commit failed

**Solution:**

1. **Check if report exists elsewhere:**
   ```bash
   find . -name "*phase*" -type f
   find . -name "*report*" -type f
   ```

2. **Check git log for hints:**
   ```bash
   git log --oneline --all
   # See if agent committed anything
   ```

3. **If truly lost:**
   - Agent should have exited with `report_path` in JSON
   - Re-run the phase from PM (agent has idempotency safeguards)

---

## Backend & API Issues

### Backend tests fail: "Can't connect to API"

**Problem:** backend-tester can't reach the API endpoints.

**Causes:**
- Backend dev server not running
- Wrong port/URL in env vars
- Firewall blocking localhost connections

**Solution:**

1. **Start backend dev server (per your stack):**
   ```bash
   # Next.js
   npm run dev
   
   # Flask
   python app.py
   
   # Django
   python manage.py runserver
   ```

2. **Verify server is running:**
   ```bash
   curl http://localhost:3000/api/health
   # Should return 200, not connection refused
   ```

3. **Check .env.local has correct API URL:**
   ```bash
   echo $DATABASE_URL
   echo $API_PORT
   # Verify against backend-builder report
   ```

4. **Re-run backend-tester:**
   - PM will dispatch again; tester will verify fresh

---

### Backend RLS policies are too strict

**Problem:** Authenticated users can't read/write their own data.

**Symptom:** Tester report shows: "GET /notes returns 403 Forbidden (not 200)"

**Cause:** RLS policy denies access; likely auth check misconfigured.

**Solution:**

1. **Review Supabase RLS policy:**
   ```bash
   # Check hardener report for exact policy
   # Should be something like:
   # CREATE POLICY "Users see own notes"
   #   ON notes FOR SELECT
   #   USING (auth.uid() = user_id);
   ```

2. **Verify JWT is being sent:**
   ```bash
   curl -H "Authorization: Bearer $JWT" http://localhost:3000/api/notes
   # JWT must be valid and contain correct user ID
   ```

3. **Fix and re-test:**
   - PM re-dispatches backend-builder for policy fix
   - backend-tester verifies again

---

## Frontend & Browser Issues

### Frontend won't load; blank page

**Problem:** Browser shows blank page; no errors in console.

**Causes:**
- Frontend dev server not running
- Build failed
- API endpoint misconfigured

**Solution:**

1. **Start frontend dev server:**
   ```bash
   npm run dev
   ```

2. **Check for build errors:**
   ```bash
   npm run build
   # Should complete without errors
   ```

3. **Check browser console for JS errors:**
   - Open DevTools (F12)
   - Go to Console tab
   - Look for red errors
   - Report in phase report for hardener to fix

4. **Verify API URLs:**
   - Check .env.local / .env.production
   - API base URL should match running backend

---

### API calls from frontend return 401

**Problem:** Frontend makes requests; backend returns 401 Unauthorized.

**Cause:** JWT token missing or invalid.

**Solution:**

1. **Check browser LocalStorage:**
   ```javascript
   // In browser console
   localStorage.getItem('jwt')
   // Should exist and be non-empty
   ```

2. **Verify JWT was stored after login:**
   ```javascript
   // In browser console after login
   console.log('JWT:', localStorage.getItem('jwt'))
   ```

3. **Check request headers:**
   - Open DevTools → Network tab
   - Make a request to /api/notes
   - Look at Request Headers
   - Should have: `Authorization: Bearer <token>`

4. **If missing, report as bug:**
   - Frontend-tester or hardener will fix the auth flow

---

### Frontend shows console errors but app works

**Problem:** DevTools console shows warnings/errors but UI functions correctly.

**Decision:** Is it safe to deploy?

**Solution:**

1. **Categorize errors:**
   - ⚠️ Warnings (yellow) — usually safe, check what they say
   - 🔴 Errors (red) — may cause issues; report to hardener

2. **Common safe warnings:**
   - "React strict mode double-invokes effects" — safe in dev
   - "DevTools detected application..." — safe, just informational
   - Unused variable warnings — safe if not in critical path

3. **Common unsafe errors:**
   - Uncaught TypeError — fix before deploy
   - Network failures — check API connectivity
   - RLS/auth errors — fix before deploy

4. **Report unclear cases:**
   - Phase report detail: "Console shows error X in flow Y"
   - Hardener will investigate and fix

---

## Deployment Issues

### Staging deploy succeeded but site doesn't load

**Problem:** Deployer says "staging URL deployed" but browser can't reach it.

**Causes:**
- Domain/DNS not configured
- Build failed silently
- Environment variables not set

**Solution:**

1. **Check deployment logs:**
   ```bash
   # Vercel: Dashboard → Deployments → click latest
   # Fly: fly logs
   # Render: Dashboard → Logs
   ```

2. **Verify environment variables are set:**
   - Deployer should have set DATABASE_URL, API keys, etc.
   - Check platform dashboard: Settings → Environment Variables
   - Restart deployment if vars missing

3. **Check DNS (if using custom domain):**
   ```bash
   dig your-domain.com
   nslookup your-domain.com
   # Should resolve to deployment platform's IP
   ```

4. **Retry deployment:**
   - PM re-dispatches deployer (mode=staging)

---

### Production domain not working after deploy

**Problem:** Deployer said prod deployed, but your domain doesn't load.

**Causes:**
- DNS change hasn't propagated (can take 15–60 minutes)
- CNAME record incorrect
- SSL certificate not issued yet

**Solution:**

1. **Check DNS propagation:**
   ```bash
   dig your-domain.com +trace
   # Should eventually show platform IP
   
   # Or use online tool: whatsmydns.net
   ```

2. **Wait for DNS** — if TTL is high, wait 15–60 minutes and try again

3. **Verify CNAME record:**
   ```bash
   # Should match platform's requirement
   # Example for Vercel:
   CNAME  your-domain.com  cname.vercel.app
   ```

4. **Check SSL certificate:**
   - Vercel/Render auto-issue free SSL
   - Check platform dashboard for certificate status
   - Wait 1–2 minutes for issuance

5. **Manually test platform URL (not your domain):**
   ```bash
   # Vercel gives you a .vercel.app URL
   curl https://your-app.vercel.app/api/health
   # Should work even if domain DNS hasn't propagated
   ```

---

## Debugging Deep Dives

### How to read phase reports

Phase reports are YAML + markdown files that document what happened.

**Structure:**
```markdown
---
phase: 03
title: Database Schema
status: done  # or needs_input, blocked
timestamp: 2026-05-07T10:30:00Z
---

## Acceptance Criteria
✓ Supabase migrations created
✓ RLS policies implemented
✓ Tests pass

## What Was Built
- users table (id, email, password_hash, created_at)
- notes table (id, user_id, title, body, created_at, updated_at)
- sessions table (id, user_id, token, expires_at)

## RLS Policies
- Users can see only their own notes
- Public read on users.email for auth flow

## Tests
- All migration tests pass: 12 passed in 3.4s
- RLS verified: user A can't see user B's notes

## Git Commits
Run these manually:
git add . && git commit -m "feat: add database schema with RLS"

## Open Issues
None
```

**How to use it:**
- To understand what happened in a phase → read the report
- To revert to prior state → check "Git Commits" section
- To find bugs → check "Open Issues" section

---

### How to check git history

Understand what was built and when.

```bash
# See all commits
git log --oneline

# See commits for a specific file
git log --oneline src/pages/api/notes.ts

# See what changed in a specific commit
git show <commit-hash>

# See diff between phases
git log --oneline docs/phase-reports/
# Most recent report = last phase completed

# Revert a specific commit if needed
git revert <commit-hash>
# Creates a new commit that undoes the original
```

---

### How to inspect environment variables

Make sure secrets are configured correctly without exposing them.

```bash
# Never echo secrets, but verify they exist
env | grep -i database
env | grep -i api

# Check .env files (local only)
cat .env.local
cat .env.production  # Don't commit this!

# Verify .env is in .gitignore
cat .gitignore | grep "\.env"
# Should show: .env, .env.local, .env.*.local, etc.
```

---

## Getting Help

- **Architecture questions:** Read `docs/design.md`
- **How does a phase work?** Read `agents/<phase>.md`
- **Security rules?** Read `SECURITY_RULES.md`
- **Phase details?** Read `docs/phase-reports/phase-<NN>.md`
- **Still stuck?** Create a GitHub issue with phase report and logs

---

## Common Success Patterns

### What to do if deployment fails

1. PM re-dispatches deployer → generates new staging URL
2. Test staging locally before retrying production
3. If staging works but prod fails → usually DNS/domain issue (wait 15 min)
4. Check error tracking (Sentry) for 5xx errors

### What to do if a bug appears after hardening

1. Report the bug (which flow, what happened, where error?)
2. PM re-dispatches hardener to fix
3. Hardener writes regression test, fixes bug, verifies test passes
4. Re-run frontend/backend tester to confirm fix
5. Re-deploy

### What to do if you need to backtrack

1. Identify which phase to revert to
2. Read ROLLBACK.md for specific instructions
3. PM can resume from an earlier phase
4. Agents are idempotent; re-running a phase is safe

---

**Questions?** See README.md for links to full documentation.
