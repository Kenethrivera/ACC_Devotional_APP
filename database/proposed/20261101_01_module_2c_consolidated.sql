-- PROPOSED ONLY. Owner-operated consolidated Module 2C + any-day scheduling.
-- Apply once, after the existing applied Module 2B migrations.
-- Supersedes the two separate 20261030_01 and 20261031_01 proposals.
-- Neither prerequisite migration should be rerun.

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

create table public.member_devotional_reading_states (
  member_id uuid not null references auth.users (id) on delete cascade,
  scheduled_date date not null,
  assignment_id uuid not null,
  devotional_version_id uuid not null,
  first_opened_at timestamptz not null default now(),
  last_opened_at timestamptz not null default now(),
  reflected_at timestamptz,
  primary key (member_id, scheduled_date),
  constraint member_devotional_reading_states_assignment_fk
    foreign key (assignment_id, scheduled_date, devotional_version_id)
    references public.devotional_assignments
      (id, scheduled_date, devotional_version_id)
    on delete restrict,
  constraint member_devotional_reading_states_time_check
    check (
      last_opened_at >= first_opened_at
      and (reflected_at is null or reflected_at >= first_opened_at)
    )
);

create index member_devotional_reading_states_schedule_idx
  on public.member_devotional_reading_states (scheduled_date, member_id);

create index member_devotional_reading_states_member_activity_idx
  on public.member_devotional_reading_states
    (member_id, last_opened_at desc);

create table public.member_devotional_reflection_documents (
  member_id uuid not null references auth.users (id) on delete cascade,
  scheduled_date date not null,
  assignment_id uuid not null,
  devotional_version_id uuid not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (member_id, scheduled_date),
  constraint member_devotional_reflection_documents_reading_fk
    foreign key (member_id, scheduled_date)
    references public.member_devotional_reading_states
      (member_id, scheduled_date)
    on delete cascade,
  constraint member_devotional_reflection_documents_assignment_fk
    foreign key (assignment_id, scheduled_date, devotional_version_id)
    references public.devotional_assignments
      (id, scheduled_date, devotional_version_id)
    on delete restrict,
  constraint member_devotional_reflection_documents_time_check
    check (updated_at >= created_at)
);

