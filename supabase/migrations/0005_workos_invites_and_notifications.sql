-- Brilliants Work OS — Migration 0005: Invites, Assignment Notifications, Escalations
-- Run order: after 0004

-- ============================================================
-- INVITES
-- ============================================================
create table public.workos_invites (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.workos_companies(id) on delete cascade,
  email       text not null,
  full_name   text not null default '',
  role        public.workos_user_role not null default 'MEMBER',
  department  public.department not null default 'OTHER',
  status      text not null default 'PENDING' check (status in ('PENDING', 'ACCEPTED', 'EXPIRED')),
  token       text not null default md5(random()::text || clock_timestamp()::text),
  invited_by  uuid references public.workos_profiles(id) on delete set null,
  created_at  timestamptz not null default now(),
  expires_at  timestamptz not null default now() + interval '7 days',

  constraint workos_invites_company_email unique (company_id, email)
);

comment on table public.workos_invites is 'Pending invitations to join a company';

create index workos_invites_email_idx on public.workos_invites (email, status);

alter table public.workos_invites enable row level security;

-- Inviters/admin can see invites for their company
create policy "invites_select" on public.workos_invites
  for select using (
    public.my_workos_company() = company_id
    and (
      public.is_workos_admin()
      or invited_by = public.my_workos_profile()
    )
  );

create policy "invites_insert" on public.workos_invites
  for insert with check (
    public.is_workos_manager()
    and public.my_workos_company() = company_id
  );

create policy "invites_delete" on public.workos_invites
  for delete using (
    public.is_workos_admin()
    and public.my_workos_company() = company_id
  );

