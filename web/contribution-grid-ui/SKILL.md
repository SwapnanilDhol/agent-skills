---
name: contribution-grid-ui
description: Design, implement, or review GitHub-style contribution calendars and date-based heatmaps for habits, activity, progress, or other recurring events.
---

# Contribution Grid UI

Make the calendar visually satisfying without hiding the meaning of a cell. Start with a domain
definition of scheduled, completed, missed, unscheduled, today, and future dates; then render
that definition consistently in the grid, tooltip, legend, and accessible text.

## Define the data contract first

- Use one cell per local calendar date.
- Define the week-column and weekday-row ordering explicitly. Keep it stable across locales.
- Distinguish “not scheduled” from “scheduled but incomplete”; they must not share an accidental
  color or imply a missed habit.
- Disable or label future cells instead of treating them as failures.
- For an aggregate grid, document the denominator and intensity buckets (for example, completed
  scheduled habits divided by scheduled habits). For a per-habit grid, prefer categorical states.
- Keep streak calculations in domain logic. Do not infer streaks from visual color levels.

## Render the calendar

- Show a useful bounded range, such as the trailing 52 weeks, without making the first viewport
  unusable on a phone.
- Keep the current date visible and make dense cells large enough to tap or focus.
- Use an explicit legend and a text summary for every state. Color should reinforce state, not be
  its only encoding.
- Use accessible names such as “Monday, September 14: completed” and expose the same information
  in a tooltip or detail surface for pointer users.
- Support keyboard focus and activation for editable historical cells; do not make a decorative
  preview look interactive.
- Provide a responsive strategy deliberately: compact cells with horizontal scrolling, a shorter
  range, or a detail view are all valid if the choice preserves date comprehension.

## Calendar correctness

Test the grid around local midnight, week and year boundaries, leap days, DST transitions, a
non-default first day of week, schedule start dates, schedule edits, archived habits, and timezone
changes. Verify that past corrections update summaries and streaks without rewriting unrelated
history.

## Visual review

Inspect empty, sparse, dense, mixed-state, and future-date grids. Check contrast and high-contrast
mode, color-vision safety, focus visibility, touch sizing, and a narrow viewport. A successful
render is not enough: a user should be able to answer “what happened on this date?” without
guessing.
