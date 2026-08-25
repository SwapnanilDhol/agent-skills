---
name: app-attestation
description: Implement or review App Attest-backed authenticated sessions for SFK-first iOS apps with RevenueCat and a backend Worker.
---

# App Attestation

Use this skill when adding or reviewing Apple App Attest, authenticated backend sessions, RevenueCat purchase binding, or the staged rollout of those protections in an SFK-first iOS app.

Before changing code, read the canonical implementation playbook:

<https://github.com/SwapnanilDhol/ios-dev-guide/blob/main/stack/app-attestation.md>

## Ownership split

- Put App Attest mechanics—key generation, device-only Keychain storage, challenge hashing, attestation, and assertions—in SwapFoundationKit.
- Put verified StoreKit transaction and RevenueCat purchase-proof extraction in SwapProKit.
- Keep session lifecycle, API headers, purchase timing, entitlement policy, and UI behavior in the host app.
- Keep attestation/assertion verification, assertion counters, session persistence, token issuance, RevenueCat correlation, and rate limits in the Worker.

## Non-negotiable security rules

- The bearer session is the credential. Never authorize from `X-App-User-ID`, RevenueCat IDs, or client-side Pro state alone.
- Verify the App Attest certificate chain, app ID, nonce, environment, key ID, assertion counter, token expiry, and purchase correlation on the server.
- Only bind a RevenueCat ID after the server correlates a verified StoreKit transaction JWS with the RevenueCat customer record.
- Keep development and production bundle IDs, entitlements, Keychain keys, and Worker environments separate. Never accept development attestation on production.
- Do not generate assertions for every request. Enroll once, issue short-lived sessions, and refresh near expiry or after purchase binding.
- Never log or persist raw secrets, bearer tokens, attestation objects, assertion objects, or purchase JWS values.

## Implementation workflow

1. Inspect package revisions, bundle IDs, entitlements, RevenueCat entitlement configuration, API header construction, Worker configuration, and D1 migrations.
2. Check SwapFoundationKit capabilities before adding host-side primitives; check SwapProKit before reimplementing purchase-proof extraction.
3. Add the smallest host `BackendSessionService` actor needed for bootstrap, enrollment, session refresh, secure token storage, and purchase binding. Keep AppDelegate as orchestration only.
4. Add Worker auth routes, D1 persistence, verifier configuration, and replay/counter/identity checks without changing unrelated endpoints.
5. Add tests for replay, expiry, identity mismatch, key rebind, assertion counter failures, and purchase-correlation failures.
6. Configure `AUTH_SESSION_SECRET` as a Worker secret and apply the D1 migration before enforcement.
7. Deploy with `AUTH_ENFORCE_SESSIONS=false` while the updated app rolls out. Enable enforcement only after real-device production smoke tests and acceptable adoption.
8. Validate Worker typecheck/tests and an iOS build. Do not claim production readiness without a real-device App Attest check.

## Required handoff

Report which code belongs in SFK, SwapProKit, the host app, and the Worker; required secrets/entitlements/migrations; current enforcement state; tests/builds run; and any real-device validation still pending.

