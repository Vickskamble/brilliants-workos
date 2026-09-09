-- Brilliants Work OS — Migration 0003: Functions & Triggers
-- Run order: after 0002

-- ============================================================
-- AUTH HELPERS (all SECURITY DEFINER for RLS safety)
-- ============================================================

-- Returns the caller's role in their company
create or replace function public.my_workos_role()
returns public.workos_user_role
language sql
stable
security definer
set search_path = ''
as $$
  select role from public.workos_profiles
  where user_id = auth.uid()
  limit 1;
$$;

-- Returns the caller's company_id
create or replace function public.my_workos_company()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select company_id from public.workos_profiles
  where user_id = auth.uid()
  limit 1;
$$;

-- Returns the caller's profile_id
create or replace function public.my_workos_profile()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select id from public.workos_profiles
  where user_id = auth.uid()
  limit 1;
$$;

create or replace function public.is_workos_owner()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.my_workos_role() = 'OWNER';
$$;

create or replace function public.is_workos_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.my_workos_role() in ('OWNER', 'ADMIN');
$$;

create or replace function public.is_workos_manager()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.my_workos_role() in ('OWNER', 'ADMIN', 'MANAGER');
$$;

-- ============================================================
-- AUTO-CREATE PROFILE ON SIGNUP
-- ============================================================
-- Note: Profile is NOT auto-created on signup because company_id is required.
-- Instead, profiles are created when:
--   1. Owner creates their company (first user)
--   2. Admin/Manager invites a member (adds to company)
-- This is handled at the application level.

-- ============================================================
-- PROTECT PRIVILEGES (prevent role escalation)
-- ============================================================
create or replace function public.protect_workos_profile_privileges()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Only OWNER can change role or company_id
  if (old.role is distinct from new.role or old.company_id is distinct from new.company_id) then
    if not public.is_workos_owner() then
      raise exception 'Only OWNER can modify role or company assignment';
    end if;
  end if;
  -- Users can't change their own user_id
  if (old.user_id is distinct from new.user_id) then
    raise exception 'Cannot change user_id';
  end if;
  return new;
end;
$$;

create trigger protect_profile_privileges
  before update on public.workos_profiles
  for each row execute function public.protect_workos_profile_privileges();

