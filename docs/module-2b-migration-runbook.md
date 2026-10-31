# Module 2B owner-operated migration runbook

Status: prepared for owner review and manual execution. Nothing in this runbook
has been executed by Codex.

## 1. Approval gates

Do not apply the migrations until all of the following are true:

- A current backup or recovery point exists and the first application is in a
  non-production environment.
- The executing database role is trusted, can create objects in `public` and
  `private`, owns or can read `public.user_roles`, and will remain the trusted
  owner of the Module 2B SECURITY DEFINER functions.
- The owner has selected a positive integer for the per-member daily completion
  limit.
- The approved assignment policy permits initial publication, replacement, and
  retirement for any past, current, or future Manila calendar date. Existing
  completions remain attached to their original immutable revisions, and each
  member may complete an official schedule date only once.
- The owner approves the interpretation that one church-wide setting is applied
  independently to each member, rather than being a shared congregation quota.
- The owner approves cascading deletion of a deleted Auth user's completions
  and reflections.
- The owner approves retaining soft audit UUIDs for content authors/publishers
  after an Auth account is deleted.
- No existing object uses a proposed Module 2B name.

The authorization prerequisite recorded in `docs/supabase-schema.md` is
compatible with the proposal. No Module 1 role-management function needs to be
changed.

## 2. Read-only preflight queries

Run these as the role that would apply the migrations. Stop if the result does
not match the expectation in the comments.

```sql
-- Record the prospective owner. It must be a trusted database-owner role,
-- never anon or authenticated.
select current_user, session_user;

-- Expected: true. The SECURITY DEFINER authorization helper must be able to
-- read the protected role table as its owner.
select has_table_privilege(
  current_user,
  'public.user_roles',
  'SELECT'
) as migration_owner_can_read_roles;

-- Confirm the future function owner can actually bypass user_roles RLS.
-- Expected: owner_bypasses_rls is true. This is true for a BYPASSRLS role, or
-- for the table owner when FORCE ROW LEVEL SECURITY is false.
select
  current_user as migration_role,
  r.rolbypassrls,
  pg_catalog.pg_get_userbyid(c.relowner) as user_roles_owner,
  c.relforcerowsecurity,
  (
    r.rolbypassrls
    or (
      c.relowner = r.oid
      and not c.relforcerowsecurity
    )
  ) as owner_bypasses_rls
from pg_catalog.pg_roles as r
join pg_catalog.pg_class as c on c.oid = 'public.user_roles'::regclass
where r.rolname = current_user;

-- Expected: uuid/text/timestamptz, all NO, with the verified defaults.
select
  column_name,
  data_type,
  udt_name,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'user_roles'
order by ordinal_position;

-- Expected: true.
select c.relrowsecurity as user_roles_rls_enabled
from pg_catalog.pg_class as c
join pg_catalog.pg_namespace as n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname = 'user_roles';

-- Expected: all false.
select
  has_table_privilege('authenticated', 'public.user_roles', 'INSERT')
    as authenticated_can_insert,
  has_table_privilege('authenticated', 'public.user_roles', 'UPDATE')
    as authenticated_can_update,
  has_table_privilege('authenticated', 'public.user_roles', 'DELETE')
    as authenticated_can_delete;

-- Expected: non-null function identity.
select pg_catalog.to_regprocedure('gen_random_uuid()')
  as uuid_generator;

-- Expected: every value is null. A non-null value is a name collision and
-- must be reviewed rather than overwritten.
select
  pg_catalog.to_regclass('public.devotional_contents') as devotional_contents,
  pg_catalog.to_regclass('public.devotional_content_versions')
    as devotional_content_versions,
  pg_catalog.to_regclass('public.devotional_assignments')
    as devotional_assignments,
  pg_catalog.to_regclass('public.member_devotional_completions')
    as member_devotional_completions,
  pg_catalog.to_regclass('public.member_devotional_reflections')
    as member_devotional_reflections,
  pg_catalog.to_regclass('public.devotional_settings')
    as devotional_settings;

-- Expected: every value is null.
select
  pg_catalog.to_regprocedure('public.devotional_manila_today()')
    as manila_helper,
  pg_catalog.to_regprocedure('public.is_devotional_admin()')
    as authorization_helper,
  pg_catalog.to_regprocedure(
    'public.complete_devotional_assignment(uuid,text)'
  ) as completion_rpc,
  pg_catalog.to_regprocedure(
    'public.publish_devotional_assignment_revision(date,uuid)'
  ) as publishing_rpc,
  pg_catalog.to_regprocedure(
    'public.retire_devotional_assignment(date)'
  ) as retirement_rpc;

-- Expected: zero rows. The migrations use CREATE FUNCTION rather than
-- CREATE OR REPLACE FUNCTION, so any unexpected collision also fails and rolls
-- back safely.
select n.nspname, p.oid::regprocedure as existing_function
from pg_catalog.pg_proc as p
join pg_catalog.pg_namespace as n on n.oid = p.pronamespace
where n.nspname = 'private'
  and p.proname in (
    'set_devotional_content_audit',
    'guard_devotional_content_update',
    'set_devotional_version_audit',
    'set_devotional_settings_audit',
    'guard_devotional_version_mutation',
    'validate_devotional_assignment',
    'guard_devotional_assignment_mutation',
    'set_reflection_audit'
  );
```

