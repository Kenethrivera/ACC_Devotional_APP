-- SUPERSEDED PROPOSAL. Do not apply this scheduled-date streak migration.
-- Use 20261102_03_daily_devotional_activity_streak.sql instead.
-- Module 2D: keep retrospective reading separate from the current streak.
-- Apply after 20261102_01_devotional_calendar_backend.sql.
--
-- This replaces only the Calendar RPC. It does not recreate tables, modify
-- participation rows, or change RLS. The response shape is unchanged.

begin;

create or replace function public.get_my_devotional_calendar_month(
  p_month date
)
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_member_id uuid := auth.uid();
  v_today date := public.devotional_manila_today();
  v_month_start date;
  v_month_end date;
begin
  if v_member_id is null then
    raise exception 'Authentication is required';
  end if;
  if p_month is null then
    raise exception 'A calendar month is required';
  end if;

  v_month_start := date_trunc('month', p_month)::date;
  v_month_end := (v_month_start + interval '1 month - 1 day')::date;

  return (
    with member_activity_events as (
      select
        reading.scheduled_date,
        true as is_read,
        reading.reflected_at is not null as is_reflected,
        coalesce(
          (reading.first_opened_at at time zone 'Asia/Manila')::date
            = reading.scheduled_date,
          false
        ) as is_on_time_read
      from public.member_devotional_reading_states as reading
      where reading.member_id = v_member_id

      union all

      select
        completion.scheduled_date,
        true as is_read,
        legacy_reflection.completion_id is not null as is_reflected,
        coalesce(
          (completion.completed_at at time zone 'Asia/Manila')::date
            = completion.scheduled_date,
          false
        ) as is_on_time_read
      from public.member_devotional_completions as completion
      left join public.member_devotional_reflections as legacy_reflection
        on legacy_reflection.completion_id = completion.id
       and legacy_reflection.member_id = v_member_id
      where completion.member_id = v_member_id
    ),
    member_activity as (
      select
        event.scheduled_date,
        bool_or(event.is_read) as is_read,
        bool_or(event.is_reflected) as is_reflected,
        bool_or(event.is_on_time_read) as is_on_time_read
      from member_activity_events as event
      group by event.scheduled_date
    ),
    current_assignments as (
      select assignment.*
      from public.devotional_assignments as assignment
      where assignment.published_at is not null
        and assignment.superseded_at is null
        and assignment.scheduled_date <= v_today
    ),
    month_days as (
      select
        assignment.scheduled_date,
        to_jsonb(assignment) as assignment,
        to_jsonb(version) as content,
        coalesce(activity.is_read, false) as is_read,
        coalesce(activity.is_reflected, false) as is_reflected
      from current_assignments as assignment
      join public.devotional_content_versions as version
        on version.id = assignment.devotional_version_id
      left join member_activity as activity
        on activity.scheduled_date = assignment.scheduled_date
      where assignment.scheduled_date between v_month_start and v_month_end
    ),
    ranked_streak as (
      select
        row_number() over (
          order by assignment.scheduled_date desc
        ) as position,
        coalesce(activity.is_on_time_read, false) as is_on_time_read
      from current_assignments as assignment
      left join member_activity as activity
        on activity.scheduled_date = assignment.scheduled_date
      where assignment.scheduled_date < v_today
         or coalesce(activity.is_on_time_read, false)
    ),
    streak_summary as (
      select case
        when count(*) = 0 then 0
        when bool_and(is_on_time_read) then count(*)::integer
        else (
          min(position) filter (where not is_on_time_read) - 1
        )::integer
      end as current_streak
      from ranked_streak
    ),
    all_time_summary as (
      select
        count(*) filter (where activity.is_read)::integer as all_time_read,
        count(*) filter (
          where activity.is_reflected
        )::integer as all_time_reflected
      from member_activity as activity
    ),
    month_summary as (
      select
        count(*) filter (where day.is_read)::integer as month_read,
        count(*)::integer as month_published_through_today
      from month_days as day
    ),
    calendar_days as (
      select coalesce(
        jsonb_agg(
          jsonb_build_object(
            'assignment', day.assignment,
            'content', day.content,
            'is_read', day.is_read,
            'is_reflected', day.is_reflected
          ) order by day.scheduled_date
        ),
        '[]'::jsonb
      ) as days
      from month_days as day
    )
    select jsonb_build_object(
      'manila_today', v_today,
      'month_start', v_month_start,
      'month_end', v_month_end,
      'summary', jsonb_build_object(
        'all_time_read', all_time.all_time_read,
        'all_time_reflected', all_time.all_time_reflected,
        'month_read', month.month_read,
        'month_published_through_today',
          month.month_published_through_today,
        'current_streak', streak.current_streak
      ),
      'days', calendar.days
    )
    from all_time_summary as all_time
    cross join month_summary as month
    cross join streak_summary as streak
    cross join calendar_days as calendar
  );
end;
$$;

-- CREATE OR REPLACE preserves the function identity and existing owner.
-- Reassert the intended callable boundary without broadening table access.
revoke all
  on function public.get_my_devotional_calendar_month(date)
  from public, anon, authenticated;
grant execute
  on function public.get_my_devotional_calendar_month(date)
  to authenticated;

comment on function public.get_my_devotional_calendar_month(date) is
  'Returns a private member calendar month; current streak includes only devotionals first opened on their scheduled Asia/Manila date.';

commit;

-- Owner-operated rollback: reapply the prior reviewed function definition
-- from 20261102_01_devotional_calendar_backend.sql. No data rollback is needed.
