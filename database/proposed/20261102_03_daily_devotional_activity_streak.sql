-- PROPOSED ONLY. The project owner must review and execute this manually.
-- Module 2D: calculate streaks from distinct actual Manila activity dates.
-- Apply once after the deployed Module 2C and Calendar migrations.
-- Do not rerun Module 2C or either earlier Calendar migration.
--
-- This migration adds one member-private daily activity table, backfills only
-- dates supported by retained activity timestamps, and replaces the existing
-- opening, reflection-save, and Calendar RPCs without changing their signatures.

begin;

create table public.member_devotional_daily_activity (
  member_id uuid not null references auth.users (id) on delete cascade,
  activity_date date not null,
  first_engaged_at timestamptz not null,
  primary key (member_id, activity_date),
  constraint member_devotional_daily_activity_manila_date_check
    check (
      (first_engaged_at at time zone 'Asia/Manila')::date = activity_date
    )
);

alter table public.member_devotional_daily_activity enable row level security;

create policy member_devotional_daily_activity_owner_select
on public.member_devotional_daily_activity
for select
to authenticated
using ((select auth.uid()) = member_id);

revoke all on table public.member_devotional_daily_activity
  from public, anon, authenticated;
grant select on table public.member_devotional_daily_activity
  to authenticated;

-- Every source below is an actual retained event timestamp. Scheduled dates are
-- deliberately not used. Intermediate revisit/edit days that were never stored
-- cannot be reconstructed and are not invented by this backfill.
with reliable_activity_events as (
  select member_id, first_opened_at as engaged_at
  from public.member_devotional_reading_states

  union all

  select member_id, last_opened_at
  from public.member_devotional_reading_states

  union all

  select member_id, reflected_at
  from public.member_devotional_reading_states
  where reflected_at is not null

  union all

  select member_id, created_at
  from public.member_devotional_reflection_documents

  union all

  select member_id, updated_at
  from public.member_devotional_reflection_documents

  union all

  select member_id, completed_at
  from public.member_devotional_completions

  union all

  select member_id, created_at
  from public.member_devotional_reflections

  union all

  select member_id, updated_at
  from public.member_devotional_reflections
),
dated_activity as (
  select
    member_id,
    (engaged_at at time zone 'Asia/Manila')::date as activity_date,
    engaged_at
  from reliable_activity_events
)
insert into public.member_devotional_daily_activity (
  member_id,
  activity_date,
  first_engaged_at
)
select
  member_id,
  activity_date,
  min(engaged_at)
from dated_activity
group by member_id, activity_date
on conflict (member_id, activity_date) do nothing;

-- CREATE OR REPLACE preserves each deployed function's identity and owner.
create or replace function public.record_devotional_opening(
  p_assignment_id uuid
)
returns public.member_devotional_reading_states
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member_id uuid := auth.uid();
  v_engaged_at timestamptz := now();
  v_today date := (v_engaged_at at time zone 'Asia/Manila')::date;
  v_assignment public.devotional_assignments%rowtype;
  v_reading public.member_devotional_reading_states%rowtype;
begin
  if v_member_id is null then
    raise exception 'Authentication is required';
  end if;

  select * into v_assignment
  from public.devotional_assignments
  where id = p_assignment_id
    and published_at is not null
    and superseded_at is null
  for share;

  if not found then
    raise exception 'The devotional assignment is unavailable';
  end if;
  if v_assignment.scheduled_date > v_today then
    raise exception 'Future devotional assignments are locked';
  end if;

  insert into public.member_devotional_reading_states (
    member_id,
    scheduled_date,
    assignment_id,
    devotional_version_id,
    first_opened_at,
    last_opened_at
  ) values (
    v_member_id,
    v_assignment.scheduled_date,
    v_assignment.id,
    v_assignment.devotional_version_id,
    v_engaged_at,
    v_engaged_at
  )
  on conflict (member_id, scheduled_date) do update
    set assignment_id = excluded.assignment_id,
        devotional_version_id = excluded.devotional_version_id,
        last_opened_at = v_engaged_at
  returning * into v_reading;

  insert into public.member_devotional_daily_activity (
    member_id,
    activity_date,
    first_engaged_at
  ) values (
    v_member_id,
    v_today,
    v_engaged_at
  )
  on conflict (member_id, activity_date) do nothing;

  return v_reading;
end;
$$;

