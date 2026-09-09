# Brilliants Work OS

Team Task + Performance + Target Management System for Brilliants.

> "Har team member ko pata ho ki aaj kya karna hai, manager ko pata ho kisne kya kiya,
> aur business ko pata ho target ke against progress kya hai."

**Live:** https://vickskamble.github.io/brilliants-workos/

---

## Features

### 1. Auth & Roles (Multi-tenant)
- Email/password Sign Up, Login, Forgot Password (reset email)
- Each company is a tenant — role-based access: **Owner / Admin / Manager / Member**
- First user to create a company becomes the **Owner**
- **Real invites** (`workos_invites`): existing users are added instantly;
  new users are **auto-joined on signup** (`accept_workos_invite`)
- Every table is scoped by `company_id` via Postgres RLS
- Role model:
  - Owner — sees everything, manages company
  - Admin — same as owner except company deletion/owner-transfer
  - Manager — manages members, assigns tasks, sets targets
  - Member — sees own tasks/targets/standups only

### 2. Dashboard & Analytics
- Gradient analytics dashboard with KPI cards, task status donut, and 7-day activity chart
- Monthly target achievement gauge (₹ achieved vs. total, remaining)
- **Top Performers leaderboard** (35% tasks + 40% targets + 25% on-time)
- Daily Stand-Up card: "X of Y submitted today" + per-member Plan/Report dots
- Quick actions: Assign Task, Set Target, Invite Member, Overdue Tasks

### 3. Tasks
- Assign tasks with member, priority (**URGENT / HIGH / MEDIUM / LOW**),
  due date & time, and an optional target value
- **My Tasks** (today) and **Overdue Tasks** views
- Status flow: `TODO → IN_PROGRESS → COMPLETED`
- Completion records result, comment, and **actual value**
- Actual value rolls into the member's active targets automatically via
  `record_task_actual_value` RPC
- Assignment creates a **real-time notification** for the assignee

### 4. Targets
- Set targets per member across 10 types (sales, leads, calls, meetings, demos,
  conversions, revenue, posts, reels, tasks)
- Periods: daily / weekly / monthly / quarterly / yearly
- Auto daily/weekly breakdown (working-days calculation)
- Live progress bar + total, achieved, remainder per member
- **Performance score** — 35% task completion + 40% target achievement + 25% on-time rate

### 5. Daily Stand-up
- **Morning Plan** — top 3 tasks for the day (pre-filled from today's tasks)
- **Evening Report** — completed today (required), pending today, blockers
- Saved per profile per day; managers see the whole team's status on the dashboard

### 6. Notifications (Real-time)
- Supabase Realtime channel, live unread **badge on the Alerts tab**
- Triggered on: task assigned, task overdue, escalation, team join
- Tapping a task notification opens the task detail directly

### 7. Escalations (Automatic)
- Checks run on every task insert/update (idempotent, de-duplicated)
- **Day 1** overdue → employee, **Day 2** → manager, **Day 3+** → admin

### 8. Teams
- Departments: SALES / MARKETING / DEVELOPMENT / SUPPORT / OPERATIONS / OTHER
- Create teams (name, description, optional manager)
- Tap a team to add/remove members from a bottom sheet

### 9. Performance & Leaderboard
- Overall score ring with band (**EXCELLENT / GOOD / AVERAGE / NEEDS ATTENTION**)
- Task completion, target achievement, on-time rate breakdown
- Monthly snapshot via `get_performance_score` RPC
- Company `get_company_leaderboard` RPC powers the Top Performers section

---

## Pages / Routes

| Route | Page |
|---|---|
| `/login` `/signup` `/forgot-password` | Auth |
| `/home` | Main navigation hub (Dashboard / Tasks / Targets / Alerts / Team) |
| `/assign-task` | Assign a task |
| `/task-detail` | Task detail + status/result update |
| `/my-tasks`, `/overdue-tasks` | Task lists |
| `/set-target` | Set a target for a member |
| `/invite-member` | Email invite |
| `/member-detail` | Member performance profile |
| `/morning-plan`, `/evening-report` | Daily stand-up |
| `/notifications` | Alerts center |

---

## Tech Stack

- **Frontend:** Flutter (Web + Mobile), flutter_bloc, clean architecture
- **Backend:** Supabase — Postgres (RLS), Auth, Realtime, RPC functions
- **Deployment:** GitHub Actions → GitHub Pages (auto-deploy on push to `main`)

## Setup

### 1. Migrations

Run in order via `supabase db push` (or the SQL editor):

1. `supabase/migrations/0001_workos_enums.sql`
2. `supabase/migrations/0002_workos_tables.sql`
3. `supabase/migrations/0003_workos_functions.sql`
4. `supabase/migrations/0004_workos_rls.sql`
5. `supabase/migrations/0005_workos_invites_and_notifications.sql`
6. `supabase/migrations/0006_workos_task_actual_value.sql`

7. `supabase/migrations/0007_workos_leaderboard.sql`

8. `supabase/migrations/0008_workos_realtime.sql`
### 2. Environment

Copy `.env.example` to `.env` and set credentials; also update `assets/env`:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### 3. Run

```bash
flutter pub get
flutter run -d chrome   # Web
flutter run -d windows  # Desktop
flutter run            # Mobile (device)
```

### 4. Deploy

Push to `main` — GitHub Actions builds `build/web` and publishes to GitHub Pages.

## Project Structure

```
lib/
├── core/          # Config, network, theme, widgets
├── data/          # Models, datasources, repositories
├── domain/        # Pure entities
└── presentation/  # BLoCs + Pages
supabase/migrations/  # SQL migrations
.github/workflows/    # Deploy pipeline
```

## Database Schema (Key Tables)

- `workos_companies` — tenant root
- `workos_profiles` — user profiles (extends auth.users)
- `workos_teams` / `workos_team_members` — teams
- `workos_tasks` / `workos_notifications` — tasks & real-time alerts
- `workos_targets` / `workos_target_breakdowns` — targets & auto-breakdown
- `workos_daily_standups` — morning/evening reports
- `workos_invites` — pending member invites
- `workos_activity_log` — audit trail

## Architecture Decisions

- **Multi-tenant**: `company_id` scoping via RLS (reuse TryOn pattern)
- **RLS**: all tables scoped by company; Owner sees all, Member sees own
- **Performance Score**: 35% tasks + 40% targets + 25% on-time
- **Target Auto-Breakdown**: monthly → daily (working-days calculation)
- **Escalation**: Day 1 → employee, Day 2 → manager, Day 3+ → admin
- **Security**: members write their own standups/completions via
  SECURITY DEFINER RPCs (record_task_actual_value, accept_workos_invite)