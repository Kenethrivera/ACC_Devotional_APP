-- PROPOSED ONLY. The project owner must review and execute this manually.
-- Module 2B: devotional content, versioning, assignments, completions, and
-- private reflection storage. This file enables RLS without adding policies,
-- leaving the new tables deny-by-default until the security migration follows.

begin;

create table public.devotional_contents (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by uuid
);

create table public.devotional_content_versions (
  id uuid primary key default gen_random_uuid(),
  devotional_id uuid not null
    references public.devotional_contents (id) on delete restrict,
  version_number integer not null check (version_number > 0),
  title text not null check (btrim(title) <> ''),
  scripture_reference text not null check (btrim(scripture_reference) <> ''),
  body text not null check (btrim(body) <> ''),
  created_at timestamptz not null default now(),
  created_by uuid,
  published_at timestamptz,
  published_by uuid,
  constraint devotional_content_versions_number_key
    unique (devotional_id, version_number),
  constraint devotional_content_versions_publication_check
    check ((published_at is null) = (published_by is null)),
  constraint devotional_content_versions_publication_order_check
    check (published_at is null or published_at >= created_at)
);

create table public.devotional_assignments (
  id uuid primary key default gen_random_uuid(),
  scheduled_date date not null,
  devotional_version_id uuid not null
    references public.devotional_content_versions (id) on delete restrict,
  revision_number integer not null check (revision_number > 0),
  created_at timestamptz not null default now(),
  created_by uuid,
  published_at timestamptz,
  published_by uuid,
  superseded_at timestamptz,
  superseded_by uuid,
  constraint devotional_assignments_weekday_check
    check (extract(isodow from scheduled_date) between 1 and 5),
  constraint devotional_assignments_revision_key
    unique (scheduled_date, revision_number),
  constraint devotional_assignments_completion_reference_key
    unique (id, scheduled_date, devotional_version_id),
  constraint devotional_assignments_publication_check
    check ((published_at is null) = (published_by is null)),
  constraint devotional_assignments_supersession_check
    check ((superseded_at is null) = (superseded_by is null)),
  constraint devotional_assignments_publication_order_check
    check (published_at is null or published_at >= created_at),
  constraint devotional_assignments_supersession_order_check
    check (
      superseded_at is null
      or (published_at is not null and superseded_at >= published_at)
    )
);

-- Historical and unpublished draft rows may coexist, while only one current
-- published church-wide assignment may exist for a Manila schedule date.
create unique index devotional_assignments_one_current_per_date_idx
  on public.devotional_assignments (scheduled_date)
  where published_at is not null
    and superseded_at is null;

create index devotional_assignments_available_date_idx
  on public.devotional_assignments (scheduled_date, published_at)
  where published_at is not null
    and superseded_at is null;

create index devotional_assignments_version_idx
  on public.devotional_assignments (devotional_version_id);

create table public.member_devotional_completions (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references auth.users (id) on delete cascade,
  assignment_id uuid not null,
  scheduled_date date not null,
  devotional_version_id uuid not null,
  completed_at timestamptz not null,
  completed_on_manila_date date not null,
  constraint member_devotional_completions_assignment_fk
    foreign key (assignment_id, scheduled_date, devotional_version_id)
    references public.devotional_assignments
      (id, scheduled_date, devotional_version_id)
    on delete restrict,
  constraint member_devotional_completions_member_assignment_key
    unique (member_id, assignment_id),
  constraint member_devotional_completions_member_schedule_key
    unique (member_id, scheduled_date),
  constraint member_devotional_completions_owner_reference_key
    unique (id, member_id),
  constraint member_devotional_completions_schedule_order_check
    check (completed_on_manila_date >= scheduled_date),
  constraint member_devotional_completions_manila_date_check
    check (
      (completed_at at time zone 'Asia/Manila')::date
        = completed_on_manila_date
    )
);

create index member_devotional_completions_member_completed_idx
  on public.member_devotional_completions
    (member_id, completed_on_manila_date desc);

create index member_devotional_completions_schedule_idx
  on public.member_devotional_completions (scheduled_date, member_id);

create index member_devotional_completions_assignment_idx
  on public.member_devotional_completions (assignment_id);

create index member_devotional_completions_member_version_idx
  on public.member_devotional_completions (member_id, devotional_version_id);

-- Reflections are deliberately separated from progress metadata. This keeps
-- administrative completion reporting independent from private journal text.
create table public.member_devotional_reflections (
  completion_id uuid primary key,
  member_id uuid not null,
  reflection_text text not null check (btrim(reflection_text) <> ''),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint member_devotional_reflections_update_order_check
    check (updated_at >= created_at),
  constraint member_devotional_reflections_owner_fk
    foreign key (completion_id, member_id)
    references public.member_devotional_completions (id, member_id)
    on delete cascade
);

create index member_devotional_reflections_member_idx
  on public.member_devotional_reflections (member_id);