-- ============================================================
-- INVITE MEMBER (SECURITY DEFINER)
-- If the email already has a Supabase account -> creates the
-- workos_profile immediately and notifies them.
-- Otherwise -> stores a PENDING invite; the user is attached
-- automatically when they sign up (see accept_workos_invite).
-- ============================================================
create or replace function public.invite_workos_member(
  p_email text,
  p_full_name text,
  p_role public.workos_user_role default 'MEMBER',
  p_department public.department default 'OTHER'
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_company_id uuid;
  v_is_manager boolean;
  v_target_user uuid;
  v_existing uuid;
  v_profile public.workos_profiles;
begin
  v_company_id := public.my_workos_company();
  v_is_manager := public.is_workos_manager();

  if v_company_id is null or not v_is_manager then
    raise exception 'Only managers can invite members';
  end if;

  select id into v_target_user
  from auth.users u
  where lower(u.email) = lower(p_email)
  limit 1;

  if v_target_user is not null then
    -- Already has an account: attach directly (unless already in a company)
    select id into v_existing
    from public.workos_profiles
    where user_id = v_target_user
    limit 1;

    if v_existing is not null then
      if exists (select 1 from public.workos_profiles where id = v_existing and company_id = v_company_id) then
        return jsonb_build_object('status', 'ALREADY_MEMBER', 'profile_id', v_existing);
      end if;
      return jsonb_build_object('status', 'IN_OTHER_COMPANY');
    end if;

    insert into public.workos_profiles (user_id, company_id, full_name, role, department)
    values (v_target_user, v_company_id, p_full_name, p_role, p_department)
    returning * into v_profile;

    insert into public.workos_notifications (company_id, user_id, title, body, type, reference_id, reference_type)
    values (
      v_company_id,
      v_target_user,
      'Welcome to the team',
      format('You were added to %s as a %s.', (select name from public.workos_companies where id = v_company_id), p_role::text),
      'TEAM_JOIN',
      v_profile.id,
      'profile'
    );

    return jsonb_build_object('status', 'ADDED', 'profile_id', v_profile.id);
  end if;

  -- No account yet: store a pending invite
  insert into public.workos_invites (company_id, email, full_name, role, department, invited_by)
  values (v_company_id, lower(p_email), p_full_name, p_role, p_department, public.my_workos_profile())
  on conflict (company_id, email)
  do update set full_name = excluded.full_name, role = excluded.role,
                department = excluded.department, status = 'PENDING',
                expires_at = now() + interval '7 days'
  returning id into v_existing;

  return jsonb_build_object('status', 'INVITED', 'invite_id', v_existing);
end;
$$;

-- ============================================================
-- ACCEPT INVITE (SECURITY DEFINER)
-- Called right after signup so a freshly-created user is
-- attached to the company that invited them.
-- ============================================================
create or replace function public.accept_workos_invite(p_email text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_invite public.workos_invites;
  v_profile public.workos_profiles;
begin
  select * into v_invite
  from public.workos_invites
  where lower(email) = lower(p_email)
    and status = 'PENDING'
    and expires_at > now()
  order by created_at desc
  limit 1;

  if not found then
    return jsonb_build_object('status', 'NO_INVITE');
  end if;

  if exists (select 1 from public.workos_profiles where user_id = auth.uid()) then
    return jsonb_build_object('status', 'ALREADY_HAS_COMPANY');
  end if;

  insert into public.workos_profiles (user_id, company_id, full_name, role, department)
  values (auth.uid(), v_invite.company_id, coalesce(nullif(v_invite.full_name, ''), 'New Member'), v_invite.role, v_invite.department)
  returning * into v_profile;

  update public.workos_invites
  set status = 'ACCEPTED'
  where id = v_invite.id;

  if v_invite.invited_by is not null then
    insert into public.workos_notifications (company_id, user_id, title, body, type, reference_id, reference_type)
    values (
      v_invite.company_id,
      (select user_id from public.workos_profiles where id = v_invite.invited_by),
      'Invite accepted',
      format('%s has joined.', coalesce(nullif(v_invite.full_name, ''), 'A new member')),
      'TEAM_JOIN',
      v_profile.id,
      'profile'
    );
  end if;

  return jsonb_build_object('status', 'ACCEPTED', 'profile_id', v_profile.id);
end;
$$;

-- ============================================================
-- TASK ASSIGNMENT NOTIFICATION (SECURITY DEFINER trigger)
-- ============================================================
create or replace function public.notify_task_assignment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_assignee_user_id uuid;
  v_assigner_name text;
begin
  if new.assigned_to is null then
    return new;
  end if;

  select user_id into v_assignee_user_id
  from public.workos_profiles where id = new.assigned_to;

  select full_name into v_assigner_name
  from public.workos_profiles where id = new.assigned_by;

  if v_assignee_user_id is not null then
    insert into public.workos_notifications (company_id, user_id, title, body, type, reference_id, reference_type)
    values (
      new.company_id,
      v_assignee_user_id,
      'New task assigned',
      format('"%s" was assigned to you%s', new.title,
        case when new.due_date is not null
          then format(' (due %s)', to_char(new.due_date, 'DD Mon'))
          else '' end),
      'TASK_ASSIGNED',
      new.id,
      'task'
    );
  end if;

  return new;
end;
$$;

create trigger workos_task_assignment_trigger
  after insert on public.workos_tasks
  for each row execute function public.notify_task_assignment();

-- ============================================================
-- ESCALATION CHECK — made idempotent (dedup notifications)
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

    if v_days_overdue = 1 then
      insert into public.workos_notifications (company_id, user_id, title, body, type, reference_id, reference_type)
      select p_company_id, v_task.assignee_user_id, '⚠️ Task Overdue',
             format('"%s" is overdue by %s day(s)', v_task.title, v_days_overdue),
             'TASK_OVERDUE', v_task.id, 'task'
      where not exists (
        select 1 from public.workos_notifications
        where reference_id = v_task.id and type = 'TASK_OVERDUE' and is_read = false
      );
    end if;

    if v_days_overdue >= 2 then
      select user_id into v_manager_user_id
      from public.workos_profiles where id = v_task.assigned_by;

      if v_manager_user_id is not null and v_manager_user_id != v_task.assignee_user_id then
        insert into public.workos_notifications (company_id, user_id, title, body, type, reference_id, reference_type)
        select p_company_id, v_manager_user_id, '🔴 Escalation: Task Overdue',
               format('%s has overdue task "%s" (%s days)', v_task.assignee_name, v_task.title, v_days_overdue),
               'TASK_ESCALATION', v_task.id, 'task'
        where not exists (
          select 1 from public.workos_notifications
          where reference_id = v_task.id and type = 'TASK_ESCALATION' and is_read = false
        );
      end if;
    end if;

    if v_days_overdue >= 3 then
      for v_admin_user_id in
        select user_id from public.workos_profiles
        where company_id = p_company_id and role in ('OWNER', 'ADMIN')
          and user_id != v_task.assignee_user_id
      loop
        insert into public.workos_notifications (company_id, user_id, title, body, type, reference_id, reference_type)
        select p_company_id, v_admin_user_id, '🚨 Critical: Task Overdue 3+ Days',
               format('%s has task "%s" overdue by %s days', v_task.assignee_name, v_task.title, v_days_overdue),
               'TASK_CRITICAL', v_task.id, 'task'
        where not exists (
          select 1 from public.workos_notifications
          where reference_id = v_task.id and type = 'TASK_CRITICAL' and is_read = false
        );
      end loop;
    end if;
  end loop;
end;
$$;

-- Run escalation checks on every task insert/update so alert levels
-- stay current without requiring a scheduler.
create or replace function public.trigger_escalation_check()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.check_escalations(new.company_id);
  return new;
end;
$$;

create trigger workos_escalation_trigger
  after insert or update on public.workos_tasks
  for each row execute function public.trigger_escalation_check();

-- ============================================================
-- GRANTS
-- ============================================================
grant execute on function public.invite_workos_member(text, text, public.workos_user_role, public.department) to authenticated;
grant execute on function public.accept_workos_invite(text) to authenticated;
grant execute on function public.check_escalations(uuid) to authenticated;