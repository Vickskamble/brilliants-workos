-- Brilliants Work OS — Migration 0008: Realtime Publication
-- Adds WorkOS tables to the supabase_realtime publication so the app
-- receives live POSTGRES_CHANGES (instant refresh without manual pull).

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'workos_tasks'
  ) then
    alter publication supabase_realtime add table public.workos_tasks;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'workos_targets'
  ) then
    alter publication supabase_realtime add table public.workos_targets;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'workos_daily_standups'
  ) then
    alter publication supabase_realtime add table public.workos_daily_standups;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'workos_teams'
  ) then
    alter publication supabase_realtime add table public.workos_teams;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'workos_team_members'
  ) then
    alter publication supabase_realtime add table public.workos_team_members;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'workos_notifications'
  ) then
    alter publication supabase_realtime add table public.workos_notifications;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'workos_profiles'
  ) then
    alter publication supabase_realtime add table public.workos_profiles;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'workos_companies'
  ) then
    alter publication supabase_realtime add table public.workos_companies;
  end if;
end $$;