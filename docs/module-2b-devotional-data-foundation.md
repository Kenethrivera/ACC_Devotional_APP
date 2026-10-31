# Module 2B devotional data foundation

Status: migrations applied and generated types refreshed by the project owner;
Supabase repository adapters implemented locally and awaiting owner testing.

## Schema verification boundary

`database.types.ts` now exports all six devotional tables, their generated
relationships, and the completion, publication, retirement, Manila-date, and
authorization RPCs. The owner-verified contract is recorded in
`docs/supabase-schema.md`; the local `supabase/schema.sql` remains empty.

The Flutter data adapters map only identifiers and types present in the
regenerated contract. They are wired at application bootstrap but are not yet
connected to dashboard presentation.

The proposal relies on these existing Supabase/PostgreSQL objects:

- `auth.users(id uuid)`
- Verified `public.user_roles.user_id uuid not null`
- Verified `public.user_roles.role text not null default 'member'`
- Verified `public.user_roles.created_at timestamptz not null default now()`

The devotional authorization helper now uses the native indexed comparison
`user_id = auth.uid()` and direct text role comparison. It only reads the
existing protected table and does not modify or replace Module 1 role functions.

The owner verified that authenticated users have no direct role-table mutation
privileges and that existing SECURITY DEFINER role-management functions enforce
Super Admin protections. The migration executor must still be a trusted owner
of the new tables/functions, and the owner must confirm `gen_random_uuid()` is
available before application.

## Proposed model

| Object | Purpose |
| --- | --- |
| `devotional_contents` | Stable identity for a devotional across revisions. |
| `devotional_content_versions` | Draft and immutable published text versions. |
| `devotional_assignments` | Dated, revisioned church-wide assignments. Only one current published revision may exist per date; unpublished drafts do not participate in that partial unique index. |
| `member_devotional_completions` | Manual completion facts pinned to the exact assignment and content version. |
| `member_devotional_reflections` | Optional member-owned private text, physically separated from reporting data. |
| `devotional_settings` | Singleton church policy containing the per-member daily completion limit. |

Official assignments may be scheduled on any calendar date, including Saturday
and Sunday. The assignment table retains superseded revisions so an edit never
rewrites the version referenced by an existing completion. A unique
member-and-schedule-date constraint prevents a replacement assignment revision
from producing a second completion for the same official devotional day.

Published content versions cannot be unpublished or rewritten. Withdrawing a
published devotional retires its current assignment through
`retire_devotional_assignment`; the assignment revision, content version, and
existing completions remain stored and linked.

The approved assignment lifecycle permits initial publication, replacement,
and retirement for any past, current, or future Manila calendar date.
Replacement preserves the old assignment revision, exact content version, and
all linked completions. Members without a completion use the latest current
published revision. A member with any completion for the official schedule date
cannot complete a replacement revision for that date.

## Scheduling and completion rules

- The server derives the current church date with `Asia/Manila`; the client is
  not trusted to provide it.
- Members can select only current, published assignments whose schedule date is
  today or earlier. This prevents direct reads of future content.
- `complete_devotional_assignment` is the only granted completion write path.
  It checks authentication, publication, current assignment revision, future
  locking, duplicate completion, and the configured daily limit.
- The daily limit is one church-wide policy applied per member. Its count resets
  at midnight in `Asia/Manila` and includes both today's work and catch-up work.
- An advisory transaction lock serializes a member's completion requests for a
  Manila date, preventing parallel requests from bypassing the limit.
- Authenticated application roles receive no completion update/delete grants or
  RLS policies. This implements the approved no-undo rule while still allowing
  the `auth.users` foreign-key cascade to remove a deleted member's private
  data. UI confirmation remains a future reader responsibility.
- A missed published assignment remains eligible for catch-up, subject to the
  daily limit.
- A completion belongs to the official `scheduled_date`, not merely to an
  assignment revision. Both an explicit RPC check and the unique
  `(member_id, scheduled_date)` constraint prevent repeat completion after a
  replacement.

## Future progress and streak rule

The future progress-calculation module must build obligations from current
published official assignment dates, not from weekdays. Any calendar date with
no current published official assignment is neutral and must not automatically
break or reduce a member's streak. Existing completions on a subsequently
retired date remain valid and must never be erased or converted to an incomplete
result. The exact positive-credit treatment of such retained completions belongs
to the future progress specification; the minimum invariant is no automatic
penalty for an unavailable assignment.

The phrase "church-wide daily completion limit" is implemented as one church
configuration value applied independently to each member. It is not a single
shared quota across the congregation. The owner must approve that interpretation
before application.

The owner configured the applied per-member daily completion limit to `3`.

## Privacy and authorization

RLS is enabled on every proposed table.

- Members read available published content, their own completion records, and
  only their own reflections.
- Admin and Super Admin roles may read completion metadata for progress
  reporting and manage devotional publishing/settings.
- There is deliberately no Admin or Super Admin reflection policy. The
  administrative Dart repository also has no reflection model or method.
- Reflection inserts must reference a completion owned by the signed-in member.
- Authentication and role checks are server-enforced. UI role checks are not
  part of the security boundary.
- RLS policy helpers are placed in `public` with execution revoked from
  `PUBLIC` and granted only to `authenticated`. This avoids granting broad
  `USAGE` on the existing `private` schema.
- Broad inherited/default table privileges are explicitly revoked from `anon`
  and `authenticated` before the minimum required privileges are granted back.

The Supabase service role and PostgreSQL superusers can bypass RLS as an
infrastructure capability. Application code must never expose those credentials
or use them for ordinary admin screens.

