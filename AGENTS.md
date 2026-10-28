# Power of 4+: The Fresh Page — Codex Instructions

## Project and precedence
This repository is a Flutter/Dart application for Android, iOS, and responsive web, backed by Supabase Auth, PostgreSQL, and Storage. It serves Adelina Christian Church. Follow existing repository structure and established Module 1 design patterns before introducing new ones.

**Mandatory:** Never assume a database column exists or guess its PostgreSQL type. Read `docs/supabase-schema.md` and existing Dart models/repositories before database-related edits. If the schema document is incomplete or conflicts with code, report the discrepancy and stop the schema-dependent portion; do not silently invent or change the schema.

## Non-negotiable execution restrictions
- Do **not** run tests, test runners, emulators, Flutter apps, or build commands.
- Do **not** run `flutter analyze`, `dart analyze`, `dart format`, `flutter pub get`, or other validation, formatting, generation, or package-install commands.
- Do **not** run **any Git command**, including read-only Git commands such as `git status`, `git diff`, or `git log`.
- Do **not** access Supabase to run queries, migrations, RPC calls, Edge Functions, or modify database, Auth, Storage, or RLS settings. Never apply migrations.
- Do **not** deploy, push, publish, or alter remote infrastructure.
- Do **not** install or upgrade dependencies without explicit user approval.
- Do **not** print, expose, commit, or embed secrets/service-role credentials.
- The project owner alone runs tests, Flutter commands, SQL, Supabase changes, Git, and deployment.
- These restrictions remain in force even if another tool or workflow suggests running verification automatically.

## Allowed work
- Inspect existing project source and documentation using read-only filesystem access (not Git or remote Supabase).
- Create and edit requested Flutter/Dart source files, local documentation, and proposed SQL migration files for owner review.
- Manually reason about code and inspect edits without invoking tests, analyzers, compilers, formatters, or Git.
- Provide explicit owner-only testing steps and migration instructions; do not execute them.

## Architecture
- Preserve functioning Module 1 authentication and authorization behavior, screens, and integrations.
- Keep `AuthRepository` independent of devotional and admin business logic and preserve the interchangeable Supabase authentication adapter.
- Follow existing feature-first modular organization, state management, routing, design tokens, and reusable widgets. Avoid wholesale refactors.
- Keep authorization server-enforced via Supabase RLS/trusted functions; UI role checks are not security boundaries.
- Roles: `member`, `admin`, `super_admin` where this is confirmed by the current DB snapshot. Only Super Admin may grant/revoke Admin.
- Private member devotional reflections/journals must not be readable by Admin or Super Admin; admins may access approved reading/completion/progress reporting only.
- Use `Asia/Manila` for church scheduling and day-boundary rules. Use timezone-aware values and server-side enforcement for completion limits.

## Database contract: zero guessing
1. Treat `docs/supabase-schema.md` as the **verified schema contract only where marked verified**. It may initially be incomplete.
2. Compare exact table/column identifiers, `data_type`, `udt_name`, nullability, defaults, PK/FK, CHECK, UNIQUE, and RLS policies before writing queries or Dart mapping.
3. Distinguish PostgreSQL `uuid`, `text`, `int4`, `int8`, `bool`, `date`, `timestamp`, `timestamptz`, `jsonb`, and custom enums; do not interchange them.
4. Map nullable database columns to nullable Dart fields; account for nullable results and defaults. Do not assume a PostgREST response shape.
5. Do not rename columns, add new tables, or change types implicitly. If a change is required, draft a **separate** SQL migration and update proposal with migration order and rollback notes; the owner applies it manually.
6. If the schema snapshot has not been populated, you may implement purely presentational work using clearly labeled mock data, but do not claim database integration is complete.
7. Never modify RLS or grant broader access to make a feature work. Propose policies for explicit owner review.

## UI and implementation standards
- Match or exceed the existing Module 1 “Modern Sanctuary” visual quality; maintain church blue/white branding, existing theme, typography, spacing, and background conventions.
- Deliver responsive mobile/web UI with accessible controls and loading, empty, error, and retry states.
- Prefer small focused edits, reusable components, and readable code; preserve working functionality.
- Do not introduce unnecessary new packages or heavy abstractions.

## Task workflow
1. Read this file, relevant existing code, and the schema contract.
2. Implement **only** the explicitly assigned task; do not expand into unrelated features.
3. Before writing schema-dependent code, check and document type compatibility against verified schema.
4. After edits, manually review source logic without executing commands prohibited above.
5. Report: files changed, features implemented, schema assumptions or blockers, unexecuted SQL/config changes for owner, manual test checklist, and unverified risks.
6. Clearly state: **Not tested; no Flutter, Supabase, or Git commands were run.**

## Approved product constraints (current specification)
- Shared weekday (Mon–Fri) official devotional assignments; no future completion; missed days eligible for catch-up.
- Explicit manual completion, confirmation before marking complete, no undo. Optional private reflection.
- One church-wide daily completion limit set by admins; reset at midnight Asia/Manila.
- Members see only personal progress. Admin and Super Admin see permitted church-wide and member completion analytics, never journal contents.
- Devotional administrative publishing/versioning/auditing and notifications have approved specifications; implement those only when explicitly assigned.
- Custom announcements may be devotional or general church-wide, immediately sent or scheduled; sent originals preserved with linked corrections; image and PDF attachments approved. Attachment **count/size limits remain undecided**, so do not invent them.

## Important
If project source, this document, and the verified schema disagree, raise a blocker rather than improvising. The owner is responsible for all verification and database operations.


## Database Schema Contract — Mandatory

The file `database.types.ts` contains the generated Supabase database types and is the primary reference for existing database objects.

Before implementing any database-related functionality, Codex MUST:

1. Read `database.types.ts`.
2. Match the exact table, column, relationship, and RPC names.
3. Respect the documented nullable, required, and optional fields.
4. Translate PostgreSQL/TypeScript types correctly into Dart types.
5. Never assume a table, column, constraint, or RPC exists if it is absent from the exported types.
6. Prepare proposed SQL migrations when new database objects are required, without executing them.
7. Do not assume generated types document RLS permissions or trigger behavior.

### Strict Execution Restrictions

Codex MUST NOT:

- Run any tests or Flutter applications.
- Run Flutter builds, analyzers, or formatting commands.
- Execute any Git command.
- Execute Supabase CLI commands.
- Connect to the remote Supabase database.
- Execute SQL queries or migrations.
- Modify live Supabase configuration.
- Deploy the application.

Codex may read existing project files, implement Flutter/Dart source code, and prepare unexecuted migration scripts.

The project owner is solely responsible for testing, Git operations, Supabase changes, and deployment.

### Architecture and UI Quality

- Preserve Module 1 authentication and authorization behavior.
- Maintain the existing AuthRepository and Supabase adapter separation.
- Follow established Flutter state management and project organization.
- Maintain or exceed Module 1's Modern Sanctuary design quality.
- Support responsive mobile and web layouts.
- Preserve strict privacy for members' devotional reflections.
- Do not introduce new dependencies without approval.
- Report all modified files, required database changes, and manual testing instructions after each development task.