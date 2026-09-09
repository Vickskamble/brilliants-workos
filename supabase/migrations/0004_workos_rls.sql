-- Brilliants Work OS — Migration 0004: RLS Policies
-- Run order: after 0003

-- ============================================================
-- Enable RLS on all tables
-- ============================================================
alter table public.workos_companies enable row level security;
alter table public.workos_profiles enable row level security;
alter table public.workos_teams enable row level security;
alter table public.workos_team_members enable row level security;
alter table public.workos_recurrences enable row level security;
alter table public.workos_tasks enable row level security;
alter table public.workos_targets enable row level security;
alter table public.workos_target_breakdowns enable row level security;
alter table public.workos_daily_standups enable row level security;
alter table public.workos_notifications enable row level security;
alter table public.workos_activity_log enable row level security;

-- ============================================================
-- COMPANIES
-- ============================================================
create policy "companies_select" on public.workos_companies
  for select using (
    public.is_workos_owner()
    or public.my_workos_company() = id
  );

create policy "companies_insert" on public.workos_companies
  for insert with check (
    public.is_workos_owner()
  );

create policy "companies_update" on public.workos_companies
  for update using (
    public.is_workos_owner()
    or (public.is_workos_admin() and public.my_workos_company() = id)
  );

create policy "companies_delete" on public.workos_companies
  for delete using (
    public.is_workos_owner()
  );

-- ============================================================
-- PROFILES
-- ============================================================
-- Owner/Admin: see all in their company
-- Member: see own profile + colleagues in same company
create policy "profiles_select" on public.workos_profiles
  for select using (
    public.is_workos_owner()
    or auth.uid() = user_id
    or (
      public.my_workos_company() = company_id
      and public.my_workos_role() in ('OWNER', 'ADMIN', 'MANAGER')
    )
    or public.my_workos_company() = company_id
  );

create policy "profiles_insert" on public.workos_profiles
  for insert with check (
    public.is_workos_owner()
    or public.is_workos_admin()
    or (
      auth.uid() = user_id
      and role = 'MEMBER'
      and company_id = public.my_workos_company()
    )
  );

create policy "profiles_update" on public.workos_profiles
  for update using (
    public.is_workos_owner()
    or (
      public.is_workos_admin()
      and public.my_workos_company() = company_id
    )
    or auth.uid() = user_id
  );

create policy "profiles_delete" on public.workos_profiles
  for delete using (
    public.is_workos_owner()
  );

-- ============================================================
-- TEAMS
-- ============================================================
create policy "teams_select" on public.workos_teams
  for select using (
    public.my_workos_company() = company_id
  );

create policy "teams_insert" on public.workos_teams
  for insert with check (
    public.is_workos_manager()
    and public.my_workos_company() = company_id
  );

create policy "teams_update" on public.workos_teams
  for update using (
    public.is_workos_manager()
    and public.my_workos_company() = company_id
  );

create policy "teams_delete" on public.workos_teams
  for delete using (
    public.is_workos_admin()
    and public.my_workos_company() = company_id
  );

-- ============================================================
-- TEAM MEMBERS
-- ============================================================
create policy "team_members_select" on public.workos_team_members
  for select using (
    exists (
      select 1 from public.workos_teams t
      where t.id = team_id and t.company_id = public.my_workos_company()
    )
  );

create policy "team_members_insert" on public.workos_team_members
  for insert with check (
    public.is_workos_manager()
    and exists (
      select 1 from public.workos_teams t
      where t.id = team_id and t.company_id = public.my_workos_company()
    )
  );

create policy "team_members_update" on public.workos_team_members
  for update using (
    public.is_workos_manager()
    and exists (
      select 1 from public.workos_teams t
      where t.id = team_id and t.company_id = public.my_workos_company()
    )
  );

create policy "team_members_delete" on public.workos_team_members
  for delete using (
    public.is_workos_manager()
    and exists (
      select 1 from public.workos_teams t
      where t.id = team_id and t.company_id = public.my_workos_company()
    )
  );

