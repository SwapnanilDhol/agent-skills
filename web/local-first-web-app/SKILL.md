---
name: local-first-web-app
description: Build or review browser-only web apps that keep structured user data on-device, including IndexedDB persistence, migrations, offline behavior, local date/time semantics, backup/restore, and best-effort local reminders.
---

# Local-First Web App

Treat the browser as the user's data store while making the limitation explicit: data is tied to
the current browser and device unless the product later adds sync. Keep persistence dependable,
testable, and isolated from UI code.

## Persistence boundary

- Use IndexedDB for structured records, collections, and history; keep UI state out of the
  database adapter.
- Expose a small typed repository API such as list, create, update, and delete. Keep IndexedDB
  request/transaction details behind that boundary.
- Version the database and perform additive, deterministic migrations. Never reset user data to
  recover from a schema change.
- Resolve writes only after the transaction completes. Surface unavailable storage, quota, and
  transaction errors as real UI states rather than reporting a false success.
- Generate stable record IDs and deterministic ordering so reloads and tests are predictable.

## Dates and schedules

- Store calendar-only values as `YYYY-MM-DD` local-date strings; do not derive a user's calendar
  day by slicing a UTC ISO timestamp.
- Store timestamps as ISO instants only when the event time itself matters.
- Keep recurrence rules separate from occurrences or completion records. Decide explicitly how
  start dates, schedule edits, archived records, timezone changes, DST, leap days, and the
  boundary between “today” and “missed” behave.
- Test date calculations at midnight, week boundaries, leap days, DST changes, and a non-default
  timezone.

## Offline and privacy behavior

- Keep core reads and writes available after the application shell has loaded once.
- Do not send habit names, completion history, or other user records to a server in a local-only
  product. Avoid analytics that silently identify or upload those records.
- Explain local-only storage at first run and in settings. Warn that clearing site data,
  changing browsers, or changing devices can remove access.
- Offer versioned JSON export and validated import when losing data would be materially harmful.
  Validate the complete file before applying it, and leave the existing dataset unchanged on
  failure. Confirm destructive clear-all actions.

## Local reminders

If reminders are browser-only, use in-page scheduling plus the Notifications API as a best-effort
enhancement. Ask for permission after a direct user action, persist a delivery key to prevent
duplicates, and recheck on load, focus, and visibility changes. A page timer cannot guarantee a
notification after the tab or browser is closed; do not promise background delivery through
experimental periodic-sync APIs. Make denial or unsupported browsers a usable in-app state.

## Verification

Test repository operations with an IndexedDB-capable test environment, including transaction
failure and migration paths. Exercise create → reload → read, offline core flows, export/import,
and a reminder recheck. Inspect network requests to confirm that local records stay local.
