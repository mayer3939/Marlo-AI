# Quick Start — Build a Real App in 3 Hours

Marlo automates phased software delivery. This guide shows you how in a real example.

---

## What You'll Build

**Project:** Note-Taking App (CRUD + Auth)

**Deliverable:** Production app at your domain

**Time:** ~3 hours (hands-off agent work, mostly)

---

## Prerequisites

1. **Claude Code installed** — web, CLI, or IDE extension
2. **Marlo AI cloned & installed** (see README Install section)
3. **Cloud account ready** — Supabase (free) + Vercel (free) or similar
4. **Project directory** — a fresh folder with `git init`

---

## Step-by-Step

### Phase 0: Discovery (You + PM) — 15 minutes

**Start the orchestrator:**

```bash
mkdir note-app && cd note-app
git init
```

In Claude Code:

```
/project-manager
```

**PM asks discovery questions. Answer:**

```
Persona: Solo developer, first project with Supabase
Core flow: Sign up → Dashboard (list notes) → Create note → Edit note → Delete note → Sign out
Cloud platform: Vercel (frontend) + Supabase (backend)
Integrations: None yet
Compliance: None
Success metric: Deployed to production in one day
Database: PostgreSQL (Supabase will set up)
Stack preference: Next.js, TypeScript, TailwindCSS
```

**PM saves to `docs/briefing.md` and dispatches Phase 1.**

---

### Phase 1: Demo (Agent) — 30 minutes

**Agent: demo-builder**

PM sends you a localhost dev server link. You see:

```
✓ Login screen
✓ Sign-up screen  
✓ Dashboard (5 mock notes)
✓ Create note modal
✓ Edit note modal
✓ Settings page (account management)
```

**You approve:** "Looks good! Proceed."

Phase report written to `docs/phase-reports/phase-01-demo.md`.

---

### Phase 2: Planning (Agent) — 20 minutes

**Agent: planner**

Creates `PLAN.md` with all 10 phases and their acceptance criteria. Example:

```
## Phase 3 — Database Schema
Acceptance Criteria:
- Supabase migrations created for users, notes, sessions tables
- RLS policies enable each user to see only their own notes
- Tests verify schema

## Phase 4 — Auth API
Acceptance Criteria:
- POST /auth/signup returns JWT
- POST /auth/login returns JWT
- POST /auth/logout clears session
- GET /auth/me returns current user
- All endpoints tested
```

You see: "Stack locked: Next.js 15 + Supabase + Vercel. Scaffolding..."

Phase report: `docs/phase-reports/phase-02-scaffolding.md`.

---

### Phase 3: Backend — DB Schema (Agent) — 30 minutes

**Agent: backend-builder**

Builds one milestone: the database schema.

```bash
# What agent does:
# 1. Creates Supabase migrations for users, notes, sessions
# 2. Enables Row-Level Security (RLS) on all tables
# 3. Writes tests to verify schema + RLS
# 4. Git commits

# What you see:
# - Literal git commands to run (e.g., "Run: supabase db push")
```

Phase report: `docs/phase-reports/phase-03-db-schema.md`.

---

### Phase 4: Backend — Auth API (Agent) — 45 minutes

**Agent: backend-builder** (invoked again for next milestone)

Builds: signup, login, logout, profile endpoints.

All test-driven. Every endpoint tested before committing.

Phase report: `docs/phase-reports/phase-04-auth-api.md`.

---

### Phase 5: Backend — Notes API (Agent) — 60 minutes

**Agent: backend-builder** (invoked for 3rd milestone)

Builds: POST /notes, GET /notes, PATCH /notes/:id, DELETE /notes/:id.

RLS ensures each user sees only their notes.

Phase report: `docs/phase-reports/phase-05-notes-api.md`.

---

### Phase K+1: Backend Testing (Agent) — 20 minutes

**Agent: backend-tester**

Verifies all backend work without touching code:

```bash
curl -X POST http://localhost:3000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"..."}'
# Response: {"jwt": "...", "user": {...}}
✓ signup works

curl -X GET http://localhost:3000/notes \
  -H "Authorization: Bearer $JWT"
# Response: [{"id": 1, "title": "My note", ...}, ...]
✓ notes api works

# ... (tests all endpoints)
```

Phase report: `docs/phase-reports/phase-K1-backend-test.md` (includes **bug list** if any).

**Gate:** Backend verified. Proceed to frontend.

---

### Phase K+2: Frontend — Auth Screens (Agent) — 45 minutes

**Agent: frontend-builder**

Builds: Login screen, Sign-up screen. Replaces demo mockups with real API calls.

```javascript
// Real example from built code:
async function signup(email: string, password: string) {
  const res = await fetch('/api/auth/signup', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  });
  const { jwt } = await res.json();
  localStorage.setItem('jwt', jwt);  // Store JWT
  redirect('/dashboard');
}
```

Phase report: `docs/phase-reports/phase-K2-auth-screens.md`.

---

### Phase K+3: Frontend — Dashboard & Notes (Agent) — 75 minutes

**Agent: frontend-builder**

Builds: Dashboard (list notes), Create modal, Edit modal, Delete button.

Wired to real backend API. All flows work end-to-end.

Phase report: `docs/phase-reports/phase-K3-notes-crud.md`.

---

### Phase M+1: Frontend Testing (Agent) — 30 minutes

**Agent: frontend-tester**

Clicks through every user flow in a real browser:

```
✓ Sign up with new email → redirects to dashboard
✓ Create note → appears in list
✓ Edit note → updates immediately
✓ Delete note → removed from list
✓ Logout → redirects to login
✓ Try accessing /dashboard without auth → redirected to /login
✓ Mobile responsive? (if in scope)
```

