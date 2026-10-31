# Module 2C devotional reader revision

## Status

The Flutter source and one consolidated SQL proposal are prepared for owner review.
The SQL has not been executed, dependencies have not been installed, and the
generated `database.types.ts` file has intentionally not been edited.

Until the Module 2C migration is applied, the reader can load the existing
published devotional but shows an explicit notice that reading engagement,
rich-text reflection saves, highlights, and synced preferences are unavailable.
It does not report a successful save when persistence is unavailable.

## Participation semantics

- **Read** means the member opened an available official devotional. It does
  not claim that every word was read.
- **Reflected** means the member saved a nonempty private rich-text reflection.
  Saving also ensures a Read record exists.
- Module 2B completion rows and `complete_devotional_assignment` remain intact
  for historical compatibility. Module 2C never calls that RPC.
- Dates with no current official assignment are neutral. Future progress and
  streak queries must build their denominator from available official
  assignment dates, then left-join reading states; they must not treat missing
  assignments as missed participation. This rule applies equally to every day
  of the week; weekday numbers must not create obligations.
- The legacy daily completion limit of 3 is not a reading/reflection limit.
  No replacement limit is proposed now. If abuse protection becomes necessary,
  it should be a separately reviewed request-rate policy, not a participation
  cap and not a reinterpretation of the legacy setting.

## Privacy and security

The proposed migration allows devotional admins to select reading-state
metadata for future reporting. It deliberately provides no admin policy for
reflection documents, devotional highlights, Bible highlights, or reader
preferences. Member ownership is checked with `auth.uid()`, and the two write
RPCs verify the published assignment and server-authoritative Manila date.

## Rich-text editor

The UI uses Quill Delta JSON as the canonical rich-text document and stores a
plain-text companion only for validation/accessibility. `flutter_quill` 11.5.0
is pinned because it is the newest stable version whose published constraint is
compatible with the project's Dart 3.11 SDK declaration. The owner must install
dependencies manually.

Ordinary editor clipboard operations are disabled through the editor's public
configuration and clipboard toolbar buttons are hidden. The app provides
**Insert Selected Passage** for text selected from the open devotional or Bible
passage. OS accessibility services, browser behavior, IMEs, and some mobile
context menus may bypass application-level clipboard controls; the app cannot
reliably prove whether manually typed text came from an AI system.

## Bible provider and licensing

`BibleProvider` is independent of `DevotionalRepository`. The initial
`LocalBibleProvider` is explicitly a limited test catalog, not an external API.
It contains a small set of faithfully copied public-domain ASV (1901) and World
English Bible samples for Genesis 1:1, Psalm 23:1, John 3:16, Matthew 6:33,
and Romans 8:28. eBible.org
identifies both translations as public domain; the World English Bible name is
an eBible.org trademark and is used only to identify the unmodified text.

Unsupported references return an honest missing-passage state. Production use
requires a licensed/API-backed provider or a reviewed expansion of the local
public-domain catalog. Copyrighted translation text must not be stored in the
database without permission; preferences and anchors store identifiers and
selected snippets, not a translation corpus.

## Historical reflection compatibility

Legacy plain-text reflections remain untouched. A future, separately reviewed
backfill may wrap each member's `reflection_text` in a single Quill insert plus
terminal newline and write it to the new owner-private document table. The
legacy source row should remain for rollback/audit, and no administrative view
may expose either representation.

## Owner-operated application order

1. Review `database/proposed/20261101_01_module_2c_consolidated.sql`,
   including the any-day scheduling change, RLS, grants, RPC ownership, and
   rollback comments. The separate 20261030 and 20261031 proposals are
   superseded; do not apply either of them in addition to this file.
2. Apply the consolidated file once, manually, after the applied Module 2B
   migrations. The weekday constraint is dropped with `IF EXISTS`, so an
   already-absent constraint does not fail the transaction.
3. Regenerate `database.types.ts` using the Supabase Dashboard project type
   export or another owner-authorized method. The local file is currently
   empty after a privilege-related generation failure; do not hand-edit it.
   Compare generated Module 2B and 2C shapes against the Dart mappings.
4. Install the declared Flutter dependencies manually.
5. Perform the manual test checklist from the completion report on web,
   Android, iOS, and a tablet-sized viewport.