create or replace function public.save_devotional_reflection_workspace(
  p_assignment_id uuid,
  p_blocks jsonb
)
returns public.member_devotional_reflection_documents
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member_id uuid := auth.uid();
  v_engaged_at timestamptz := now();
  v_today date := (v_engaged_at at time zone 'Asia/Manila')::date;
  v_assignment public.devotional_assignments%rowtype;
  v_reflection public.member_devotional_reflection_documents%rowtype;
  v_block jsonb;
  v_block_id uuid;
  v_saved_block_ids uuid[] := array[]::uuid[];
begin
  if v_member_id is null then
    raise exception 'Authentication is required';
  end if;
  if p_blocks is null or jsonb_typeof(p_blocks) <> 'array' then
    raise exception 'The reflection blocks are invalid';
  end if;
  if not exists (
    select 1
    from jsonb_array_elements(p_blocks) as block
    where btrim(coalesce(block ->> 'plain_text', '')) <> ''
  ) then
    raise exception 'Write a reflection before saving';
  end if;

  select * into v_assignment
  from public.devotional_assignments
  where id = p_assignment_id
    and published_at is not null
    and superseded_at is null
  for share;

  if not found then
    raise exception 'The devotional assignment is unavailable';
  end if;
  if v_assignment.scheduled_date > v_today then
    raise exception 'Future devotional assignments are locked';
  end if;

  insert into public.member_devotional_reading_states (
    member_id,
    scheduled_date,
    assignment_id,
    devotional_version_id,
    first_opened_at,
    last_opened_at,
    reflected_at
  ) values (
    v_member_id,
    v_assignment.scheduled_date,
    v_assignment.id,
    v_assignment.devotional_version_id,
    v_engaged_at,
    v_engaged_at,
    v_engaged_at
  )
  on conflict (member_id, scheduled_date) do update
    set assignment_id = excluded.assignment_id,
        devotional_version_id = excluded.devotional_version_id,
        last_opened_at = v_engaged_at,
        reflected_at = coalesce(
          public.member_devotional_reading_states.reflected_at,
          v_engaged_at
        );

  insert into public.member_devotional_reflection_documents (
    member_id,
    scheduled_date,
    assignment_id,
    devotional_version_id,
    created_at,
    updated_at
  ) values (
    v_member_id,
    v_assignment.scheduled_date,
    v_assignment.id,
    v_assignment.devotional_version_id,
    v_engaged_at,
    v_engaged_at
  )
  on conflict (member_id, scheduled_date) do update
    set assignment_id = excluded.assignment_id,
        devotional_version_id = excluded.devotional_version_id,
        updated_at = v_engaged_at
  returning * into v_reflection;

  -- Move existing rows outside the valid client order range first so that
  -- reordering saved nodes cannot collide with the unique order key.
  update public.member_devotional_reflection_blocks
  set display_order = display_order + 100000
  where member_id = v_member_id
    and scheduled_date = v_assignment.scheduled_date;

  for v_block in
    select value from jsonb_array_elements(p_blocks)
  loop
    if jsonb_typeof(v_block -> 'document_delta') <> 'array' then
      raise exception 'A reflection block document is invalid';
    end if;
    if v_block ->> 'block_type' = 'citation'
       and btrim(coalesce(v_block ->> 'selected_text', '')) = '' then
      raise exception 'A cited passage cannot be empty';
    end if;
    if (v_block ->> 'display_order')::integer < 0 then
      raise exception 'A reflection block order is invalid';
    end if;
    -- Flutter selection offsets are UTF-16 code-unit offsets. PostgreSQL text
    -- substring positions count Unicode characters, so comparing them here
    -- would reject valid citations around supplementary characters. The client
    -- validates the immutable loaded devotional body before sending this
    -- member-private citation; the FK and block constraint retain its version
    -- identity and required anchor fields.
    v_block_id := null;
    if nullif(v_block ->> 'id', '') is not null then
      v_block_id := (v_block ->> 'id')::uuid;
      update public.member_devotional_reflection_blocks
      set block_type = v_block ->> 'block_type',
          source_type = v_block ->> 'source_type',
          scripture_reference = v_block ->> 'scripture_reference',
          translation_id = v_block ->> 'translation_id',
          verse_identity = v_block ->> 'verse_identity',
          passage_key = v_block ->> 'passage_key',
          devotional_version_id =
            nullif(v_block ->> 'devotional_version_id', '')::uuid,
          devotional_title = v_block ->> 'devotional_title',
          selected_text = v_block ->> 'selected_text',
          start_offset = nullif(v_block ->> 'start_offset', '')::integer,
          end_offset = nullif(v_block ->> 'end_offset', '')::integer,
          highlight_color = v_block ->> 'highlight_color',
          document_delta = v_block -> 'document_delta',
          plain_text = btrim(coalesce(v_block ->> 'plain_text', '')),
          display_order = (v_block ->> 'display_order')::integer,
          updated_at = v_engaged_at
      where id = v_block_id
        and member_id = v_member_id
        and scheduled_date = v_assignment.scheduled_date;
      if not found then
        raise exception 'A reflection block does not belong to this member';
      end if;
    else
      insert into public.member_devotional_reflection_blocks (
        member_id, scheduled_date, block_type, source_type, scripture_reference,
        translation_id, verse_identity, passage_key, devotional_version_id,
        devotional_title, selected_text, start_offset, end_offset,
        highlight_color, document_delta, plain_text,
        display_order, created_at, updated_at
      ) values (
        v_member_id,
        v_assignment.scheduled_date,
        v_block ->> 'block_type',
        v_block ->> 'source_type',
        v_block ->> 'scripture_reference',
        v_block ->> 'translation_id',
        v_block ->> 'verse_identity',
        v_block ->> 'passage_key',
        nullif(v_block ->> 'devotional_version_id', '')::uuid,
        v_block ->> 'devotional_title',
        v_block ->> 'selected_text',
        nullif(v_block ->> 'start_offset', '')::integer,
        nullif(v_block ->> 'end_offset', '')::integer,
        v_block ->> 'highlight_color',
        v_block -> 'document_delta',
        btrim(coalesce(v_block ->> 'plain_text', '')),
        (v_block ->> 'display_order')::integer,
        v_engaged_at,
        v_engaged_at
      ) returning id into v_block_id;
    end if;
    v_saved_block_ids := array_append(v_saved_block_ids, v_block_id);
  end loop;

  delete from public.member_devotional_reflection_blocks
  where member_id = v_member_id
    and scheduled_date = v_assignment.scheduled_date
    and not (id = any(v_saved_block_ids));

  insert into public.member_devotional_daily_activity (
    member_id,
    activity_date,
    first_engaged_at
  ) values (
    v_member_id,
    v_today,
    v_engaged_at
  )
  on conflict (member_id, activity_date) do nothing;

  return v_reflection;
