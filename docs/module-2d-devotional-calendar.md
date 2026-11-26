# Module 2D devotional calendar backend

Status: source implementation and proposed migration prepared; owner application
and runtime verification are pending.

## Scope

The calendar reuses the existing Module 2B assignment/completion tables and the
Module 2C reading-state and reflection tables. Module 2D adds one small
member-owned daily activity table. One read-only RPC returns the requested month
and the signed-in member's progress in a single database request.

## Calendar rules

- The Manila calendar date is returned by the database.
- Only current published assignments through today are obligations.
- Saturday and Sunday assignments work the same as weekday assignments.
- A date without a current published assignment is neutral.
- Read includes a Module 2C opening or a retained Module 2B completion.
- Reflected includes Module 2C `reflected_at` or a retained Module 2B private
  reflection.
- Current streak counts distinct consecutive Asia/Manila calendar dates with
  genuine devotional reading or successful meaningful-reflection activity.
- At most one streak day is recorded per member per Manila calendar date,
  regardless of how many current or historical devotionals the member opens.
- If there is activity today, the streak is counted backward from today. If
  today is still inactive but yesterday was active, it is counted backward from
  yesterday. Otherwise the current streak is zero.
- Today remains eligible until midnight Asia/Manila, so inactivity today does
  not prematurely discard an active streak ending yesterday.
- Opening or reflecting on a historical devotional updates that devotional's
  scheduled-date Read/Reflected state and totals while also recording activity
  for the actual day of engagement.
- Reopening a devotional on a later day can qualify that later day once, without
  duplicating its scheduled-date Read status or changing `first_opened_at`.
- Retired dates can remain in all-time participation totals but are not current
  month obligations.

Scheduled-date participation remains grouped by member and scheduled date,
preventing duplicate totals when Module 2B and Module 2C both contain the date.
Daily streak activity is stored separately in
`public.member_devotional_daily_activity` with primary key
`(member_id, activity_date)`.

The one-time backfill uses only retained event timestamps: Module 2C first/last
opening and reflection timestamps, reflection document creation/update times,
and Module 2B completion/reflection timestamps. It converts each actual event
timestamp to Asia/Manila and groups duplicate dates. Intermediate historical
activity days that were never retained cannot be reconstructed and are not
invented.

## Source contract

The Flutter repository method is:

`getMyCalendarMonth({required DateTime month})`

It calls:

`public.get_my_devotional_calendar_month(p_month date) -> jsonb`

The returned JSON contains `manila_today`, `month_start`, `month_end`, `summary`,
and `days`. Each day contains the current assignment revision, its immutable
content version, and private `is_read` / `is_reflected` flags.

## Security boundary

The Calendar RPC is `SECURITY INVOKER`, has an empty `search_path`, and requires
`auth.uid()`. The daily table has RLS and permits authenticated members to select
only their own rows. Direct client writes are not granted; the established
trusted opening and reflection RPCs perform the atomic daily upsert after their
existing member and assignment checks. Private reflection text is not returned.

## Owner-operated application order

1. Confirm the owner-reported Module 2C tables/RPCs and Calendar RPC are already
   deployed. Do not rerun their migrations.
2. Do not apply the superseded scheduled-date streak proposal
   `database/proposed/20261102_02_fix_historical_devotional_streak.sql`.
3. Review and manually apply only
   `database/proposed/20261102_03_daily_devotional_activity_streak.sql` once.
4. Regenerate `database.types.ts` from the intended Supabase project using an
   owner-authorized method. Do not hand-edit the generated file.
5. Restart the application and perform the manual checks below.

## Manual checks

- STREAK-01: With no activity today, open one devotional and confirm the streak
  records one activity day.
- STREAK-02: Open five different devotionals today and confirm the streak value
  does not increase after the first qualifying activity.
- STREAK-03: Open an old devotional today and confirm today receives the one
  activity day, not the devotional's scheduled date.
- STREAK-04: Return tomorrow and open any available devotional; confirm the
  consecutive streak increases by one.
- STREAK-05: Miss a complete Manila day; after the following Manila midnight,
  confirm the current streak is zero.
- STREAK-06: Resume after that missed day and confirm the streak starts at one.
- STREAK-07: Revisit an already-read devotional on a later day and confirm that
  later day qualifies once without duplicating Days Read.
- STREAK-08: Confirm historical Read/Reflected indicators and lifetime/monthly
  totals remain attached to the devotional's scheduled date.
- STREAK-09: Sign in as another member and confirm streak data is isolated.
- STREAK-10: Verify one opening immediately before 11:59 PM and another after
  12:00 AM Asia/Manila create two consecutive activity dates.
- Confirm Saturday/Sunday assignments and dates without assignments retain their
  existing Calendar behavior.
