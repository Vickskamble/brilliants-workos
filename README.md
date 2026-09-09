# Brilliants Work OS

Team Task + Performance + Target Management System for Brilliants.

> "Har team member ko pata ho ki aaj kya karna hai, manager ko pata ho kisne kya kiya, aur business ko pata ho target ke against progress kya hai."

## Tech Stack

- **Frontend**: Flutter (Web + Mobile)
- **Backend**: Supabase (PostgreSQL, Auth, Realtime)
- **State Management**: flutter_bloc
- **Architecture**: Clean Architecture (data / domain / presentation)

## Features (V1 Core)

- 🔐 Multi-tenant Auth (Owner / Admin / Manager / Member roles)
- 👥 Team Management (departments, teams, members)
- 📋 Task Assignment & Tracking (priority, status, due dates)
- 🎯 Target Management (sales, calls, leads, demos, etc.)
- ✅ Daily Standup (morning plan + evening report)
- 🔔 In-app Notifications (task assigned, reminders, overdue, escalation)
- 📊 Dashboard (KPIs, team status, performance)

## Setup

### 1. Database Migrations

Run the SQL migrations in order via Supabase SQL Editor:

1. `supabase/migrations/0001_workos_enums.sql`
2. `supabase/migrations/0002_workos_tables.sql`
3. `supabase/migrations/0003_workos_functions.sql`
4. `supabase/migrations/0004_workos_rls.sql`

### 2. Configure Environment

Copy `.env.example` to `.env` and set your Supabase credentials:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

Also update `assets/env` for web builds.

### 3. Run

```bash
flutter pub get
flutter run -d chrome   # Web
flutter run -d windows  # Desktop
flutter run            # Mobile (device)
```

## Project Structure

```
lib/
├── core/          # Config, network, theme, utils, widgets
├── data/          # Models, datasources, repositories
├── domain/        # Pure entities
└── presentation/  # BLoCs + Pages
```

## Database Schema (Key Tables)

- `workos_companies` — tenant root
- `workos_profiles` — user profiles (extends auth.users)
- `workos_teams` / `workos_team_members` — teams
- `workos_tasks` — task assignments
- `workos_targets` / `workos_target_breakdowns` — targets & auto-breakdown
- `workos_daily_standups` — morning/evening reports
- `workos_notifications` — in-app alerts
- `workos_activity_log` — audit trail

## Architecture Decisions

- **Multi-tenant**: `company_id` scoping via RLS (reuse TryOn pattern)
- **RLS**: All tables scoped by company; Owner sees all, Member sees own
- **Performance Score**: 35% task completion + 40% target achievement + 25% on-time rate
- **Target Auto-Breakdown**: Monthly → Daily (working days calculation)
- **Escalation**: Day 1 → employee, Day 2 → manager, Day 3 → admin
