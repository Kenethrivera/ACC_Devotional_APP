# Supabase schema contract

This document records only schema details that have been verified against the
live Supabase project. Proposed, generated-only, or inferred details are marked
separately and must not be treated as live objects.

## Verification record

The existing authorization prerequisite below was manually verified by the
project owner on 2026-10-29. No database connection or SQL execution was
performed while writing this document.

## Verified existing objects

### `public.user_roles`

| Column | PostgreSQL type | Nullable | Default |
| --- | --- | --- | --- |
| `user_id` | `uuid` | No | None reported |
| `role` | `text` | No | `'member'` |
| `created_at` | `timestamptz` | No | `now()` |

Verified authorization behavior:

- Row Level Security is enabled on `public.user_roles`.
- Authenticated users have no direct `INSERT`, `UPDATE`, or `DELETE`
  privileges on the table.
- Existing role-management SECURITY DEFINER functions verify that the caller is
  a `super_admin`.
- Those functions prevent callers from modifying their own role.
- Those functions protect other `super_admin` accounts from modification.
- Public role-management RPCs delegate to protected functions in the `private`
  schema.

The generated snapshot currently exposes the public RPCs
`list_manageable_users` and `set_admin_access`. Their generated signatures
remain documented in `database.types.ts`.

The owner did not provide the table's PK, UNIQUE, CHECK, foreign-key, SELECT
policy, exact policy definitions, exact private function names, or function
ownership. Do not infer those details from this verification record.

## Verified applied Module 2B objects

The project owner confirmed that both Module 2B migrations were applied on
2026-10-29. A later type-generation attempt failed with a privileges error,
leaving the local `database.types.ts` empty. The following names are recorded
from the applied Module 2B migration source and prior owner verification;
they cannot currently be cross-checked against a local generated snapshot:

- `public.devotional_contents`
- `public.devotional_content_versions`
- `public.devotional_assignments`
- `public.member_devotional_completions`
- `public.member_devotional_reflections`
- `public.devotional_settings`
- `public.devotional_manila_today()`
- `public.is_devotional_admin()`
- `public.complete_devotional_assignment(uuid, text)`
- `public.publish_devotional_assignment_revision(date, uuid)`
- `public.retire_devotional_assignment(date)`

The owner also confirmed:

- RLS is enabled on all six devotional tables.
- Policy counts match the reviewed migrations.
- The per-member Manila-calendar daily completion limit is configured to `3`.

Exact applied row nullability, insert/update shapes, foreign-key relationships,
RPC arguments, and RPC return records must be rechecked after the owner restores
the generated `database.types.ts` using the intended Supabase project.

The applied Module 2B source includes the named constraint
`devotional_assignments_weekday_check` and a matching Monday-through-Friday
guard inside `public.publish_devotional_assignment_revision(date, uuid)`. These
remain part of the live contract until the owner applies the policy migration
below.

## Proposed any-day scheduling policy (not applied or verified)

The consolidated file
`database/proposed/20261101_01_module_2c_consolidated.sql` includes the
any-day policy from the earlier, superseded 20261031 proposal. It proposes:

- dropping only `devotional_assignments_weekday_check`;
- replacing `public.publish_devotional_assignment_revision(date, uuid)` with
  the same signature and security boundary, without its weekday rejection; and
- retaining the current function owner, `SECURITY DEFINER`, empty secure
  `search_path`, authenticated-only execution, assignment revision history,
  one-current-assignment-per-date index, completion constraints, and all RLS
  policies.

This scheduling portion does not alter generated Module 2B table or RPC types, so no
`database.types.ts` edit is proposed. After manual application, the owner must
verify the live constraint/function metadata and record the new verification
date here.

## Proposed Module 2C objects (not applied or verified)

The final owner-operated proposal is
`database/proposed/20261101_01_module_2c_consolidated.sql`. It supersedes the
separate 20261030 Module 2C and 20261031 any-day proposals and proposes:

- `public.member_devotional_reading_states`
- `public.member_devotional_reflection_documents`
- `public.member_devotional_reflection_blocks`
- `public.member_devotional_highlights`
- `public.member_bible_highlights`
- `public.member_devotional_reader_preferences`
- `public.record_devotional_opening(uuid)`
- `public.save_devotional_reflection_workspace(uuid, jsonb)`

The proposed reflection workspace stores an ordered sequence of owner-private
paragraph and citation blocks. Every block has its own Quill document and
stable identifier, allowing regular writing and cited reflections to be
interleaved and reordered. Citation blocks retain their source type, immutable
source identity, exact selected text and offsets, and optional normalized
`#RRGGBB` highlight color.
Devotional and Bible highlight colors use the same normalized representation.

These objects are **not** part of the verified schema contract until the owner
applies the migration, regenerates `database.types.ts`, and records verification
here. The current generated types do not contain them. Flutter code that uses
them must treat missing table/function responses as a migration-required state.
