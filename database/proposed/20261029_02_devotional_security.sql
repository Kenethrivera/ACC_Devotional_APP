-- PROPOSED ONLY. The project owner must review and execute this manually.
-- Apply only after 20261029_01_devotional_foundation.sql.

begin;

create function public.devotional_manila_today()
returns date
language sql
stable
set search_path = ''
as $$
  select (now() at time zone 'Asia/Manila')::date;
$$;

create function public.is_devotional_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.user_roles
    where user_id = auth.uid()
      and role in ('admin', 'super_admin')
  );
$$;

revoke all on function public.devotional_manila_today() from public;
revoke all on function public.is_devotional_admin() from public;
grant execute on function public.devotional_manila_today() to authenticated;
grant execute on function public.is_devotional_admin() to authenticated;

alter table public.devotional_contents enable row level security;
alter table public.devotional_content_versions enable row level security;
alter table public.devotional_assignments enable row level security;
alter table public.member_devotional_completions enable row level security;
alter table public.member_devotional_reflections enable row level security;
alter table public.devotional_settings enable row level security;

create policy devotional_contents_read
on public.devotional_contents
for select
to authenticated
using (
  public.is_devotional_admin()
  or exists (
    select 1
    from public.devotional_content_versions as version
    join public.devotional_assignments as assignment
      on assignment.devotional_version_id = version.id
    where version.devotional_id = devotional_contents.id
      and version.published_at is not null
      and assignment.published_at is not null
      and assignment.superseded_at is null
      and assignment.scheduled_date <= public.devotional_manila_today()
  )
  or exists (
    select 1
    from public.devotional_content_versions as version
    join public.member_devotional_completions as completion
      on completion.devotional_version_id = version.id
    where version.devotional_id = devotional_contents.id
      and completion.member_id = auth.uid()
  )
);

create policy devotional_versions_read
on public.devotional_content_versions
for select
to authenticated
using (
  public.is_devotional_admin()
  or (
    published_at is not null
    and exists (
      select 1
      from public.devotional_assignments as assignment
      where assignment.devotional_version_id = devotional_content_versions.id
        and assignment.published_at is not null
        and assignment.superseded_at is null
        and assignment.scheduled_date <= public.devotional_manila_today()
    )
  )
  or exists (
    select 1
    from public.member_devotional_completions as completion
    where completion.devotional_version_id = devotional_content_versions.id
      and completion.member_id = auth.uid()
  )
);

create policy devotional_assignments_read
on public.devotional_assignments
for select
to authenticated
using (
  public.is_devotional_admin()
  or (
    published_at is not null
    and superseded_at is null
    and scheduled_date <= public.devotional_manila_today()
  )
  or exists (
    select 1
    from public.member_devotional_completions as completion
    where completion.assignment_id = devotional_assignments.id
      and completion.member_id = auth.uid()
  )
);

create policy devotional_contents_admin_insert
on public.devotional_contents
for insert
to authenticated
with check (public.is_devotional_admin());

create policy devotional_contents_admin_delete
on public.devotional_contents
for delete
to authenticated
using (public.is_devotional_admin());

create policy devotional_versions_admin_write
on public.devotional_content_versions
for all
to authenticated
using (public.is_devotional_admin())
with check (public.is_devotional_admin());

create policy devotional_completions_read
on public.member_devotional_completions
for select
to authenticated
using (
  member_id = auth.uid()
  or public.is_devotional_admin()
);

-- There is intentionally no Admin or Super Admin reflection policy.
create policy devotional_reflections_owner_read
on public.member_devotional_reflections
for select
to authenticated
using (member_id = auth.uid());

create policy devotional_reflections_owner_insert
on public.member_devotional_reflections
for insert
to authenticated
with check (
  member_id = auth.uid()
  and exists (
    select 1
    from public.member_devotional_completions as completion
    where completion.id = member_devotional_reflections.completion_id
      and completion.member_id = auth.uid()
  )
);

create policy devotional_reflections_owner_update
on public.member_devotional_reflections
for update
to authenticated
using (member_id = auth.uid())
with check (member_id = auth.uid());

create policy devotional_reflections_owner_delete
on public.member_devotional_reflections
for delete
to authenticated
using (member_id = auth.uid());

create policy devotional_settings_read
on public.devotional_settings
for select
to authenticated
using (true);

create policy devotional_settings_admin_insert
on public.devotional_settings
for insert
to authenticated
with check (public.is_devotional_admin());

create policy devotional_settings_admin_update
on public.devotional_settings
for update
to authenticated
using (public.is_devotional_admin())
with check (public.is_devotional_admin());

-- Supabase projects can have broad default privileges for new public tables.
-- Remove them before granting the exact operations supported by these policies.
revoke all on table
  public.devotional_contents,
  public.devotional_content_versions,
  public.devotional_assignments,
  public.member_devotional_completions,
  public.member_devotional_reflections,
  public.devotional_settings
from anon, authenticated;

grant select on public.devotional_contents to authenticated;
grant select on public.devotional_content_versions to authenticated;
grant select on public.devotional_assignments to authenticated;
grant select on public.member_devotional_completions to authenticated;
grant select, insert, update, delete
  on public.member_devotional_reflections to authenticated;
grant select on public.devotional_settings to authenticated;

grant insert, delete on public.devotional_contents to authenticated;
grant insert, update, delete
  on public.devotional_content_versions to authenticated;