create table public.member_devotional_reflection_blocks (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references auth.users (id) on delete cascade,
  scheduled_date date not null,
  block_type text not null check (block_type in ('paragraph', 'citation')),
  document_delta jsonb not null default '[{"insert":"\n"}]'::jsonb
    check (jsonb_typeof(document_delta) = 'array'),
  plain_text text not null default '',
  source_type text check (source_type in ('bible', 'devotion')),
  scripture_reference text,
  translation_id text,
  verse_identity text,
  passage_key text,
  devotional_version_id uuid
    references public.devotional_content_versions (id) on delete restrict,
  devotional_title text,
  selected_text text,
  start_offset integer check (start_offset >= 0),
  end_offset integer,
  highlight_color text
    check (highlight_color is null or highlight_color ~ '^#[0-9A-F]{6}$'),
  display_order integer not null check (display_order >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint member_devotional_reflection_blocks_workspace_fk
    foreign key (member_id, scheduled_date)
    references public.member_devotional_reflection_documents
      (member_id, scheduled_date)
    on delete cascade,
  constraint member_devotional_reflection_blocks_type_check
    check (
      (
        block_type = 'paragraph'
        and source_type is null
        and scripture_reference is null
        and translation_id is null
        and verse_identity is null
        and passage_key is null
        and devotional_version_id is null
        and devotional_title is null
        and selected_text is null
        and start_offset is null
        and end_offset is null
        and highlight_color is null
      )
      or
      (
        block_type = 'citation'
        and source_type is not null
        and source_type = 'bible'
        and scripture_reference is not null
        and btrim(scripture_reference) <> ''
        and translation_id is not null
        and btrim(translation_id) <> ''
        and passage_key is not null
        and btrim(passage_key) <> ''
        and selected_text is not null
        and btrim(selected_text) <> ''
        and start_offset is not null
        and end_offset is not null
        and end_offset > start_offset
        and devotional_version_id is null
        and devotional_title is null
      )
      or
      (
        block_type = 'citation'
        and source_type is not null
        and source_type = 'devotion'
        and devotional_version_id is not null
        and devotional_title is not null
        and btrim(devotional_title) <> ''
        and selected_text is not null
        and btrim(selected_text) <> ''
        and start_offset is not null
        and end_offset is not null
        and end_offset > start_offset
        and scripture_reference is null
        and translation_id is null
        and verse_identity is null
        and passage_key is null
      )
    ),
  constraint member_devotional_reflection_blocks_order_key
    unique (member_id, scheduled_date, display_order),
  constraint member_devotional_reflection_blocks_time_check
    check (updated_at >= created_at)
);

create unique index member_cited_bible_reflections_anchor_key
  on public.member_devotional_reflection_blocks
    (member_id, scheduled_date, translation_id, passage_key,
     start_offset, end_offset)
  where block_type = 'citation' and source_type = 'bible';

create unique index member_cited_devotion_reflections_anchor_key
  on public.member_devotional_reflection_blocks
    (member_id, scheduled_date, devotional_version_id,
     start_offset, end_offset)
  where block_type = 'citation' and source_type = 'devotion';

create table public.member_devotional_highlights (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references auth.users (id) on delete cascade,
  devotional_version_id uuid not null
    references public.devotional_content_versions (id) on delete restrict,
  start_offset integer not null check (start_offset >= 0),
  end_offset integer not null check (end_offset > start_offset),
  highlight_color text not null
    check (highlight_color ~ '^#[0-9A-F]{6}$'),
  selected_text text not null check (selected_text <> ''),
  prefix_context text,
  suffix_context text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint member_devotional_highlights_anchor_key
    unique (member_id, devotional_version_id, start_offset, end_offset)
);

create index member_devotional_highlights_lookup_idx
  on public.member_devotional_highlights
    (member_id, devotional_version_id, start_offset);

create table public.member_bible_highlights (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references auth.users (id) on delete cascade,
  translation_id text not null check (btrim(translation_id) <> ''),
  passage_key text not null check (btrim(passage_key) <> ''),
  verse_identity text,
  start_offset integer not null check (start_offset >= 0),
  end_offset integer not null check (end_offset > start_offset),
  highlight_color text not null
    check (highlight_color ~ '^#[0-9A-F]{6}$'),
  selected_text text not null check (selected_text <> ''),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint member_bible_highlights_anchor_key
    unique (
      member_id,
      translation_id,
      passage_key,
      start_offset,
      end_offset
    )
);

create index member_bible_highlights_lookup_idx
  on public.member_bible_highlights
    (member_id, translation_id, passage_key, start_offset);

create function private.text_array_has_unique_values(p_values text[])
returns boolean
language sql
immutable
strict
set search_path = ''
as $$
  select cardinality(p_values) = (
    select count(distinct item)::integer
    from unnest(p_values) as item
  );
$$;

create table public.member_devotional_reader_preferences (
  member_id uuid primary key references auth.users (id) on delete cascade,
  reader_layout text not null default 'side_by_side'
    check (reader_layout in ('side_by_side', 'stacked')),
  bible_translation_ids text[] not null default array['ASV']::text[]
    check (
      cardinality(bible_translation_ids) > 0
      and private.text_array_has_unique_values(bible_translation_ids)
    ),
  updated_at timestamptz not null default now()
);

-- Prevent clients from spoofing ownership or audit timestamps on directly
-- writable private tables.
create function private.set_member_devotional_private_audit()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.member_id := auth.uid();
  if tg_op = 'INSERT' then
    new.created_at := now();
  end if;
  new.updated_at := now();
  return new;
end;
$$;

create trigger set_member_devotional_highlight_audit
before insert or update on public.member_devotional_highlights
for each row execute function private.set_member_devotional_private_audit();

create trigger set_member_bible_highlight_audit
before insert or update on public.member_bible_highlights
for each row execute function private.set_member_devotional_private_audit();

create trigger set_member_reflection_block_audit
before insert or update on public.member_devotional_reflection_blocks
for each row execute function private.set_member_devotional_private_audit();

create function private.set_member_reader_preference_audit()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.member_id := auth.uid();
  new.updated_at := now();
  return new;
end;
$$;

create trigger set_member_reader_preference_audit
before insert or update on public.member_devotional_reader_preferences
for each row execute function private.set_member_reader_preference_audit();

alter table public.member_devotional_reading_states enable row level security;
alter table public.member_devotional_reflection_documents enable row level security;
alter table public.member_devotional_reflection_blocks enable row level security;
alter table public.member_devotional_highlights enable row level security;
alter table public.member_bible_highlights enable row level security;
alter table public.member_devotional_reader_preferences enable row level security;

-- Participation metadata may be reported to devotional administrators.
-- It contains no reflection or highlighting content.
create policy devotional_reading_states_owner_or_admin_read
on public.member_devotional_reading_states
for select
to authenticated
using (member_id = auth.uid() or public.is_devotional_admin());

-- There is deliberately no Admin or Super Admin policy on reflection content.
create policy devotional_reflection_documents_owner_read
on public.member_devotional_reflection_documents
for select
to authenticated
using (member_id = auth.uid());

create policy devotional_reflection_documents_owner_delete
on public.member_devotional_reflection_documents
for delete
to authenticated
using (member_id = auth.uid());

create policy devotional_reflection_blocks_owner_read
on public.member_devotional_reflection_blocks
for select
to authenticated
using (member_id = auth.uid());

create policy devotional_highlights_owner_all
on public.member_devotional_highlights
for all
to authenticated
using (member_id = auth.uid())
with check (member_id = auth.uid());

create policy bible_highlights_owner_all
on public.member_bible_highlights
for all
to authenticated
using (member_id = auth.uid())
with check (member_id = auth.uid());

create policy devotional_reader_preferences_owner_all
on public.member_devotional_reader_preferences
for all
to authenticated
using (member_id = auth.uid())
with check (member_id = auth.uid());

-- Allow a member to continue reading the exact immutable content revision
-- recorded by Module 2C even if the official assignment is later replaced.
create policy devotional_assignments_read_from_reading_state
on public.devotional_assignments
for select
to authenticated
using (
  exists (
    select 1
    from public.member_devotional_reading_states as reading
    where reading.assignment_id = devotional_assignments.id
      and reading.member_id = auth.uid()
  )
);

create policy devotional_versions_read_from_reading_state
on public.devotional_content_versions
for select
to authenticated
using (
  exists (
    select 1
    from public.member_devotional_reading_states as reading
    where reading.devotional_version_id = devotional_content_versions.id
      and reading.member_id = auth.uid()
  )
);

create policy devotional_contents_read_from_reading_state
on public.devotional_contents
for select
to authenticated
using (
  exists (
    select 1
    from public.devotional_content_versions as version
    join public.member_devotional_reading_states as reading
      on reading.devotional_version_id = version.id
    where version.devotional_id = devotional_contents.id
      and reading.member_id = auth.uid()
  )
);

revoke all on table
  public.member_devotional_reading_states,
  public.member_devotional_reflection_documents,
  public.member_devotional_reflection_blocks,
  public.member_devotional_highlights,
  public.member_bible_highlights,
  public.member_devotional_reader_preferences
from anon, authenticated;

grant select on public.member_devotional_reading_states to authenticated;
grant select, delete
  on public.member_devotional_reflection_documents to authenticated;
grant select on public.member_devotional_reflection_blocks to authenticated;
grant select, insert, update, delete
  on public.member_devotional_highlights,
     public.member_bible_highlights,
     public.member_devotional_reader_preferences
  to authenticated;

create function public.record_devotional_opening(p_assignment_id uuid)
returns public.member_devotional_reading_states
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member_id uuid := auth.uid();
  v_today date := public.devotional_manila_today();
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
    now(),
    now()
  )
  on conflict (member_id, scheduled_date) do update
    set assignment_id = excluded.assignment_id,
        devotional_version_id = excluded.devotional_version_id,
        last_opened_at = now()
  returning * into v_reading;

  return v_reading;