Also confirm `auth.users.id` is `uuid`. It is referenced by
`member_devotional_completions.member_id` with `ON DELETE CASCADE`.

## 3. Migration order

1. Apply the complete contents of
   `database/proposed/20261029_01_devotional_foundation.sql` as one script.
   It creates storage, relationships, constraints, indexes, triggers, and
   enables RLS without policies. Its transaction leaves the tables
   deny-by-default.
2. If step 1 succeeds, immediately apply the complete contents of
   `database/proposed/20261029_02_devotional_security.sql` as one script. It
   creates policies, exact grants, and trusted workflow functions.
3. If either script reports an error, stop. Do not execute fragments from the
   failed script. Capture the complete error and review a forward correction.
4. Bootstrap the chosen positive daily limit. Replace `<chosen_limit>` before
   running this statement:

```sql
insert into public.devotional_settings (
  singleton_key,
  daily_completion_limit
) values (
  true,
  <chosen_limit>
)
on conflict (singleton_key) do update
set daily_completion_limit = excluded.daily_completion_limit;
```

When executed from the SQL editor, `auth.uid()` is normally null, so this
bootstrap row can have `updated_by = null`. Later updates made through an
authenticated Admin session are stamped with that Admin's UUID.

5. Do not connect the Flutter UI or implement the Supabase repository adapter
   yet. Complete the checks below, then regenerate `database.types.ts` from the
   applied schema and review the generated contract first.

## 4. Structural post-application queries

### Columns and nullability

```sql
select
  table_name,
  ordinal_position,
  column_name,
  data_type,
  udt_name,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'public'
  and table_name in (
    'devotional_contents',
    'devotional_content_versions',
    'devotional_assignments',
    'member_devotional_completions',
    'member_devotional_reflections',
    'devotional_settings'
  )
order by table_name, ordinal_position;
```

### Constraints and relationships

```sql
select
  conrelid::regclass as table_name,
  conname as constraint_name,
  contype as constraint_type,
  pg_catalog.pg_get_constraintdef(oid, true) as definition
from pg_catalog.pg_constraint
where connamespace = 'public'::regnamespace
  and conrelid in (
    'public.devotional_contents'::regclass,
    'public.devotional_content_versions'::regclass,
    'public.devotional_assignments'::regclass,
    'public.member_devotional_completions'::regclass,
    'public.member_devotional_reflections'::regclass,
    'public.devotional_settings'::regclass
  )
order by conrelid::regclass::text, conname;
```

### Indexes

```sql
select tablename, indexname, indexdef
from pg_catalog.pg_indexes
where schemaname = 'public'
  and tablename in (
    'devotional_contents',
    'devotional_content_versions',
    'devotional_assignments',
    'member_devotional_completions',
    'member_devotional_reflections',
    'devotional_settings'
  )
order by tablename, indexname;
```

### RLS and policies

```sql
-- Expected: rls_enabled is true for all six tables.
select
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as force_rls
from pg_catalog.pg_class as c
join pg_catalog.pg_namespace as n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in (
    'devotional_contents',
    'devotional_content_versions',
    'devotional_assignments',
    'member_devotional_completions',
    'member_devotional_reflections',
    'devotional_settings'
  )
order by c.relname;

select
  tablename,
  policyname,
  roles,
  cmd,
  qual,
  with_check
from pg_catalog.pg_policies
where schemaname = 'public'
  and tablename in (
    'devotional_contents',
    'devotional_content_versions',
    'devotional_assignments',
    'member_devotional_completions',
    'member_devotional_reflections',
    'devotional_settings'
  )
order by tablename, policyname;
```

Confirm that `member_devotional_reflections` has only the four owner policies
and no Admin/Super Admin policy.

### Effective table privileges

```sql
select
  role_name,
  table_name,
  has_table_privilege(role_name, 'public.' || table_name, 'SELECT')
    as can_select,
  has_table_privilege(role_name, 'public.' || table_name, 'INSERT')
    as can_insert,
  has_table_privilege(role_name, 'public.' || table_name, 'UPDATE')
    as can_update,
  has_table_privilege(role_name, 'public.' || table_name, 'DELETE')
    as can_delete
from unnest(array['anon', 'authenticated']) as roles(role_name)
cross join unnest(array[
  'devotional_contents',
  'devotional_content_versions',
  'devotional_assignments',
  'member_devotional_completions',
  'member_devotional_reflections',
  'devotional_settings'
]) as tables(table_name)
order by role_name, table_name;
```

