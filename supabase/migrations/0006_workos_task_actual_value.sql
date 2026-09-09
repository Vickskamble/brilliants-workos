-- Brilliants Work OS — Migration 0006: Record task actual value for targets
-- Run order: after 0005
-- Members can complete their own tasks, but workos_targets RLS is
-- manager-only. This SECURITY DEFINER function lets the task's actual
-- value roll up into the assignee's active targets without broad target access.

create or replace function public.record_task_actual_value(
  p_task_id uuid,
  p_actual_value numeric default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_task public.workos_tasks;
  v_today date := current_date;
  v_target record;
begin
  select * into v_task from public.workos_tasks where id = p_task_id;
  if not found then return; end if;

  -- Only the assignee or a manager may record values
  if v_task.assigned_to is not null
     and v_task.assigned_to is distinct from public.my_workos_profile()
     and not public.is_workos_manager() then
    return;
  end if;

  if p_actual_value is null then
    p_actual_value := coalesce(v_task.actual_value, 0);
  end if;

  -- Roll up into every active target for this member covering today
  for v_target in
    select id, coalesce(current_value, 0) as current_value
    from public.workos_targets
    where profile_id = v_task.assigned_to
      and period_start <= v_today
      and period_end >= v_today
  loop
    update public.workos_targets
    set current_value = v_target.current_value + p_actual_value
    where id = v_target.id;
  end loop;
end;
$$;

grant execute on function public.record_task_actual_value(uuid, numeric) to authenticated;