end;
$$;

create function public.save_devotional_reflection_workspace(
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
  v_today date := public.devotional_manila_today();
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
    now(),
    now(),
    now()
  )
  on conflict (member_id, scheduled_date) do update
    set assignment_id = excluded.assignment_id,
        devotional_version_id = excluded.devotional_version_id,
        last_opened_at = now(),
        reflected_at = coalesce(
          public.member_devotional_reading_states.reflected_at,
          now()
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
    now(),
    now()
  )
  on conflict (member_id, scheduled_date) do update
    set assignment_id = excluded.assignment_id,
        devotional_version_id = excluded.devotional_version_id,
        updated_at = now()
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
          updated_at = now()
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
        display_order
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
        (v_block ->> 'display_order')::integer
      ) returning id into v_block_id;
    end if;
    v_saved_block_ids := array_append(
      v_saved_block_ids,
      v_block_id
    );
  end loop;

  delete from public.member_devotional_reflection_blocks
  where member_id = v_member_id
    and scheduled_date = v_assignment.scheduled_date
    and not (id = any(v_saved_block_ids));

  return v_reflection;
end;
$$;

revoke all on function public.record_devotional_opening(uuid) from public;
revoke all on function
  public.save_devotional_reflection_workspace(uuid, jsonb)
from public;
grant execute on function public.record_devotional_opening(uuid)
  to authenticated;
grant execute on function
  public.save_devotional_reflection_workspace(uuid, jsonb)
to authenticated;

commit;

-- Rollback requires owner review and export of any new member-private data.
-- Do not restore the weekday check if any weekend assignment has been published.
-- Keep legacy completions and reflections intact.