-- ============================================================
-- TARGET AUTO-BREAKDOWN
-- ============================================================
create or replace function public.create_target_breakdowns(p_target_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_target record;
  v_working_days int;
  v_weeks int;
  v_daily numeric;
  v_weekly numeric;
begin
  select * into v_target from public.workos_targets where id = p_target_id;
  if not found then return; end if;

  -- Calculate working days (Mon-Fri) in period
  v_working_days := (
    select count(*)
    from generate_series(v_target.period_start, v_target.period_end, '1 day'::interval) d
    where extract(dow from d) between 1 and 5
  );

  if v_working_days = 0 then v_working_days := 1; end if;

  v_weeks := greatest(1, ceil(v_working_days / 5.0)::int);
  v_daily := v_target.target_value / v_working_days;
  v_weekly := v_target.target_value / v_weeks;

  insert into public.workos_target_breakdowns (target_id, daily_value, weekly_value, notes)
  values (
    p_target_id,
    round(v_daily, 2),
    round(v_weekly, 2),
    format('Auto: %s working days, %s weeks', v_working_days, v_weeks)
  );
end;
$$;

-- Trigger: auto-create breakdown when target is inserted
create or replace function public.trigger_target_breakdown()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.create_target_breakdowns(new.id);
  return new;
end;
$$;

create trigger target_auto_breakdown
  after insert on public.workos_targets
  for each row execute function public.trigger_target_breakdown();

-- ============================================================
-- PERFORMANCE SCORE CALCULATOR
-- ============================================================
create or replace function public.get_performance_score(
  p_profile_id uuid,
  p_start_date date,
  p_end_date date
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_company_id uuid;
  v_assigned bigint;
  v_completed bigint;
  v_completed_on_time bigint;
  v_target_total numeric;
  v_target_achieved numeric;
  v_task_completion numeric;
  v_on_time_rate numeric;
  v_target_achievement numeric;
  v_overall numeric;
  v_band public.performance_band;
begin
  -- Get company
  select company_id into v_company_id
  from public.workos_profiles where id = p_profile_id;
  if not found then return '{"error": "profile not found"}'::jsonb; end if;

  -- Task stats
  select
    count(*),
    count(*) filter (where status = 'COMPLETED'),
    count(*) filter (where status = 'COMPLETED' and completed_at <= due_date + coalesce(due_time, '23:59:59'))
  into v_assigned, v_completed, v_completed_on_time
  from public.workos_tasks
  where assigned_to = p_profile_id
    and due_date between p_start_date and p_end_date;

  -- Target stats
  select
    coalesce(sum(target_value), 0),
    coalesce(sum(current_value), 0)
  into v_target_total, v_target_achieved
  from public.workos_targets
  where profile_id = p_profile_id
    and period_start >= p_start_date
    and period_end <= p_end_date;

  -- Calculate percentages
  v_task_completion := case when v_assigned > 0 then (v_completed::numeric / v_assigned * 100) else 0 end;
  v_on_time_rate := case when v_completed > 0 then (v_completed_on_time::numeric / v_completed * 100) else 0 end;
  v_target_achievement := case when v_target_total > 0 then least(v_target_achieved / v_target_total * 100, 100) else 0 end;

  -- Weighted overall: 35% tasks, 40% targets, 25% on-time
  v_overall := (v_task_completion * 0.35) + (v_target_achievement * 0.40) + (v_on_time_rate * 0.25);

  -- Band
  v_band := case
    when v_overall >= 85 then 'EXCELLENT'::public.performance_band
    when v_overall >= 70 then 'GOOD'::public.performance_band
    when v_overall >= 50 then 'AVERAGE'::public.performance_band
    else 'NEEDS_ATTENTION'::public.performance_band
  end;

  return jsonb_build_object(
    'task_completion', round(v_task_completion, 1),
    'target_achievement', round(v_target_achievement, 1),
    'on_time_rate', round(v_on_time_rate, 1),
    'overall', round(v_overall, 1),
    'band', v_band::text,
    'assigned', v_assigned,
    'completed', v_completed,
    'completed_on_time', v_completed_on_time,
    'target_total', v_target_total,
    'target_achieved', v_target_achieved
  );
end;
$$;

-- ============================================================
-- DASHBOARD STATS
-- ============================================================
create or replace function public.get_dashboard_stats(p_company_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_today date := current_date;
  v_result jsonb;
  v_total_team bigint;
  v_total_tasks bigint;
  v_completed bigint;
  v_pending bigint;
  v_overdue bigint;
  v_target_total numeric;
  v_target_achieved numeric;
begin
  -- Team count
  select count(*) into v_total_team
  from public.workos_profiles
  where company_id = p_company_id and is_active = true;

  -- Today's tasks
  select
    count(*),
    count(*) filter (where status = 'COMPLETED'),
    count(*) filter (where status in ('TODO', 'IN_PROGRESS')),
    count(*) filter (where status in ('TODO', 'IN_PROGRESS') and due_date < v_today)
  into v_total_tasks, v_completed, v_pending, v_overdue
  from public.workos_tasks
  where company_id = p_company_id
    and (due_date = v_today or (status in ('TODO', 'IN_PROGRESS') and due_date <= v_today));

  -- Current month targets
  select
    coalesce(sum(target_value), 0),
    coalesce(sum(current_value), 0)
  into v_target_total, v_target_achieved
  from public.workos_targets
  where company_id = p_company_id
    and period_start >= date_trunc('month', v_today)::date
    and period_end <= (date_trunc('month', v_today) + interval '1 month - 1 day')::date;

  v_result := jsonb_build_object(
    'total_team', v_total_team,
    'total_tasks', v_total_tasks,
    'completed', v_completed,
    'pending', v_pending,
    'overdue', v_overdue,
    'target_achievement', case when v_target_total > 0
      then round(v_target_achieved / v_target_total * 100, 1)
      else 0 end,
    'target_achieved', v_target_achieved,
    'target_total', v_target_total
  );

  return v_result;
end;
$$;

-- ============================================================
-- ESCALATION CHECK
-- ============================================================
create or replace function public.check_escalations(p_company_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_task record;
  v_days_overdue int;
  v_manager_user_id uuid;
  v_admin_user_id uuid;
begin
  for v_task in
    select t.*, p.full_name as assignee_name, p.user_id as assignee_user_id
    from public.workos_tasks t
    join public.workos_profiles p on p.id = t.assigned_to
    where t.company_id = p_company_id
      and t.status in ('TODO', 'IN_PROGRESS')
      and t.due_date < current_date
  loop
    v_days_overdue := current_date - v_task.due_date;

    -- Day 1: reminder to employee
    if v_days_overdue = 1 then
      insert into public.workos_notifications (company_id, user_id, title, body, type, reference_id, reference_type)
      values (
        p_company_id,
        v_task.assignee_user_id,
        '⚠️ Task Overdue',
        format('"%s" is overdue by %s day(s)', v_task.title, v_days_overdue),
        'TASK_OVERDUE',
        v_task.id,
        'task'
      );
    end if;

    -- Day 2+: notify manager
    if v_days_overdue >= 2 then
      -- Find the task creator (manager)
      select user_id into v_manager_user_id
      from public.workos_profiles where id = v_task.assigned_by;

      if v_manager_user_id is not null and v_manager_user_id != v_task.assignee_user_id then
        insert into public.workos_notifications (company_id, user_id, title, body, type, reference_id, reference_type)
        values (
          p_company_id,
          v_manager_user_id,
          '🔴 Escalation: Task Overdue',
          format('%s has overdue task "%s" (%s days)', v_task.assignee_name, v_task.title, v_days_overdue),
          'TASK_ESCALATION',
          v_task.id,
          'task'
        );
      end if;
    end if;

    -- Day 3+: notify admin/owner
    if v_days_overdue >= 3 then
      for v_admin_user_id in
        select user_id from public.workos_profiles
        where company_id = p_company_id and role in ('OWNER', 'ADMIN')
          and user_id != v_task.assignee_user_id
      loop
        insert into public.workos_notifications (company_id, user_id, title, body, type, reference_id, reference_type)
        values (
          p_company_id,
          v_admin_user_id,
          '🚨 Critical: Task Overdue 3+ Days',
          format('%s has task "%s" overdue by %s days', v_task.assignee_name, v_task.title, v_days_overdue),
          'TASK_CRITICAL',
          v_task.id,
          'task'
        );
      end loop;
    end if;
  end loop;
end;
$$;

-- ============================================================
-- GET STAFF LIST (similar to TryOn pattern)
-- ============================================================
create or replace function public.get_workos_staff_list()
returns table (
  profile_id uuid,
  user_id uuid,
  full_name text,
  email text,
  phone text,
  avatar_url text,
  role public.workos_user_role,
  department public.department,
  is_active boolean,
  joined_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_company uuid;
  v_role public.workos_user_role;
begin
  v_company := public.my_workos_company();
  v_role := public.my_workos_role();

  if v_company is null then
    return;
  end if;

  return query
  select
    p.id,
    p.user_id,
    p.full_name,
    au.email::text,
    p.phone,
    p.avatar_url,
    p.role,
    p.department,
    p.is_active,
    p.joined_at
  from public.workos_profiles p
  join auth.users au on au.id = p.user_id
  where p.company_id = v_company
    and (
      v_role in ('OWNER', 'ADMIN')
      or p.user_id = auth.uid()
    )
  order by p.full_name;
end;
$$;

-- ============================================================
-- CREATE COMPANY (bootstrap) — SECURITY DEFINER
-- Allows a brand-new authenticated user (no profile yet) to
-- create their first company and become its OWNER.
-- Bypasses RLS so the fresh user isn't blocked by is_workos_owner().
-- ============================================================
create or replace function public.create_workos_company(
  p_name text,
  p_slug text,
  p_industry text default null
)
returns public.workos_profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_company_id uuid;
  v_profile public.workos_profiles;
begin
  if exists (
    select 1 from public.workos_profiles where user_id = auth.uid()
  ) then
    raise exception 'User already belongs to a company';
  end if;

  insert into public.workos_companies (name, slug, industry)
  values (p_name, p_slug, p_industry)
  returning id into v_company_id;

  insert into public.workos_profiles (
    user_id, company_id, full_name, role, department
  ) values (
    auth.uid(),
    v_company_id,
    coalesce(
      nullif(auth.jwt() ->> 'full_name', ''),
      'Owner'
    ),
    'OWNER',
    'OTHER'
  )
  returning * into v_profile;

  return v_profile;
end;
$$;

grant execute on function public.create_workos_company(text, text, text) to authenticated;
grant execute on function public.get_workos_staff_list() to authenticated;
grant execute on function public.get_performance_score(uuid, date, date) to authenticated;
grant execute on function public.get_dashboard_stats(uuid) to authenticated;