end;
$$;

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
        reading.reflected_at is not null as is_reflected
      from public.member_devotional_reading_states as reading
      where reading.member_id = v_member_id

      union all

      select
        completion.scheduled_date,
        true as is_read,
        legacy_reflection.completion_id is not null as is_reflected
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
        bool_or(event.is_reflected) as is_reflected
      from member_activity_events as event
      group by event.scheduled_date
    ),
    daily_activity as (
      select activity.activity_date
      from public.member_devotional_daily_activity as activity
      where activity.member_id = v_member_id
        and activity.activity_date <= v_today
    ),
    streak_anchor as (
      select case
        when exists (
          select 1 from daily_activity where activity_date = v_today
        ) then v_today
        when exists (
          select 1 from daily_activity where activity_date = v_today - 1
        ) then v_today - 1
        else null::date
      end as anchor_date
    ),
    ranked_streak as (
      select
        activity.activity_date,
        anchor.anchor_date,
        row_number() over (
          order by activity.activity_date desc
        ) as position
      from daily_activity as activity
      cross join streak_anchor as anchor
      where anchor.anchor_date is not null
        and activity.activity_date <= anchor.anchor_date
    ),
    streak_summary as (
      select count(*) filter (
        where activity_date = anchor_date - (position::integer - 1)
      )::integer as current_streak
      from ranked_streak
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

-- Preserve the established callable boundaries for all replaced RPCs.
revoke all on function public.record_devotional_opening(uuid)
  from public, anon, authenticated;
grant execute on function public.record_devotional_opening(uuid)
  to authenticated;

revoke all on function
  public.save_devotional_reflection_workspace(uuid, jsonb)
from public, anon, authenticated;
grant execute on function
  public.save_devotional_reflection_workspace(uuid, jsonb)
to authenticated;

revoke all on function public.get_my_devotional_calendar_month(date)
  from public, anon, authenticated;
grant execute on function public.get_my_devotional_calendar_month(date)
  to authenticated;

comment on table public.member_devotional_daily_activity is
  'One member-owned devotional engagement row per Asia/Manila calendar date.';
comment on function public.get_my_devotional_calendar_month(date) is
  'Returns a private member calendar month; current streak uses distinct consecutive Asia/Manila activity dates.';

commit;

-- Owner-operated rollback requires restoring the three prior reviewed function
-- bodies. Keep the activity table and its data unless the owner has first
-- exported it and explicitly accepts losing daily-streak history.