-- ============================================================
-- RECURRENCES
-- ============================================================
create policy "recurrences_select" on public.workos_recurrences
  for select using (
    public.my_workos_company() = company_id
  );

create policy "recurrences_insert" on public.workos_recurrences
  for insert with check (
    public.is_workos_manager()
    and public.my_workos_company() = company_id
  );

create policy "recurrences_update" on public.workos_recurrences
  for update using (
    public.is_workos_manager()
    and public.my_workos_company() = company_id
  );

create policy "recurrences_delete" on public.workos_recurrences
  for delete using (
    public.is_workos_admin()
    and public.my_workos_company() = company_id
  );

-- ============================================================
-- TASKS
-- ============================================================
-- Everyone in company can see tasks (role-scoped)
-- Assignee can update their own task status
-- Manager/Admin can do full CRUD
create policy "tasks_select" on public.workos_tasks
  for select using (
    public.my_workos_company() = company_id
  );

create policy "tasks_insert" on public.workos_tasks
  for insert with check (
    public.is_workos_manager()
    and public.my_workos_company() = company_id
  );

create policy "tasks_update" on public.workos_tasks
  for update using (
    public.my_workos_company() = company_id
    and (
      public.is_workos_manager()
      or assigned_to = public.my_workos_profile()
    )
  );

create policy "tasks_delete" on public.workos_tasks
  for delete using (
    public.is_workos_admin()
    and public.my_workos_company() = company_id
  );

-- ============================================================
-- TARGETS
-- ============================================================
create policy "targets_select" on public.workos_targets
  for select using (
    public.my_workos_company() = company_id
  );

create policy "targets_insert" on public.workos_targets
  for insert with check (
    public.is_workos_manager()
    and public.my_workos_company() = company_id
  );

create policy "targets_update" on public.workos_targets
  for update using (
    public.is_workos_manager()
    and public.my_workos_company() = company_id
  );

create policy "targets_delete" on public.workos_targets
  for delete using (
    public.is_workos_admin()
    and public.my_workos_company() = company_id
  );

-- ============================================================
-- TARGET BREAKDOWNS
-- ============================================================
create policy "target_breakdowns_select" on public.workos_target_breakdowns
  for select using (
    exists (
      select 1 from public.workos_targets t
      where t.id = target_id and t.company_id = public.my_workos_company()
    )
  );

-- Only system (SECURITY DEFINER functions) inserts target breakdowns
-- No direct insert/update/delete policies

-- ============================================================
-- DAILY STANDUPS
-- ============================================================
-- Members can see their own + manager/admin can see team's
create policy "standups_select" on public.workos_daily_standups
  for select using (
    public.my_workos_company() = company_id
    and (
      profile_id = public.my_workos_profile()
      or public.is_workos_manager()
    )
  );

create policy "standups_insert" on public.workos_daily_standups
  for insert with check (
    public.my_workos_company() = company_id
    and profile_id = public.my_workos_profile()
  );

create policy "standups_update" on public.workos_daily_standups
  for update using (
    public.my_workos_company() = company_id
    and (
      profile_id = public.my_workos_profile()
      or public.is_workos_manager()
    )
  );

create policy "standups_delete" on public.workos_daily_standups
  for delete using (
    public.is_workos_admin()
    and public.my_workos_company() = company_id
  );

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
-- Users can only see their own notifications
create policy "notifications_select" on public.workos_notifications
  for select using (
    user_id = auth.uid()
  );

create policy "notifications_update" on public.workos_notifications
  for update using (
    user_id = auth.uid()
  );

create policy "notifications_delete" on public.workos_notifications
  for delete using (
    user_id = auth.uid()
  );

-- Inserts are done via SECURITY DEFINER functions only

-- ============================================================
-- ACTIVITY LOG
-- ============================================================
-- Read-only for admins, no direct writes
create policy "activity_log_select" on public.workos_activity_log
  for select using (
    public.is_workos_admin()
    and public.my_workos_company() = company_id
  );

-- No insert/update/delete policies — only SECURITY DEFINER functions write
