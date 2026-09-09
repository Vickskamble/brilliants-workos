-- Brilliants Work OS — Seed Data for Development
-- Creates demo company + users

-- Create auth users (via existing trigger flow in dev)
-- NOTE: Users are created via Supabase Auth, then we add profiles

-- Demo Company
insert into public.workos_companies (name, slug, industry)
values ('Brilliants Demo', 'brilliants-demo', 'Software')
on conflict (slug) do nothing;

-- Owner (create manually after running this once with auth.uid() replaced)
-- This is a template. In production, first user creates their company
-- via the UI and gets OWNER role automatically.

-- Demo data: Tasks
insert into public.workos_tasks (
  company_id, title, description, priority, status, due_date, target_value
)
select
  c.id,
  'PowerEMS – Contact 20 leads',
  'Reach out to 20 new PowerEMS leads via phone/email',
  'HIGH',
  'TODO',
  current_date,
  20
from public.workos_companies c
where c.slug = 'brilliants-demo'
on conflict do nothing;

-- Demo data: Targets
insert into public.workos_targets (
  company_id, target_type, period_type, period_start, period_end, target_value, current_value
)
select
  c.id,
  'REVENUE',
  'MONTHLY',
  date_trunc('month', current_date)::date,
  (date_trunc('month', current_date) + interval '1 month - 1 day')::date,
  200000,
  165000
from public.workos_companies c
where c.slug = 'brilliants-demo'
on conflict do nothing;