Phase report: `docs/phase-reports/phase-M1-frontend-test.md` (includes **bug list** if any).

---

### Phase M+2: Hardening (Agent) — 45 minutes

**Agent: hardener**

Fixes all bugs from test reports + security audit:

```bash
# Security checklist:
✓ No API keys in frontend code
✓ JWT tokens never logged
✓ SQL queries parameterized (no concatenation)
✓ RLS policies block unauthorized access
✓ Error messages don't leak internals
✓ All dependencies pinned + audited

# Bug fixes (example):
- Frontend test found: "Edit note button disabled on first click"
  → Fix: event handler race condition
  → Write test that reproduces bug
  → Implement fix
  → Run test; confirm pass
  → Commit

# Dep audit:
npm audit --production
→ All vulnerabilities patched
```

Phase report: `docs/phase-reports/phase-M2-hardening.md`.

---

### Phase M+3: Staging Deploy (Agent) — 30 minutes

**Agent: deployer**

Deploys to staging (Vercel preview URL):

```bash
# Agent hands you:
# "Run: git push origin main"
# → Vercel auto-deploys

# Agent runs smoke tests on staging URL:
✓ /api/health returns 200
✓ Sign-up flow works
✓ Notes CRUD works
✓ No 500 errors in logs

# You test manually if you want
```

Phase report: `docs/phase-reports/phase-M3-staging.md`.

**Gate:** Staging works. Ready for production.

---

### Phase M+4: Production Deploy (Agent) — 45 minutes

**Agent: deployer** (mode=prod)

Sets up observability + domain + production deploy:

```bash
# Agent hands you (don't copy-paste; verify each):
1. Add Sentry API key to .env.production
2. Wire observability dashboard (Sentry + logs)
3. Add DNS records to your domain registrar:
   CNAME    notes.example.com    cname.vercel.app
4. Add production secrets to Vercel:
   DATABASE_URL=postgres://...
   JWT_SECRET=...
5. Run: git push origin main
6. Vercel auto-deploys to production

# Agent smoke-tests:
✓ https://notes.example.com loads
✓ Sign-up → Create note → Delete works
✓ Sentry captured a test error
```

Phase report: `docs/phase-reports/phase-M4-prod.md`.

**🎉 App is live!**

---

## What You Have Now

```
note-app/
├── .git/                             # All work committed
├── docs/
│   ├── briefing.md                   # Your discovery answers
│   └── phase-reports/                # Details per phase
│       ├── phase-01-demo.md
│       ├── phase-02-scaffolding.md
│       ├── phase-03-db-schema.md
│       ├── phase-04-auth-api.md
│       ├── phase-05-notes-api.md
│       ├── phase-K1-backend-test.md
│       ├── phase-K2-auth-screens.md
│       ├── phase-K3-notes-crud.md
│       ├── phase-M1-frontend-test.md
│       ├── phase-M2-hardening.md
│       ├── phase-M3-staging.md
│       └── phase-M4-prod.md
├── PLAN.md                           # Full phased plan
├── package.json                      # Next.js deps
├── src/
│   ├── pages/
│   │   ├── api/
│   │   │   ├── auth/
│   │   │   └── notes/
│   │   ├── login.tsx
│   │   ├── dashboard.tsx
│   │   └── index.tsx
│   └── ...
├── migrations/
│   ├── 001_create_users.sql
│   ├── 002_create_notes.sql
│   └── ...
└── https://notes.example.com         # Live app
```

---

## Key Insights

### Why This Works

1. **Phases are sequential** — Each phase gates on the previous one (demo → backend → frontend → hardening → deploy)
2. **Security built-in** — Not a final step; enforced from Phase 1 onward
3. **Test-driven** — Builders write tests first; testers verify end-to-end
4. **Hands-off agents** — You approve direction; agents do execution
5. **Full audit trail** — Every decision, bug, and fix documented in phase reports

### When to Intervene

- **After Phase 1 (Demo):** Approve direction or ask for changes
- **During phases:** Agent exits `needs_input`? You provide missing piece (API key, decision, etc.)
- **After Phase K+1 (Backend Test):** Review bug list; PM re-dispatches backend-builder for fixes
- **After Phase M+1 (Frontend Test):** Review bug list; PM re-dispatches frontend-builder for fixes
- **During Phase M+3 & M+4:** Verify staging/prod yourself; provide domain + secrets

---

## Troubleshooting

**Agent exited with error?**

Read the phase report. Most common issues:
- Missing environment variable → Agent exits `needs_input`
- Ambiguous acceptance criteria → Agent exits `blocked` (clarify with PM)
- Skill not available → Restart Claude Code

**Want to change something after a phase completes?**

PM re-dispatches the agent. You don't need to manually revert.

Example: "Staging has a bug in the notes editor."
- Report in Slack/GitHub
- PM dispatches hardener (or backend-builder) for fix
- New phase report written
- Proceed to next phase or re-deploy

**Want to see what happened in a phase?**

Read `docs/phase-reports/phase-NN-name.md`. Every decision, test, and commit is documented.

---

## Next Steps

1. **Start your own project:** Replace "note-app" with your idea
2. **Read [SECURITY_RULES.md](SECURITY_RULES.md)** for non-negotiable requirements
3. **Read [docs/design.md](docs/design.md)** if you want to understand the full architecture
4. **Join discussions** — feedback & edge cases help improve Marlo

---

## Need Help?

- **How does X phase work?** → Read `agents/X-builder.md` or `agents/X-tester.md`
- **What does the PM do?** → Read `skills/project-manager/SKILL.md`
- **What's the architecture?** → Read `docs/design.md`
- **What are the rules?** → Read `SECURITY_RULES.md`
- **Report a bug** → GitHub issues (coming soon)

**Good luck building! 🚀**
