-- Brilliants Work OS — Migration 0007: Company Leaderboard
-- Run order: after 0006

create or replace function public.get_company_leaderboard(p_limit int default 10)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_company uuid;
  rec record;
  items jsonb := '[]'::jsonb;
  v_score jsonb;
begin
  v_company := public.my_workos_company();
  if v_company is null then
    return '[]'::jsonb;
  end if;

  for rec in
    select p.id, p.full_name, p.role, p.department
    from public.workos_profiles p
    where p.company_id = v_company and p.is_active = true
    order by p.full_name
  loop
    v_score := public.get_performance_score(
      rec.id,
      date_trunc('month', current_date)::date,
      least(date_trunc('month', current_date) + interval '1 month - 1 day', current_date)::date
    );

    if v_score ? 'overall' then
      items := items || jsonb_build_object(
        'profile_id', rec.id::text,
        'full_name', rec.full_name,
        'role', rec.role::text,
        'department', rec.department::text,
        'score', (v_score ->> 'overall')::numeric,
        'band', v_score ->> 'band',
        'task_completion', (v_score ->> 'task_completion')::numeric,
        'target_achievement', (v_score ->> 'target_achievement')::numeric,
        'on_time_rate', (v_score ->> 'on_time_rate')::numeric,
        'completed', coalesce((v_score ->> 'completed')::int, 0),
        'assigned', coalesce((v_score ->> 'assigned')::int, 0)
      );
    end if;
  end loop;

  return (
    select coalesce(jsonb_agg(x order by (x ->> 'score')::numeric desc), '[]'::jsonb)
    from (
      select item as x
      from jsonb_array_elements(items) item
      order by (item ->> 'score')::numeric desc
      limit p_limit
    ) sub
  );
end;
$$;

grant execute on function public.get_company_leaderboard(int) to authenticated;