All SECURITY DEFINER functions use an empty `search_path` and schema-qualified
relations and functions. They must be created and remain owned by a trusted
database-owner role that cannot be assumed by `anon` or `authenticated`.

Deleting an Auth user cascades deletion of that member's completions and private
reflections. Ordinary authenticated users cannot update or delete completion
rows. The owner should approve this account-deletion retention policy before
application.

Content/settings audit actor columns intentionally store soft UUID references
rather than foreign keys to `auth.users`. This prevents Auth-account deletion
from rewriting immutable published records or being blocked by audit triggers.
The UUID remains as a pseudonymous audit identifier after account deletion; the
owner should approve that retention policy.

## Static safety corrections

The pre-application source review made the following corrections:

- Moved RLS policy helpers from `private` to tightly permissioned `public`
  functions, avoiding a broad `USAGE` grant on the existing private schema.
- Revoked inherited/default table privileges before granting exact operations.
- Removed direct assignment-table writes; assignment replacement and retirement
  now use admin-checked SECURITY DEFINER functions.
- Added server-controlled content, version, settings, and reflection audit
  fields and made reflection ownership immutable.
- Decoupled immutable publisher audit IDs from Auth-user deletion while keeping
  hard ownership foreign keys for completions and reflections.
- Preserved Auth-user deletion cascades while enforcing no-undo completion
  behavior through grants and RLS rather than a conflicting delete trigger.
- Added timestamp/order constraints and a completion date check tied to
  `Asia/Manila`.
- Added the member/content-version index used by completion-history RLS paths.
- Changed proposed function creation to fail on name/signature collisions rather
  than replacing an unforeseen existing function.
- Excluded unpublished assignment drafts from the one-current-published partial
  index and from the publishing RPC's supersession update.
- Revoked default PUBLIC execution from private trigger functions.

## RLS dependency graph

The read-policy dependencies form a directed acyclic graph, not a recursion:

- `devotional_contents` reads through `devotional_content_versions`,
  `devotional_assignments`, and `member_devotional_completions`.
- `devotional_content_versions` reads through `devotional_assignments` and
  `member_devotional_completions`.
- `devotional_assignments` reads through `member_devotional_completions`.
- `member_devotional_completions` depends only on `auth.uid()` and the
  SECURITY DEFINER admin helper.
- Reflection insertion checks `member_devotional_completions`; completion
  policies never query reflections.
- Settings policies have no devotional-table dependency.

No edge returns to an upstream table, so there is no direct or indirect RLS
policy cycle. Authenticated users receive SELECT on every table referenced by a
policy subquery. `public.is_devotional_admin()` reads `public.user_roles` under
its trusted SECURITY DEFINER owner and has no dependency on a devotional policy.

## Applied migration record

The project owner reported both proposed migrations applied successfully, the
settings singleton configured, RLS and policy counts checked, and
`database.types.ts` regenerated before repository integration.

The complete owner-operated sequence and post-application queries are in
`docs/module-2b-migration-runbook.md`.

Both scripts are transactional, but they are intentionally separate so the
owner can review storage/constraints independently from RLS, grants, and trusted
functions.

## Rollback notes

Rollback is intentionally not automated because dropping these objects would
destroy devotional history and private reflections. If rollback is required
before production data exists, the owner should first confirm the tables are
empty, then remove the public functions, policies and grants, trigger functions,
tables in reverse foreign-key order, and finally the remaining private helper
functions. Once any real completion or reflection exists, prefer a forward
corrective migration and preserve the records.

## Flutter boundary

The domain layer contains plain Dart models matching the proposed nullability
and types. SQL `uuid` maps to `String`, `int4` maps to `int`, `date` maps to a
date-only `DateTime` interpreted in the Manila church calendar, and
`timestamptz` maps to an instant-bearing `DateTime`.

`DevotionalRepository` contains member operations and is implemented by
`SupabaseDevotionalRepository`. The separate
`DevotionalAdministrationRepository` is implemented by
`SupabaseDevotionalAdministrationRepository` for publishing, settings, and
completion reporting. It intentionally cannot read reflections. Both adapters
are created by `AppBootstrap`; no dashboard UI is connected yet.

## Owner verification checklist

After reviewing and applying the proposals in a non-production environment:

1. Confirm generated types exactly match every proposed identifier, type,
   nullable column, relationship, RPC argument, and RPC return value.
2. Set a deliberate positive daily completion limit.
3. As a member, confirm a future assignment and its content cannot be selected
   or completed, while a missed published assignment on any day can be
   completed.
4. Confirm a completion requires an explicit RPC call, cannot be updated or
   deleted, and a duplicate official schedule date is rejected.
5. Confirm concurrent completion attempts cannot exceed the configured limit
   and that the count changes at Manila midnight rather than device midnight.
6. Confirm an Admin can see completion metadata but cannot select any row from
   `member_devotional_reflections`, including another member's text.
7. Confirm a member can create, edit, clear, and read only their own optional
   reflection without changing the completion fact.
8. Publish a replacement assignment revision and confirm the previous revision,
   content version, and existing completion remain unchanged. Confirm an
   already-complete member cannot complete the new revision, while an incomplete
   member receives the latest current revision.
9. Retire an assignment after its date and confirm existing completions remain
   readable while incomplete members no longer receive a current assignment.
10. After type regeneration, implement and manually verify the repository adapter
   before connecting any devotional UI.

No SQL, Supabase, Flutter, Dart, test, analyzer, formatter, build, deployment,
or Git command was run while preparing this foundation.
