---
name: asc-morning-brief
description: >-
  Collect App Store Connect analytics and write an evidence-backed morning
  executive brief (acquisition, monetization, crashes by version, ratings,
  release health). Use when the user asks for latest App Store numbers, ASC
  analytics, morning brief, download/conversion performance, or a similar
  report for Neon or another configured iOS app.
disable-model-invocation: true
---

# ASC Morning Executive Brief

Read-only App Store Connect morning brief. Do **not** respond to reviews, edit
metadata, change pricing, submit releases, or mutate ASC.

## When invoked

1. Resolve the app config (below).
2. Authenticate / collect evidence.
3. Analyze artifacts only — never invent missing metrics.
4. Write `EXECUTIVE_SUMMARY.md` in the artifact directory.
5. Show the user a short readout + KPI scorecard + ≤5 actions.
6. Optionally refresh a canvas if the host workflow already uses one.

## App config

Look for the first existing file (repo root):

1. `.asc/morning-brief.json`
2. `app_store/morning_brief.json`

If missing and the repo is Neon/ColorPicker, use defaults:

```json
{
  "appName": "Neon",
  "appId": "1480273650",
  "platform": "IOS",
  "bundleId": "com.SwapnanilDhol.ColorPicker",
  "xcodeCloudWorkflowId": "A66EEFB1-5AF2-487F-99F0-5DFB4238DAEE",
  "collector": "make morning-brief",
  "artifactGlob": ".tmp/neon-morning/*",
  "officialAnalyticsScript": "app_store/scripts/collect_neon_official_analytics.rb"
}
```

For **another app**, create `.asc/morning-brief.json` (see
[app-config.example.json](app-config.example.json)) with at least `appName`,
`appId`, `platform`. Then either:

- point `collector` at a repo script that wraps `asc`, or
- leave `collector` empty and use the **generic collection** steps below.

## Prerequisites

```bash
asc doctor
asc status --app "<appId>" --platform "<platform>"
asc web auth status
```

If web auth is false:

```bash
asc web auth login --apple-id "<email>"
```

Never put Apple passwords in prompts, commits, or argv. Prefer cached session.

Set `ASC_TIMEOUT=120s` (or higher) if overview collection times out.

## Collection

### A. Project collector (preferred)

If config has `collector` (e.g. `make morning-brief`):

```bash
# from repo root
eval "$collector"
```

Use the printed artifact directory. Follow its `MODEL_INSTRUCTIONS.md` exactly.

### B. Generic collection (no project collector)

Create `.tmp/asc-morning/<timestamp>/` with `public/`, `web/`, `official/`.

**Public API (required):**

```bash
APP="<appId>"; OUT=".tmp/asc-morning/<timestamp>"
asc status --app "$APP" --platform IOS --output json --pretty > "$OUT/public/release-status.json"
asc review status --app "$APP" --platform IOS --output json --pretty > "$OUT/public/review-status.json"
asc reviews ratings --app "$APP" --all --workers 20 --output json --pretty > "$OUT/public/ratings.json"
asc reviews --app "$APP" --sort=-createdDate --paginate --include-response --output json --pretty > "$OUT/public/reviews.json"
asc product-pages custom-pages list --app "$APP" --paginate --output json --pretty > "$OUT/public/custom-product-pages.json"
```

Add Xcode Cloud / pricing / performance commands when IDs exist in config.

**Web analytics (best-effort):** use yesterday as `END`.

```bash
END=$(date -v-1d +%F)   # macOS; else date -d yesterday +%F
START7=$(...); PREV7...; START28...; PREV28...  # equal-length windows ending END
asc web analytics overview --app "$APP" --start "$START7" --end "$END" --output json > "$OUT/web/overview-current-7d.json"
asc web analytics overview --app "$APP" --start "$PREV7_START" --end "$PREV7_END" --output json > "$OUT/web/overview-previous-7d.json"
asc web analytics overview --app "$APP" --start "$START28" --end "$END" --output json > "$OUT/web/overview-current-28d.json"
asc web analytics overview --app "$APP" --start "$PREV28_START" --end "$PREV28_END" --output json > "$OUT/web/overview-previous-28d.json"
asc web analytics sources --app "$APP" --start "$START28" --end "$END" --output json > "$OUT/web/sources-current-28d.json"
asc web analytics sales --app "$APP" --start "$START28" --end "$END" --output json > "$OUT/web/sales-current-28d.json"
asc web analytics subscriptions --app "$APP" --start "$START28" --end "$END" --output json > "$OUT/web/subscriptions-current-28d.json"
asc web analytics campaigns --app "$APP" --start "$START28" --end "$END" --output json > "$OUT/web/campaigns-current-28d.json"
asc web analytics benchmarks --app "$APP" --output json > "$OUT/web/benchmarks.json"
```

Isolate failures: empty/partial files are OK; continue.

**Official Analytics Reports API:** if
`officialAnalyticsScript` exists, run it into `$OUT/official/`. Otherwise note
version-level crashes/downloads as unavailable from official TSVs.

Write a short `MODEL_INSTRUCTIONS.md` listing periods, evidence files, and
failures (mirror Neon's collector contract — see [report-contract.md](report-contract.md)).

## Analysis rules

1. Use the last **complete** day, not today's partial day.
2. Compare current 7d vs previous 7d and current 28d vs previous 28d.
3. Show absolute + % change when denominator ≠ 0.
4. Label missing metrics `unavailable` — never coerce to zero.
5. Cite artifact filenames after material claims.
6. Separate first-time downloads / redownloads / updates.
7. Separate proceeds vs sales; state currency.
8. Separate ratings vs written reviews.
9. Prefer `official/*.tsv` for version crashes/downloads when present.
10. If `overview-current-7d` fails, **derive** 7d totals by slicing
    `overview-current-28d` daily series into equal windows; say so in Data health.
11. Newest web day often incomplete (zeros) — call it out; avoid strong DoD claims.
12. Campaign dashboards appear only after ≥5 first-time downloads + ~24h.
13. Executive readout ≤5 bullets; recommendations ≤5 actions.

## Funnel diagnosis (when downloads look weak)

Compute for the current 28d window:

- impressions → page views %
- page views → first downloads %
- Apple conversion vs `web/benchmarks.json` peer p50
- Browse vs Search unique page views
- Web referrer / campaign attributed first downloads

State whether the bottleneck is **visibility**, **click-through**, **conversion**,
or **missing external demand**.

## Output

Write `$OUT/EXECUTIVE_SUMMARY.md` using the section order in
[report-contract.md](report-contract.md).

Then reply to the user with:

1. Headline (1–2 sentences)
2. 7d KPI table
3. Version/quality note if official crashes exist
4. ≤5 actions
5. Path to `EXECUTIVE_SUMMARY.md`

## Porting checklist (new app)

- [ ] `asc` API key works for that app
- [ ] Web session authenticated for the correct provider
- [ ] `.asc/morning-brief.json` filled
- [ ] Optional: copy/adapt Neon collectors from ColorPicker
  `app_store/scripts/collect_neon_morning_brief.rb` +
  `collect_neon_official_analytics.rb` (replace hardcoded app IDs)
- [ ] Optional: `make morning-brief` target
- [ ] Ensure `.tmp/` is gitignored

## Safety

- Read-only ASC operations only.
- Do not commit `.tmp/` analytics artifacts or review bodies.
- Do not print secrets from `~/.asc/` or env.