grant insert, update on public.devotional_settings to authenticated;

create function public.complete_devotional_assignment(
  p_assignment_id uuid,
  p_reflection_text text default null
)
returns public.member_devotional_completions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member_id uuid := auth.uid();
  v_today date := public.devotional_manila_today();
  v_assignment public.devotional_assignments%rowtype;
  v_daily_limit integer;
  v_completion_count integer;
  v_completion public.member_devotional_completions%rowtype;
  v_reflection text := nullif(btrim(p_reflection_text), '');
begin
  if v_member_id is null then
    raise exception 'Authentication is required';
  end if;

  -- Serialize completion attempts for this member and Manila date so parallel
  -- requests cannot bypass the configured daily limit.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtext(v_member_id::text),
    (v_today - date '2000-01-01')::integer
  );

  select *
  into v_assignment
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

  -- Completion belongs to the official schedule date, not merely to one
  -- assignment revision. A replacement never creates a second obligation.
  if exists (
    select 1
    from public.member_devotional_completions
    where member_id = v_member_id
      and scheduled_date = v_assignment.scheduled_date
  ) then
    raise exception 'This official devotional date is already complete';
  end if;

  select daily_completion_limit
  into v_daily_limit
  from public.devotional_settings
  where singleton_key = true
  for share;

  if not found then
    raise exception 'The devotional daily completion limit is not configured';
  end if;

  select count(*)::integer
  into v_completion_count
  from public.member_devotional_completions
  where member_id = v_member_id
    and completed_on_manila_date = v_today;

  if v_completion_count >= v_daily_limit then
    raise exception 'The daily devotional completion limit has been reached';
  end if;

  insert into public.member_devotional_completions (
    member_id,
    assignment_id,
    scheduled_date,
    devotional_version_id,
    completed_at,
    completed_on_manila_date
  ) values (
    v_member_id,
    v_assignment.id,
    v_assignment.scheduled_date,
    v_assignment.devotional_version_id,
    now(),
    v_today
  )
  returning * into v_completion;

  if v_reflection is not null then
    insert into public.member_devotional_reflections (
      completion_id,
      member_id,
      reflection_text
    ) values (
      v_completion.id,
      v_member_id,
      v_reflection
    );
  end if;

  return v_completion;
exception
  when unique_violation then
    raise exception 'This official devotional date is already complete';
end;
$$;

revoke all on function public.complete_devotional_assignment(uuid, text)
  from public;
grant execute on function public.complete_devotional_assignment(uuid, text)
  to authenticated;

-- Official policy permits initial publication and replacement for past,
-- current, or future Monday-Friday dates. Superseded revisions and completions
-- remain immutable, while incomplete members receive the latest current row.
create function public.publish_devotional_assignment_revision(
  p_scheduled_date date,
  p_devotional_version_id uuid
)
returns public.devotional_assignments
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_revision_number integer;
  v_assignment public.devotional_assignments%rowtype;
begin
  if v_actor_id is null or not public.is_devotional_admin() then
    raise exception 'Administrative access is required';
  end if;

  if extract(isodow from p_scheduled_date) not between 1 and 5 then
    raise exception 'Official devotionals may only be scheduled Monday through Friday';
  end if;

  if not exists (
    select 1
    from public.devotional_content_versions
    where id = p_devotional_version_id
      and published_at is not null
  ) then
    raise exception 'The devotional content version must be published first';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtext('devotional-assignment'),
    (p_scheduled_date - date '2000-01-01')::integer
  );

  select coalesce(max(revision_number), 0) + 1
  into v_revision_number
  from public.devotional_assignments
  where scheduled_date = p_scheduled_date;

  update public.devotional_assignments
  set superseded_at = now(),
      superseded_by = v_actor_id
  where scheduled_date = p_scheduled_date
    and published_at is not null
    and superseded_at is null;

  insert into public.devotional_assignments (
    scheduled_date,
    devotional_version_id,
    revision_number,
    created_by,
    published_at,
    published_by
  ) values (
    p_scheduled_date,
    p_devotional_version_id,
    v_revision_number,
    v_actor_id,
    now(),
    v_actor_id
  )
  returning * into v_assignment;

  return v_assignment;
end;
$$;

revoke all on function public.publish_devotional_assignment_revision(date, uuid)
  from public;
grant execute
  on function public.publish_devotional_assignment_revision(date, uuid)
  to authenticated;

-- Official policy permits retirement for past, current, or future dates.
-- Retirement preserves the published revision and every linked completion.
create function public.retire_devotional_assignment(
  p_scheduled_date date
)
returns public.devotional_assignments
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_assignment public.devotional_assignments%rowtype;
begin
  if v_actor_id is null or not public.is_devotional_admin() then
    raise exception 'Administrative access is required';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtext('devotional-assignment'),
    (p_scheduled_date - date '2000-01-01')::integer
  );

  update public.devotional_assignments
  set superseded_at = now(),
      superseded_by = v_actor_id
  where scheduled_date = p_scheduled_date
    and published_at is not null
    and superseded_at is null
  returning * into v_assignment;

  if not found then
    raise exception 'No current published assignment exists for this date';
  end if;

  return v_assignment;
end;
$$;

revoke all on function public.retire_devotional_assignment(date) from public;
grant execute on function public.retire_devotional_assignment(date)
  to authenticated;

commit;