-- A singleton row represents the church-wide policy. No value is seeded here:
-- the church must deliberately choose the per-member daily completion limit.
create table public.devotional_settings (
  singleton_key boolean primary key default true
    check (singleton_key),
  daily_completion_limit integer not null
    check (daily_completion_limit > 0),
  updated_at timestamptz not null default now(),
  updated_by uuid
);

create function private.set_devotional_content_audit()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.created_at := now();
  new.created_by := auth.uid();
  return new;
end;
$$;

create trigger set_devotional_content_audit
before insert on public.devotional_contents
for each row execute function private.set_devotional_content_audit();

create function private.guard_devotional_content_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'Devotional identity audit fields are immutable';
end;
$$;

create trigger guard_devotional_content_update
before update on public.devotional_contents
for each row execute function private.guard_devotional_content_update();

create function private.set_devotional_version_audit()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.created_at := now();
    new.created_by := auth.uid();
    new.published_at := null;
    new.published_by := null;
    return new;
  end if;

  if new.devotional_id is distinct from old.devotional_id
    or new.version_number is distinct from old.version_number
    or new.created_at is distinct from old.created_at
    or new.created_by is distinct from old.created_by then
    raise exception 'Devotional version identity and audit fields are immutable';
  end if;

  if old.published_at is null and new.published_at is not null then
    new.published_at := now();
    new.published_by := auth.uid();
  end if;

  return new;
end;
$$;

create trigger set_devotional_version_audit
before insert or update on public.devotional_content_versions
for each row execute function private.set_devotional_version_audit();

create function private.set_devotional_settings_audit()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.singleton_key := true;
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end;
$$;

create trigger set_devotional_settings_audit
before insert or update on public.devotional_settings
for each row execute function private.set_devotional_settings_audit();

create function private.guard_devotional_version_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'DELETE' then
    if old.published_at is not null then
      raise exception 'Published devotional versions are immutable';
    end if;
    return old;
  end if;

  if old.published_at is not null then
    raise exception 'Published devotional versions are immutable';
  end if;

  return new;
end;
$$;

create trigger guard_devotional_version_mutation
before update or delete on public.devotional_content_versions
for each row execute function private.guard_devotional_version_mutation();

create function private.validate_devotional_assignment()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.published_at is not null and not exists (
    select 1
    from public.devotional_content_versions as version
    where version.id = new.devotional_version_id
      and version.published_at is not null
  ) then
    raise exception 'An assignment may only publish a published content version';
  end if;

  return new;
end;
$$;

create trigger validate_devotional_assignment
before insert or update on public.devotional_assignments
for each row execute function private.validate_devotional_assignment();

create function private.guard_devotional_assignment_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'DELETE' then
    if old.published_at is not null then
      raise exception 'Published assignment revisions are retained for audit';
    end if;
    return old;
  end if;

  if old.published_at is not null then
    if new.scheduled_date is distinct from old.scheduled_date
      or new.devotional_version_id is distinct from old.devotional_version_id
      or new.revision_number is distinct from old.revision_number
      or new.created_at is distinct from old.created_at
      or new.created_by is distinct from old.created_by
      or new.published_at is distinct from old.published_at
      or new.published_by is distinct from old.published_by then
      raise exception 'Published assignment revision content is immutable';
    end if;

    if old.superseded_at is not null and (
      new.superseded_at is distinct from old.superseded_at
      or new.superseded_by is distinct from old.superseded_by
    ) then
      raise exception 'Assignment supersession is immutable';
    end if;
  end if;

  return new;
end;
$$;

create trigger guard_devotional_assignment_mutation
before update or delete on public.devotional_assignments
for each row execute function private.guard_devotional_assignment_mutation();

create function private.set_reflection_audit()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.created_at := now();
    new.updated_at := now();
    return new;
  end if;

  if new.completion_id is distinct from old.completion_id
    or new.member_id is distinct from old.member_id
    or new.created_at is distinct from old.created_at then
    raise exception 'Reflection ownership and creation metadata are immutable';
  end if;

  new.updated_at := now();
  return new;
end;
$$;

create trigger set_reflection_audit
before insert or update on public.member_devotional_reflections
for each row execute function private.set_reflection_audit();

-- Trigger functions are invoked by their triggers and are not application
-- RPCs. Remove the default PUBLIC execute grant as defense in depth.
revoke all on function private.set_devotional_content_audit() from public;
revoke all on function private.guard_devotional_content_update() from public;
revoke all on function private.set_devotional_version_audit() from public;
revoke all on function private.set_devotional_settings_audit() from public;
revoke all on function private.guard_devotional_version_mutation() from public;
revoke all on function private.validate_devotional_assignment() from public;
revoke all on function private.guard_devotional_assignment_mutation()
  from public;
revoke all on function private.set_reflection_audit() from public;

alter table public.devotional_contents enable row level security;
alter table public.devotional_content_versions enable row level security;
alter table public.devotional_assignments enable row level security;
alter table public.member_devotional_completions enable row level security;
alter table public.member_devotional_reflections enable row level security;
alter table public.devotional_settings enable row level security;

commit;