Expected highlights:

- `anon`: no privileges on any Module 2B table.
- `authenticated`: no direct assignment writes and no completion writes.
- `authenticated`: reflection CRUD privileges exist, with RLS restricting them
  to the owner.

### Function ownership and execution

```sql
select
  p.oid::regprocedure as function_signature,
  pg_catalog.pg_get_userbyid(p.proowner) as owner,
  p.prosecdef as security_definer,
  p.proconfig as function_settings,
  has_function_privilege('anon', p.oid, 'EXECUTE') as anon_can_execute,
  has_function_privilege('authenticated', p.oid, 'EXECUTE')
    as authenticated_can_execute
from pg_catalog.pg_proc as p
join pg_catalog.pg_namespace as n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'devotional_manila_today',
    'is_devotional_admin',
    'complete_devotional_assignment',
    'publish_devotional_assignment_revision',
    'retire_devotional_assignment'
  )
order by p.oid::regprocedure::text;
```

Expected:

- `anon_can_execute` is false for every function.
- `authenticated_can_execute` is true.
- `is_devotional_admin` and the three workflow functions are SECURITY DEFINER.
- Every function shows an empty fixed `search_path` in `function_settings`.
- Every SECURITY DEFINER function is owned by the trusted migration role.

### Settings and Manila date

```sql
select singleton_key, daily_completion_limit, updated_at, updated_by
from public.devotional_settings;

select
  public.devotional_manila_today() as helper_date,
  (now() at time zone 'Asia/Manila')::date as expected_date;
```

Expected: exactly one settings row with the approved positive limit, and the two
date values are equal.

## 5. Authenticated-session verification

Run these only in a non-production environment using known test accounts.
Replace the UUID placeholders with existing test users. These transactions make
no persistent changes.

```sql
-- Member account: expected false.
begin;
select pg_catalog.set_config(
  'request.jwt.claim.sub',
  '<member_user_uuid>',
  true
);
set local role authenticated;
select auth.uid(), public.is_devotional_admin();
rollback;

-- Admin account: expected true.
begin;
select pg_catalog.set_config(
  'request.jwt.claim.sub',
  '<admin_user_uuid>',
  true
);
set local role authenticated;
select auth.uid(), public.is_devotional_admin();
rollback;
```

After creating test devotional/completion data through the intended workflows:

```sql
-- Run as a test member session. Expected unauthorized_rows = 0.
select count(*) filter (where member_id <> auth.uid()) as unauthorized_rows
from public.member_devotional_completions;

select count(*) filter (where member_id <> auth.uid()) as unauthorized_rows
from public.member_devotional_reflections;
```

Using a known reflection belonging to a different test member, query its
`completion_id` as an Admin/Super Admin authenticated session. The query must
return zero rows:

```sql
select *
from public.member_devotional_reflections
where completion_id = '<another_members_completion_uuid>'::uuid;
```

Separately verify through authenticated client/RPC calls that:

1. A future assignment cannot be selected or completed by a member.
2. A missed published assignment on any day can be completed.
3. Parallel completion calls cannot exceed the configured daily limit.
4. Direct completion update/delete and assignment writes are denied.
5. Initial publication succeeds for representative past, current, and future
   dates, including Saturday and Sunday.
6. A replacement after the schedule date preserves the old revision, its exact
   content version, and existing completions.
7. A member who completed the old revision cannot complete the replacement;
   an incomplete member receives the latest current revision.
8. Retirement after the schedule date hides the current assignment without
   deleting historical rows or invalidating existing completions.
9. An Admin can read completion metadata but never another member's reflection.

Progress/streak calculation is not implemented in Module 2B. When it is added,
verify that every calendar date with no current published assignment is neutral
and does not automatically break or reduce a streak. Build obligations from
published assignment dates rather than from weekday numbers.

## Any-day scheduling policy migration

After the applied Module 2B migrations, review and manually apply
`database/proposed/20261031_01_allow_official_devotionals_any_day.sql` as the
same trusted role that owns `publish_devotional_assignment_revision`. Confirm
that the role remains the function owner after `CREATE OR REPLACE`, then verify
the function is still `SECURITY DEFINER`, has an empty `search_path`, is not
executable by `PUBLIC`, and is executable by `authenticated`. Do not apply a
rollback that restores the weekday constraint while weekend assignment history
or dependent completions exist.

## 6. Type regeneration and application integration

After all checks pass:

1. Regenerate `database.types.ts` using the owner's approved Supabase workflow.
2. Compare generated nullable fields, relationships, and RPC signatures with
   the Module 2B Dart models and repository interfaces.
3. Update `docs/supabase-schema.md` so the applied Module 2B objects move from
   "proposed" to "verified".
4. Implement the Supabase repository adapter separately.
5. Only then connect devotional presentation code to the repository.

Do not use service-role credentials in the Flutter application or ordinary
Admin interfaces.
