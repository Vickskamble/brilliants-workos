-- Brilliants Work OS — Migration 0002: Tables
-- Run order: after 0001

-- ============================================================
-- COMPANIES
-- ============================================================
create table public.workos_companies (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  slug        text not null unique,
  logo_url    text,
  industry    text,
  status      text not null default 'ACTIVE' check (status in ('ACTIVE', 'SUSPENDED')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

comment on table public.workos_companies is 'Tenant companies in Brilliants Work OS';

-- ============================================================
-- PROFILES (extends auth.users)
-- ============================================================
create table public.workos_profiles (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  company_id  uuid not null references public.workos_companies(id) on delete cascade,
  full_name   text not null default '',
  phone       text,
  avatar_url  text,
  role        public.workos_user_role not null default 'MEMBER',
  department  public.department not null default 'OTHER',
  is_active   boolean not null default true,
  joined_at   timestamptz not null default now(),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),

  constraint workos_profiles_user_company unique (user_id, company_id)
);

comment on table public.workos_profiles is 'User profiles scoped to a company';

create index workos_profiles_company_idx on public.workos_profiles (company_id);
create index workos_profiles_user_idx on public.workos_profiles (user_id);
create index workos_profiles_role_idx on public.workos_profiles (company_id, role);

-- ============================================================
-- TEAMS
-- ============================================================
create table public.workos_teams (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.workos_companies(id) on delete cascade,
  name        text not null,
  description text,
  manager_id  uuid references public.workos_profiles(id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),

  constraint workos_teams_company_name unique (company_id, name)
);

comment on table public.workos_teams is 'Teams within a company';

create index workos_teams_company_idx on public.workos_teams (company_id);

-- ============================================================
-- TEAM MEMBERS (junction table)
-- ============================================================
create table public.workos_team_members (
  id          uuid primary key default gen_random_uuid(),
  team_id     uuid not null references public.workos_teams(id) on delete cascade,
  profile_id  uuid not null references public.workos_profiles(id) on delete cascade,
  joined_at   timestamptz not null default now(),

  constraint workos_team_members_unique unique (team_id, profile_id)
);

comment on table public.workos_team_members is 'Many-to-many: teams ↔ profiles';

create index workos_team_members_team_idx on public.workos_team_members (team_id);
create index workos_team_members_profile_idx on public.workos_team_members (profile_id);

-- ============================================================
-- RECURRENCES (templates for recurring tasks)
-- ============================================================
create table public.workos_recurrences (
  id                  uuid primary key default gen_random_uuid(),
  company_id          uuid not null references public.workos_companies(id) on delete cascade,
  template_title      text not null,
  template_description text,
  assigned_to         uuid references public.workos_profiles(id) on delete set null,
  priority            public.task_priority not null default 'MEDIUM',
  recurrence_type     public.recurrence_type not null,
  day_of_week         int[],               -- for WEEKLY: [1,3,5] = Mon,Wed,Fri
  day_of_month        int,                 -- for MONTHLY: e.g. 28
  target_value        numeric,
  is_active           boolean not null default true,
  created_at          timestamptz not null default now()
);

comment on table public.workos_recurrences is 'Templates for auto-generating recurring tasks';

create index workos_recurrences_company_idx on public.workos_recurrences (company_id);
create index workos_recurrences_active_idx on public.workos_recurrences (company_id, is_active) where is_active = true;

-- ============================================================
-- TASKS
-- ============================================================
create table public.workos_tasks (
  id              uuid primary key default gen_random_uuid(),
  company_id      uuid not null references public.workos_companies(id) on delete cascade,
  title           text not null,
  description     text,
  assigned_to     uuid references public.workos_profiles(id) on delete set null,
  assigned_by     uuid references public.workos_profiles(id) on delete set null,
  team_id         uuid references public.workos_teams(id) on delete set null,
  priority        public.task_priority not null default 'MEDIUM',
  status          public.task_status not null default 'TODO',
  due_date        date,
  due_time        time,
  completed_at    timestamptz,
  result          text,                    -- employee fills on completion
  comment         text,                    -- employee comment
  attachment_url  text,                    -- proof/document link
  actual_value    numeric,                 -- actual achievement number
  target_value    numeric,                 -- expected target number
  is_recurring    boolean not null default false,
  recurrence_id   uuid references public.workos_recurrences(id) on delete set null,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

comment on table public.workos_tasks is 'All tasks assigned within a company';

create index workos_tasks_company_idx on public.workos_tasks (company_id);
create index workos_tasks_assigned_idx on public.workos_tasks (assigned_to, status, due_date);
create index workos_tasks_due_idx on public.workos_tasks (company_id, due_date) where status in ('TODO', 'IN_PROGRESS');
create index workos_tasks_status_idx on public.workos_tasks (company_id, status);
create index workos_tasks_team_idx on public.workos_tasks (team_id) where team_id is not null;

-- ============================================================
-- TARGETS
-- ============================================================
create table public.workos_targets (
  id            uuid primary key default gen_random_uuid(),
  company_id    uuid not null references public.workos_companies(id) on delete cascade,
  profile_id    uuid references public.workos_profiles(id) on delete cascade,
  team_id       uuid references public.workos_teams(id) on delete cascade,
  target_type   public.target_type not null,
  period_type   text not null check (period_type in ('DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'YEARLY')),
  period_start  date not null,
  period_end    date not null,
  target_value  numeric not null check (target_value >= 0),
  current_value numeric not null default 0,
  currency      text not null default 'INR',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),

  -- At least one of profile_id or team_id must be set
  constraint workos_targets_owner_check check (
    profile_id is not null or team_id is not null
  )
);

comment on table public.workos_targets is 'Targets for employees, teams, or company';

create index workos_targets_company_idx on public.workos_targets (company_id);
create index workos_targets_profile_idx on public.workos_targets (profile_id, period_start) where profile_id is not null;
create index workos_targets_team_idx on public.workos_targets (team_id, period_start) where team_id is not null;
create index workos_targets_period_idx on public.workos_targets (company_id, target_type, period_start);

-- ============================================================
-- TARGET BREAKDOWNS (auto-generated sub-targets)
-- ============================================================
create table public.workos_target_breakdowns (
  id          uuid primary key default gen_random_uuid(),
  target_id   uuid not null references public.workos_targets(id) on delete cascade,
  daily_value numeric,
  weekly_value numeric,
  notes       text,
  created_at  timestamptz not null default now()
);

comment on table public.workos_target_breakdowns is 'Auto-calculated daily/weekly breakdowns of targets';

create index workos_target_breakdowns_target_idx on public.workos_target_breakdowns (target_id);

-- ============================================================
-- DAILY STANDUPS
-- ============================================================
create table public.workos_daily_standups (
  id              uuid primary key default gen_random_uuid(),
  company_id      uuid not null references public.workos_companies(id) on delete cascade,
  profile_id      uuid not null references public.workos_profiles(id) on delete cascade,
  standup_date    date not null default current_date,
  plan_task_1     text,
  plan_task_2     text,
  plan_task_3     text,
  completed_today text,
  pending_today   text,
  blockers        text,
  status          text not null default 'DRAFT' check (status in ('DRAFT', 'SUBMITTED', 'REVIEWED')),
  reviewed_by     uuid references public.workos_profiles(id) on delete set null,
  reviewed_at     timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),

  constraint workos_standups_profile_date unique (profile_id, standup_date)
);

comment on table public.workos_daily_standups is 'Morning plans and evening reports';

create index workos_standups_company_idx on public.workos_daily_standups (company_id, standup_date);
create index workos_standups_profile_idx on public.workos_daily_standups (profile_id, standup_date);

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
create table public.workos_notifications (
  id              uuid primary key default gen_random_uuid(),
  company_id      uuid not null references public.workos_companies(id) on delete cascade,
  user_id         uuid not null references auth.users(id) on delete cascade,
  title           text not null,
  body            text not null,
  type            text not null,
  reference_id    uuid,
  reference_type  text,
  is_read         boolean not null default false,
  channel         public.notification_channel not null default 'IN_APP',
  created_at      timestamptz not null default now()
);

comment on table public.workos_notifications is 'In-app and channel notifications';

create index workos_notifications_user_idx on public.workos_notifications (user_id, is_read, created_at desc);
create index workos_notifications_company_idx on public.workos_notifications (company_id, created_at desc);

-- ============================================================
-- ACTIVITY LOG (audit trail)
-- ============================================================
create table public.workos_activity_log (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.workos_companies(id) on delete cascade,
  actor_id    uuid not null references public.workos_profiles(id) on delete cascade,
  action      text not null,
  entity_type text not null,
  entity_id   uuid not null,
  metadata    jsonb,
  created_at  timestamptz not null default now()
);

comment on table public.workos_activity_log is 'Immutable audit trail of all actions';

create index workos_activity_log_company_idx on public.workos_activity_log (company_id, created_at desc);
create index workos_activity_log_entity_idx on public.workos_activity_log (entity_type, entity_id);

-- ============================================================
-- UPDATED_AT TRIGGER (reuse pattern from TryOn)
-- ============================================================
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Apply to all tables with updated_at
create trigger set_updated_at before update on public.workos_companies
  for each row execute function public.set_updated_at();

create trigger set_updated_at before update on public.workos_profiles
  for each row execute function public.set_updated_at();

create trigger set_updated_at before update on public.workos_teams
  for each row execute function public.set_updated_at();

create trigger set_updated_at before update on public.workos_tasks
  for each row execute function public.set_updated_at();

create trigger set_updated_at before update on public.workos_targets
  for each row execute function public.set_updated_at();

create trigger set_updated_at before update on public.workos_daily_standups
  for each row execute function public.set_updated_at();
