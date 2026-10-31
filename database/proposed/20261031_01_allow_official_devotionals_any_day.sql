-- SUPERSEDED PROPOSAL. Do not apply; use 20261101_01_module_2c_consolidated.sql.
-- Apply after both applied 20261029 Module 2B migrations.
--
-- This additive policy migration permits an official devotional assignment on
-- every calendar date. It does not alter assignment history, completion data,
-- RLS policies, table privileges, or member-private reflection access.

begin;

ALTER TABLE public.devotional_assignments
  DROP CONSTRAINT IF EXISTS devotional_assignments_weekday_check;

-- CREATE OR REPLACE retains the existing function identity, owner, and grants.
-- The signature, SECURITY DEFINER setting, and empty secure search_path remain
-- identical to the applied function; only the weekday rejection is removed.
create or replace function public.publish_devotional_assignment_revision(
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

-- Reassert the applied execution boundary without broadening access.
revoke all
  on function public.publish_devotional_assignment_revision(date, uuid)
  from public;
grant execute
  on function public.publish_devotional_assignment_revision(date, uuid)
  to authenticated;

commit;

-- Owner-operated rollback note:
-- Do not restore the weekday constraint or weekday RPC guard while any weekend
-- assignment revision exists. First assess dependent completions and retained
-- history; deleting either would violate the approved audit/privacy contract.
