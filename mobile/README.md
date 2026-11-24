# RondiTrack Mobile

Flutter app (Android and iOS) for RondiTrack. Lives beside the API, three flavours, strict lints.

## Contract notes

Read from the API repo `AndiswaMbonambi08/RondiTrack` at commit `67a82a01f540f97ed481d0d01d1d6c201e0b7e6c`: its README and the generated types in `web/src/api/schema.d.ts`.
Contract copy: `contract/schema.d.ts` is the openapi-typescript output of the API's live OpenAPI document (`web/src/api/schema.d.ts`) at that commit. The committed `clients/typescript/openapi.json` export at that commit predates `arrearsCents`, so it is not the current contract; refreshing it is a backend follow-up.

1. **Spellings (case matters).** Contribution status is a real enum: `Pending`, `Paid`, `Confirmed`. Cycle status is a plain string, documented as `Open`, `Closed` (set by the cycle-close job) or `PaidOut`. Role is a plain string: `Member`, `Treasurer`, `Admin`. Any other string becomes `unknown`.
2. **Role.** `GET /api/v1/me/home` returns it per stokvel as `stokvels[].role`. It is never on the user or in the token (the token carries only `sub`, `jti` and, for platform admins, a `PlatformAdmin` role claim). The stokvel detail fake returns it on the stokvel the same way. Admin satisfies every Treasurer check.
3. **/me/home.** Per stokvel: `stokvelId`, `name`, `role`, `currentCycle` (`{id, label, status, dueDate}` or `null`), `paidCents`, `owedCents`, `arrearsCents` (int64 cents, never null) and `nextPayoutUtc` (date-time or `null`). The app shows them and never computes them. A user in no stokvels gets `200` with an empty list.
4. **Due dates.** `currentCycle.dueDate` is date-only (`2026-10-31`, nullable), modelled as a UTC-midnight `DateTime`. `nextPayoutUtc` is an instant (the last moment of the month in Johannesburg, `21:59:59Z`). Both are shown as a date in South African time (UTC+2, no daylight saving).
5. **Seed personas.** Sipho: Member of Ubuntu Savings Circle and Treasurer of Umoja Family Fund (one login, two roles). Nomsa: Admin of Umoja Family Fund. The platform admin (`admin@example.com`) stays out of stokvel membership, so it is the empty-Home persona. The fakes hold the same people and stokvels; contributors and amounts inside them are made-up fake data.

Backend gaps found: `role` and cycle `status` are published as plain `string` in the OpenAPI document, not as enums, so the contract does not list their spellings (only a description does). Recorded as a gap, not fixed this week: the app maps any unexpected string to `unknown`.

### Payouts (10.3)

Read from API commit `0643e4b5f1`. API `main` had no endpoint for a cycle's payout order, so the gap is fixed in the API repo, with tests: hat does a non-member get? | 404 problem+json "Payout order not found.", identical to an unknown stokvel, an unknown cycle, a cycle of another stokvel and a malformed id. The fake throws `NotFoundException`. |

| # | Question | Answer |
|---|---|---|
| 1 | Which endpoint returns a cycle's payout order, and what does each entry hold? | `GET /api/v1/stokvels/{stokvelId}/cycles/{cycleId}/payout-order` returns `{ stokvelId, cycleId, items[] }`. Each item holds `memberId`, `memberName`, `position` (1-based), `amountCents` (the pot), `payoutDate` (`yyyy-MM-dd` in Johannesburg, or `null` until paid) and `status`. `PayoutEntry` copies this with `Cents`, a `DateTime?` and `PayoutStatus`. |
| 2 | How does the API spell each payout status? | Exactly `Paid`, `Next`, `Waiting` (case matters). Anything else becomes `PayoutStatus.unknown`. |
| 3 | Does the API say who is next? | Yes: the item with status `Next` (none when everyone is paid). The server also decides the order and the positions. The app never sorts, counts or adds up. |
| 4 | W| 5 | Which role may record a payout, and what does anyone else get? | Treasurer (Admin satisfies it) of that stokvel. `POST /api/v1/stokvels/{id}/cycles/{cycleId}/payout`: non-member 404, member 403, treasurer 201. The button shows only for Treasurer or Admin in that stokvel's membership, and only while the API says someone is Next. |

## Running it

- API repo: `AndiswaMbonambi08/RondiTrack`. Nothing calls it yet: the app runs on fake repositories with the seed personas, so no API needs to be started this week. In Week 11 the dev flavour points at it (start it with `docker compose up` or `dotnet run` as its README says).
- Flutter 3.47.7. First Gradle build can take over ten minutes.
- `flutter run --flavor dev --dart-define-from-file=config/dev.json`
- `flutter run --flavor staging --dart-define-from-file=config/staging.json`
- `flutter run --flavor prod --dart-define-from-file=config/prod.json`
- Each `config/<flavor>.json` holds `FLAVOR` and `API_BASE_URL` only, nothing secret. The app refuses to start without a config, and refuses a build whose native flavour differs from the config's `FLAVOR` (unit-tested).
- Flavours: dev (`.dev`, "RondiTrack Dev"), staging (`.staging`, "RondiTrack Staging"), prod (no suffix, "RondiTrack"). The launcher name is set with a manifest placeholder, not `resValue`.
- Lint rule `public_member_api_docs` is switched off on purpose: this is an app, not a package, so doc comments on every public member add noise.

## Generated code

**Ignored in Git, generated in CI.** Reason: generated files make noisy diffs and merge conflicts and can go stale; CI always builds them from source. CI order works with this: `pub get`, format check (before generation, so generated files are never formatted-checked), `build_runner build`, `dart analyze --fatal-infos`, `flutter test`.

## Money

- `Cents` extension type over `int`; no `double` anywhere near money.
- Formatter: en-ZA, no-break spaces, integer arithmetic: `R 0,10`, `R 150,50`, `R 1 500,00`, `R 1 000 000,00`, negative as `-R 150,00`.
- Parser accepts `150`, `150,50`, `R150`, `R 1 500`, `1 500,50` (space or no-break space). Refuses `1,500.50`, `150,505`, `150.`, empty and letters.
- **Full-stop decision:** a single full stop IS accepted as a decimal separator (`150.50` = R150,50) because many phone keyboards have no comma. It is only accepted with 1-2 digits after it and never together with a comma.

## When the API adds a status

I added `archived('Archived')` to `CycleStatus` and ran `dart analyze`. It reported:

```
Analyzing mobile...

  error - lib\features\stokvel\domain\actions.dart:21:25 - The type '(CycleStatus, ContributionStatus?)' isn't exhaustively matched by the switch cases since it doesn't match the pattern '(CycleStatus.archived, _)'. Try adding a wildcard pattern or cases that match '(CycleStatus.archived, _)'. - non_exhaustive_switch_expression
  error - lib\features\stokvel\domain\actions.dart:42:28 - The type '(StokvelRole, CycleStatus)' isn't exhaustively matched by the switch cases since it doesn't match the pattern '(StokvelRole.member, CycleStatus.archived)'. Try adding a wildcard pattern or cases that match '(StokvelRole.member, CycleStatus.archived)'. - non_exhaustive_switch_expression
  error - lib\features\stokvel\presentation\labels.dart:4:42 - The type 'CycleStatus' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'CycleStatus.archived'. Try adding a wildcard pattern or cases that match 'CycleStatus.archived'. - non_exhaustive_switch_expression

3 issues found.
```

At run time on a phone with an old install, the new string `Archived` is not in the old app's enum, so `CycleStatus.parse` returns `unknown`. Nothing throws; the screen shows "Status unavailable" and no actions are offered for that cycle until the app is updated.

## Provider lifetimes

| Provider | Holds | Lifetime | Cost of keeping (entry-level phone) | Cost of disposing |
|---|---|---|---|---|
| `currentPersona` | Who is signed in (an id) | keepAlive | Tiny; must be cleared on sign-out | Would lose the session on every rebuild |
| `homeRepository` | Repository object, no data | keepAlive | Negligible memory | Recreated cheaply, but it rebuilds when the persona changes anyway |
| `stokvelRepository` | Repository object, no data | keepAlive | Negligible memory | Same as above |
| `homeController` | One card per stokvel | autoDispose | Small, but goes stale | A refetch and spinner when Home is reopened from nothing |
| `stokvelDetail(id)` | Stokvel, cycle, contributions for one id | autoDispose (family) | Grows per visited stokvel, holds paid data on a shared phone, goes stale | A refetch and spinner (about 3 s on Umoja Family Fund) |

Disposal proof: `test/stokvel/stokvel_detail_provider_test.dart` shows the id's state no longer exists once nothing listens; the provider also logs `stokvelDetail disposed id=<id>` (id only, never a name or an amount).

**Sign-out.** Sign-out will rebuild the root `ProviderScope` with a new key, which disposes every provider including the kept-alive ones (session, repositories, any cached data), so nothing survives into the next person's session on a shared phone. Sign-out will also clear the stored token first and invalidate `currentPersona` so a failed scope rebuild cannot leave an identity behind.


## Routes

Every screen has an address. A signed-out visit to any address goes to sign-in and then comes back to it. Typed routes (`go_router_builder`) are the only way widgets navigate: there is no string path and no `Navigator.push`.

| Address | Screen and tab | Signed out | Not a member | Back goes to |
| --- | --- | --- | --- | --- |
| `/` | Home, Home tab | Sign-in, then `/` | Only your own stokvels are listed | Leaves the app |
| `/stokvels` | Stokvel list, Stokvels tab | Sign-in, then `/stokvels` | Only your own stokvels are listed | Leaves the app |
| `/stokvels/:id` | Stokvel detail, Stokvels tab. At 840 dp or wider it is the list and the detail side by side | Sign-in, then this address | "Stokvel not found", the same screen as for a stokvel that does not exist | `/stokvels` (the detail sits on the list, also from a cold start) |
| `/stokvels/:id/cycles/:cycleId` | Cycle, Stokvels tab | Sign-in, then this address | "Stokvel not found". A cycle id from a different stokvel: "Cycle not found" | `/stokvels/:id`, then `/stokvels` |
| `/stokvels/:id/cycles/:cycleId/payouts` | Cycle, Stokvels tab | Sign-in, then this address | "Stokvel not found". A cycle id from a different stokvel: "Cycle not found" | `/stokvels/:id`, then `/stokvels` |
| `/activity` | Activity tab | Sign-in, then `/activity` | Only your own stokvels' contributions are listed | Leaves the app |
| `/profile` | Profile tab, with sign out | Sign-in, then `/profile` | Not applicable | Leaves the app |
| `/join/:code` | Invitation preview, on top of Home | Sign-in, then this address | Unknown code: "Invitation not found" | `/` (Home) |
| `/sign-in` (`?from=`) | Sign-in, no tabs | Stays | Not applicable | Leaves the app. Signed in: goes to `from` when it is inside the app, else `/` |
| anything else | "Page not found" with a Go to Home button | Sign-in, nothing remembered | Not applicable | Home |

**Tapping the tab you are on** returns to that tab's first screen (`goBranch(initialLocation: true)`). Tapping a different tab keeps that tab's stack and scroll position. Both are tested.

## The gate

One pure function, `redirectFor(signedIn, location)` in `lib/app/redirect.dart`, decides every navigation. It needs no widget, so `test/app/redirect_test.dart` tests it directly.

- **Signed out:** every address except `/sign-in` goes to `/sign-in`. If the address is inside the app and is not Home, it travels along as `?from=<address>`.
- **Signed in, on `/sign-in`:** go to `from` if it is an address inside the app, otherwise Home.
- **Signed in, anywhere else:** nothing changes.
- **What is remembered:** only an address that starts with a single `/`, has no scheme or host, and begins with a known root (`stokvels`, `activity`, `profile`, `join`). `https://...`, `//host`, `javascript:` and unknown paths land on Home.
- **When it runs:** the router listens to a notifier that bumps whenever the auth provider changes (`refreshListenable`), so signing out redirects immediately, not on the next tap. After sign-out the signed-in screens are gone from the stack, so back cannot return to them.
- **Week 11:** the fake `Auth` provider is replaced by the API. The gate only reads "signed in or not", so it does not change.

## Deep links

**Choice: a custom scheme**, `ronditrack://<applicationId>/<path>`. The host is the flavour's own application id, filled in by Gradle (`${applicationId}`) in the manifest's intent filter, so a link aimed at the dev build can only be claimed by the dev build. Flutter hands the router the path and query, so `/stokvels/:id`, `/stokvels/:id/cycles/:cycleId` and `/join/:code` open the same screens as in the app, while it is running and from a cold start. Signed out, the link goes to sign-in and then on to the address.

**dev** (application id `za.co.mathabo.ronditrack.dev`)

```powershell
# cold start: force-stop first, then open each link
adb shell am force-stop za.co.mathabo.ronditrack.dev
adb shell am start -W -a android.intent.action.VIEW -d "ronditrack://za.co.mathabo.ronditrack.dev/stokvels/umoja-family-fund" za.co.mathabo.ronditrack.dev
adb shell am force-stop za.co.mathabo.ronditrack.dev
adb shell am start -W -a android.intent.action.VIEW -d "ronditrack://za.co.mathabo.ronditrack.dev/stokvels/umoja-family-fund/cycles/cycle-umoja-5" za.co.mathabo.ronditrack.dev
adb shell am force-stop za.co.mathabo.ronditrack.dev
adb shell am start -W -a android.intent.action.VIEW -d "ronditrack://za.co.mathabo.ronditrack.dev/join/ubuntu2026" za.co.mathabo.ronditrack.dev
```

**staging** (application id `za.co.mathabo.ronditrack.staging`)

```powershell
# cold start: force-stop first, then open each link
adb shell am force-stop za.co.mathabo.ronditrack.staging
adb shell am start -W -a android.intent.action.VIEW -d "ronditrack://za.co.mathabo.ronditrack.staging/stokvels/umoja-family-fund" za.co.mathabo.ronditrack.staging
adb shell am force-stop za.co.mathabo.ronditrack.staging
adb shell am start -W -a android.intent.action.VIEW -d "ronditrack://za.co.mathabo.ronditrack.staging/stokvels/umoja-family-fund/cycles/cycle-umoja-5" za.co.mathabo.ronditrack.staging
adb shell am force-stop za.co.mathabo.ronditrack.staging
adb shell am start -W -a android.intent.action.VIEW -d "ronditrack://za.co.mathabo.ronditrack.staging/join/ubuntu2026" za.co.mathabo.ronditrack.staging
```

**prod** (application id `za.co.mathabo.ronditrack`)

```powershell
# cold start: force-stop first, then open each link
adb shell am force-stop za.co.mathabo.ronditrack
adb shell am start -W -a android.intent.action.VIEW -d "ronditrack://za.co.mathabo.ronditrack/stokvels/umoja-family-fund" za.co.mathabo.ronditrack
adb shell am force-stop za.co.mathabo.ronditrack
adb shell am start -W -a android.intent.action.VIEW -d "ronditrack://za.co.mathabo.ronditrack/stokvels/umoja-family-fund/cycles/cycle-umoja-5" za.co.mathabo.ronditrack
adb shell am force-stop za.co.mathabo.ronditrack
adb shell am start -W -a android.intent.action.VIEW -d "ronditrack://za.co.mathabo.ronditrack/join/ubuntu2026" za.co.mathabo.ronditrack
```


Force-stop before each link, or you are only testing a running app. Back from the cycle link goes to the stokvel, then the list. Back from the invite link goes to Home.

**What a verified App Link would add.** An `https://` link that opens the app directly with no chooser, and nothing else can claim it. It needs a domain I own, a `/.well-known/assetlinks.json` file on it listing each flavour's package name and signing certificate fingerprint, and `android:autoVerify="true"` on an `https` intent filter. Anyone tapping the link without the app installed would land on a web page instead of a dead end.

**What an `adb` test does and does not prove.** It proves the intent filter matches, the right flavour is chosen by its application id, the cold start builds the right back stack and the redirect keeps the address through sign-in. It does not prove domain ownership or verification, how a messaging app, browser or email client treats the link, or that another app has not claimed the same scheme (a custom scheme is not exclusive).

## Theme

**Seed colour:** `#1B6B4A`, a deep green, in `lib/core/theme/app_theme.dart`. Material 3 builds the light and dark schemes from it and the app follows the phone's setting. The page colours (`surface`, `onSurface`) are set from the tokens, so the table below is the contrast on screen.

Tokens Material does not have live in a `ThemeExtension` (`StatusColors`): one pair per contribution status (`pending`, `paid`, `confirmed`), per cycle status (`open`, `closed`, `paidOut`, `unknown`) and `arrears`, each with its own light and dark values. Widgets ask `context.statusColors.arrears`, never for a red. Every chip says its status in words with an icon, and `test/theme/no_typed_colours_test.dart` fails if a colour is typed anywhere outside `lib/core/theme`.

**Contrast, measured.** Checker: the WCAG 2.x relative-luminance formula in `tool/contrast_table.dart` (regenerate this table with `dart run tool/contrast_table.dart`). `test/theme/contrast_test.dart` fails the build if any chip text drops under 4.5:1 or any chip border under 3:1 against the page, in either theme.

| Token | Theme | Text on its chip (needs 4.5:1) | Border on the page (needs 3:1) |
| --- | --- | --- | --- |
| body text | light | #191C1A on #FBFDF8: 16.78:1 | n/a |
| body text | dark | #E0E4DF on #101411: 14.45:1 | n/a |
| pending | light | #5F4100 on #FFF0CC: 8.29:1 | #5F4100 on #FBFDF8: 9.14:1 |
| pending | dark | #FFD98A on #3D2C00: 9.97:1 | #FFD98A on #101411: 13.75:1 |
| paid | light | #0B3D66 on #DCEEFF: 9.46:1 | #0B3D66 on #FBFDF8: 10.95:1 |
| paid | dark | #A9D4FF on #0E2F4F: 8.81:1 | #A9D4FF on #101411: 11.99:1 |
| confirmed | light | #0F4D2A on #D9F5E3: 8.57:1 | #0F4D2A on #FBFDF8: 9.69:1 |
| confirmed | dark | #A6E8C0 on #0D3320: 9.87:1 | #A6E8C0 on #101411: 13.21:1 |
| open | light | #00464A on #D4F3F5: 9.08:1 | #00464A on #FBFDF8: 10.38:1 |
| open | dark | #9FE8EC on #00373A: 9.47:1 | #9FE8EC on #101411: 13.47:1 |
| closed | light | #3A3F44 on #E6E9EC: 8.73:1 | #3A3F44 on #FBFDF8: 10.39:1 |
| closed | dark | #D3D8DD on #2B3035: 9.28:1 | #D3D8DD on #101411: 12.95:1 |
| paidOut | light | #3F1D7A on #EBE3FF: 10.17:1 | #3F1D7A on #FBFDF8: 12.29:1 |
| paidOut | dark | #D9C8FF on #2A1A55: 9.91:1 | #D9C8FF on #101411: 12.08:1 |
| unknown | light | #4A4A4A on #EFEFEF: 7.71:1 | #4A4A4A on #FBFDF8: 8.65:1 |
| unknown | dark | #D0D0D0 on #2E2E2E: 8.80:1 | #D0D0D0 on #101411: 12.05:1 |
| arrears | light | #7A1212 on #FFE1E0: 8.89:1 | #7A1212 on #FBFDF8: 10.67:1 |
| arrears | dark | #FFB4AE on #4A1010: 9.03:1 | #FFB4AE on #101411: 10.96:1 |

## Layouts

Breakpoints are written once in `lib/core/layout/breakpoints.dart` and come from the window width, not the device. Nothing asks "is this a tablet?".

| Window width | Class | Navigation | Stokvels |
| --- | --- | --- | --- |
| under 600 dp | compact | bottom bar, four labelled destinations | list, then the stokvel full screen |
| 600 to 839 dp | medium | side rail, same four branches and labels | list, then the stokvel full screen |
| 840 dp or wider | expanded | side rail | list and the selected stokvel side by side, on `/stokvels/:id` |

The selected stokvel is in the address, so turning a tablet upright (under 840 dp) keeps that stokvel full screen, and back returns to the list. Side by side, back also returns to the list, with "Select a stokvel" on the right.

Layout tests (`test/layout/layout_test.dart`) fail on overflow: Home, the stokvel list and stokvel detail at 360 by 640 dp with text at 200%, every action still reachable, and the list and detail side by side at 1280 by 800.

## Personas

Names follow the API's demo seed. Sipho plays the brief's "Lerato" (Treasurer of one stokvel, Member of another). Mpho plays the brief's "Sipho" (Member only). Platform admin is in no stokvels. Nomsa is Admin of Umoja, and Broken (dev) fails on purpose.

| Person | Home | Ubuntu Savings Circle | Umoja Family Fund | Payouts view |
Read from the API repo `AndiswaMbonambi08/RondiTrack` at commit `67a82a01f540f97ed481d0d01d1d6c201e0b7e6c`: its README and the generated types in `web/src/api/schema.d.ts`.
Contract copy: `contract/schema.d.ts` is the openapi-typescript output of the API's live OpenAPI document (`web/src/api/schema.d.ts`) at that commit. The committed `clients/typescript/openapi.json` export at that commit predates `arrearsCents`, so it is not the current contract; refreshing it is a backend follow-up.

1. **Spellings (case matters).** Contribution status is a real enum: `Pending`, `Paid`, `Confirmed`. Cycle status is a plain string, documented as `Open`, `Closed` (set by the cycle-close job) or `PaidOut`. Role is a plain string: `Member`, `Treasurer`, `Admin`. Any other string becomes `unknown`.
2. **Role.** `GET /api/v1/me/home` returns it per stokvel as `stokvels[].role`. It is never on the user or in the token (the token carries only `sub`, `jti` and, for platform admins, a `PlatformAdmin` role claim). The stokvel detail fake returns it on the stokvel the same way. Admin satisfies every Treasurer check.
3. **/me/home.** Per stokvel: `stokvelId`, `name`, `role`, `currentCycle` (`{id, label, status, dueDate}` or `null`), `paidCents`, `owedCents`, `arrearsCents` (int64 cents, never null) and `nextPayoutUtc` (date-time or `null`). The app shows them and never computes them. A user in no stokvels gets `200` with an empty list.
4. **Due dates.** `currentCycle.dueDate` is date-only (`2026-10-31`, nullable), modelled as a UTC-midnight `DateTime`. `nextPayoutUtc` is an instant (the last moment of the month in Johannesburg, `21:59:59Z`). Both are shown as a date in South African time (UTC+2, no daylight saving).
5. **Seed personas.** Sipho: Member of Ubuntu Savings Circle and Treasurer of Umoja Family Fund (one login, two roles). Nomsa: Admin of Umoja Family Fund. The platform admin (`admin@example.com`) stays out of stokvel membership, so it is the empty-Home persona. The fakes hold the same people and stokvels; contributors and amounts inside them are made-up fake data.

Backend gaps found: `role` and cycle `status` were published as plain `string` in the OpenAPI document, so the contract did not list their spellings. Fixed in the API repo with a contract test: https://github.com/AndiswaMbonambi08/RondiTrack/pull/20. The app still maps any unexpected string to `unknown`.

## Architecture rules

`test/architecture/architecture_test.dart` fails CI when:

- a file under `lib/features` types a colour (`Colors.`, `Color(`, `Color.from...`): ask the theme;
- a screen (a file in a `presentation/` folder, or under `lib/app`) imports a `data/` folder, Dio or Drift: go through a provider.

Every exception is a record in the test with the file, the reason and the week it ends; an exception with no reason, a missing file or a passed end week fails the test.

| File | Rule | Reason | Ends |
|---|---|---|---|
| none | | There are no exceptions today. | |

## Contract notes (11.1)

API commit read from: `6583344` (API repo, branch `feat/commit-openapi-v1`, file `openapi/v1.json`).

| # | Question | Answer |
|---|----------|--------|
| 1 | How a page ends | The schema declares `nextPageToken` as a string. Whether the last page sends null, "" or omits it is NOT yet confirmed against a running API. Only the first page is read today. |
| 2 | Stale write guard | Not declared in the spec (no `If-Match`, `ETag` or version on payouts). The close preview carries a `version` string and a stale close is a 409 with code `stale-preview` (API Assignment 9.1). |
| 3 | Status spellings | Cycle: `Open`, `Closed`, `PaidOut`. Contribution: `Pending`, `Paid`, `Confirmed`. Role: `Member`, `Treasurer`, `Admin`. Activity kind: `Contribution`, `Payout`, `MemberJoined`. Unknown strings become `unknown`. |
| 4 | Refresh cookie, token life | Not yet confirmed. The login response returns `accessToken` and `expiresInSeconds`. |
| 5 | correlationId on every error | Yes. `ProblemDetails` declares `correlationId`. |
| 6 | Non-member and wrong role | Not found for a stokvel the caller is not in. A Member on a treasurer action gets 403. Seed: Sipho is a Member in Ubuntu and the Treasurer in Umoja. Not yet re-confirmed on a running API. |
| 7 | Rate limits | `Retry-After` is not declared in the spec. The app reads the raw header. Not yet confirmed which endpoints are limited. |

Backend gap found: role and cycle status were plain strings in the OpenAPI document. Fixed in the API repo: https://github.com/AndiswaMbonambi08/RondiTrack/pull/20.

## Running against the API

1. Start Postgres and the API with `ASPNETCORE_URLS=http://0.0.0.0:5051`. The API migrates and seeds itself on startup.
2. Run the dev flavour with the seed password passed in, never committed:
   `flutter run --flavor dev --dart-define-from-file=config/dev.json --dart-define=SEED_PASSWORD=<password>`
3. The emulator reaches the laptop at `10.0.2.2`. Only Sipho, Nomsa and the admin have API accounts. Mpho and Broken exist only as fakes.
4. `config/dev.json` sets `USE_API` to true. Without it the app runs on the fakes, which is what the Week 10 tests use.

## The API client

The response types are hand-written (`data/*_dto.dart`) and stop in `data/`. Reason: the generator needs a toolchain and a drift step for only four endpoints, and the hand-written types are small and tested. swagger_parser stays pinned in `pubspec.yaml` for when the app grows. Drift check: CI compares `contract/openapi/v1.json` with the API repo's file, and can be pointed at an API branch. Because there is no generated client, there is no regenerate step.

## Failures

| API answer | Failure | The person sees |
|------------|---------|-----------------|
| 400 | ValidationFailure | The detail, or "Please check what you entered and try again." |
| 401 | UnauthorizedFailure | "Please sign in again." |
| 403 | ForbiddenFailure | The API's message. They stay signed in. |
| 404 | NotFoundFailure | Not found, never "no access" |
| 409, 412 | ConflictFailure | "This changed elsewhere. Refresh and try again." when stale |
| 422 | RuleFailure | The detail |
| 429 | RateLimitedFailure | "Try again in N seconds" from `Retry-After` |
| 5xx, unreadable body | ServerFailure | An apology and the copyable reference |
| No answer | NoAnswerFailure | "You're offline, or we couldn't reach the server" with Try again |

## Decisions

- Result: a sealed class (`Ok` and `Err`) with a `guard` helper. The API repositories currently throw the typed Failure and providers hold it in an AsyncError, which the screens read through `ViewFailure`.
- Models: hand-written, see The API client.
- Timeouts: connect 10 s, send 15 s, receive 30 s. These are NOT yet measured against the API with its database down. Measure before relying on them.
- Retry: only reads, and only for "no answer", three attempts. Every 4xx is final and writes are never retried. A 500 is not retried. Not yet measured.


## Contract notes › Offline, forms and lists (11.3)

API commit read: `49d043f` (API repo). Answers still to be filled from the API code and curl:

1. Idempotency-Key: required (a missing key is a 400) when recording a contribution (scoped to the caller and the stokvel) and when closing a cycle (scoped to the caller and the cycle). The same key and body returns the first response unchanged with `Idempotency-Replayed: true`. The same key with a different body returns 422. M is `Housekeeping:IdempotencyRetentionHours`, 168 hours (7 days) by default. The outbox keeps a payment at most 24 hours, shorter than M.
2. Refusals: 409 when the person is not a member or has already contributed for the cycle; 404 when the stokvel, user or cycle does not exist or the cycle belongs to another stokvel; 403 when a member records someone else's payment; 422 for a reused key with a different body; 400 for validation and a missing key. The words come from the problem detail. Paying is rate limited per user (token bucket): 429 with `Retry-After`, and a 429 never consumes the key. Cycle closed: TODO.
3. Which records can be edited and how a stale edit is refused (version + 409, or ETag + 412): TODO.
4. Contributions list: `GET /api/v1/stokvels/{id}/contribution-history` returns `{ items, nextPageToken }`; an empty `nextPageToken` means the end. Filters: `member`, `from`, `to`, `sort` (newest or oldest). `from` and `to` need a time (a date alone is a 400), so they are instants: the app sends the UTC bounds of a South African day. A page token only works with the same filters, so a filter change starts again with no token. `from` is inclusive and `to` is exclusive (half-open), exactly the South African day bounds; `to` must be later than `from`. Backend gap: there is no cycle or status filter on this list. Largest page size: TODO.
5. Record a contribution: `POST /api/v1/stokvels/{id}/contributions` with `{ userId, contributionCycleId, amountInCents }` (whole cents, 1 to 100 000 000). Field names in a 400's errors: TODO.
6. Personal data a phone must not keep in plain storage (proofs of payment, ID numbers, bank details): TODO. Nothing personal is cached yet.

## Money and dates (11.3)

A South African day is 00:00 SAST up to, but not including, 00:00 SAST the next day (SAST is UTC+2 all year). `lib/core/time/sast_day.dart` turns a day into those UTC bounds and an instant into its South African day. The phone's own time zone is never read. Test: `test/core/sast_day_test.dart` (the 00:30 SAST contribution is on 1 November).

## Offline, languages, decisions (11.3)

Status: in progress. Packages added and pinned: drift 2.35.3, drift_flutter 0.3.1, shared_preferences 2.5.6, uuid 4.6.0 (UUIDs from the uuid package), intl 0.20.3, drift_dev 2.35.2, flutter_localizations (SDK).
Lock-file check on 23 November found five packages under two weeks old: cli_util 0.6.1, jni 1.2.1, jni_flutter 1.1.0, material_ui 1.11.0, shared_preferences_android 2.5.5. They need `dependency_overrides` to their newest older versions, each with a date to remove it. Not done yet.
Not done yet: Drift cache and age banner, outbox with a stored idempotency key and maximum age, contributions list, ARB files and second language (reviewer to be named), accessibility checks, live tests, and the tests-seen-to-fail evidence.
Languages: English and Afrikaans, through ARB files and gen-l10n (`lib/l10n`). The Afrikaans is a machine-written draft and has NOT been reviewed by a first-language speaker yet. Reviewer and what they changed: TODO. The language choice is kept in SharedPreferences.
Outbox: a payment is stored in Drift with its Idempotency-Key at the tap; maximum age 24 hours, API key lifetime M 168 hours. Keys come from the uuid package (v4).
## Assignment 11.3 status (what is left)
Done: Drift database, outbox with a key made at the tap and stored with the payment, maximum age 24 h (API key lifetime M is 168 h), pay form with rands to cents and errors under the field, South African day bounds, two languages (English and Afrikaans), the five package overrides, and tests for the outbox and the day bounds.
Left: sign-out emptying the database and asking first when a payment is waiting; Drift cache for Home and the stokvel with the last-updated banner; contributions list with paging and the six states; refreshing the stokvel after a payment; the failing payouts "loading" test; Afrikaans review by a first-language speaker; live tests, screenshots, TalkBack and the CI time-zone runs.

## Test plan (12.1)

Rules that cost a member money or privacy if they break, and the test that proves each:

| # | Rule | Test |
|---|---|---|
| 1 | One refresh for many expired requests | TODO: session interceptor test with a scripted adapter |
| 2 | No signal never signs anyone out | TODO: session interceptor test |
| 3 | One tap makes one key | `test/payments/outbox_service_test.dart`: one tap makes one key |
| 4 | Every attempt sends the same key | `test/payments/outbox_service_test.dart`: the same key is sent on every attempt; `test/payments/outbox_server_test.dart`: a retry after no answer |
| 5 | The key survives a restart | `outbox_service_test.dart`: the key survives a restart; `outbox_server_test.dart`: killed mid-request (a temporary file, reopened) |
| 6 | The outbox maximum age is shorter than the API's M | `outbox_service_test.dart`: shorter than M; after the maximum age it is never sent again |
| 7 | Sign-out empties the outbox | `outbox_service_test.dart`: sign-out empties the outbox |
| 8 | A 429 waits for Retry-After with the same key | `outbox_server_test.dart`: a 429 keeps the key |
| 9 | A 409 leaves the outbox and says why | `outbox_server_test.dart`: a 409 leaves the outbox |
| 10 | A South African day is 00:00 to 00:00 SAST | `test/core/sast_day_test.dart`, `test/core/api_instant_test.dart` |
| 11 | Rands become cents without a double | `test/core/money_test.dart` |
| 12 | Nothing personal reaches Sentry | `test/privacy/scrubber_test.dart` |
| 13 | Analytics carry ids only | `test/privacy/analytics_test.dart` |

Outbox answers (question 2): success removes the payment; a repeat with the same key returns the stored answer and removes it; 409 (already paid or not a member), 404, 403, 422 and 400 remove it and show the reason; 429 keeps it and its key and waits for Retry-After; no answer, a failed sign-in and a 5xx keep it and its key.

Layers (question 3): unit and widget tests run in CI. Integration (emulator), live tests, TalkBack and timings on a real phone run on my laptop only.
Coverage (question 4): today's number and the floor are written by `dart run tool/check_coverage.dart --write-floor`; generated code and translations are left out. Number: TODO.
Journey (question 5): sign in, record a contribution, see it on the cycle, outbox empty afterwards. Status: TODO.
What the tests cannot see (question 9): a real TalkBack walk-through (done by hand), the real API (live tests), another platform (only Android is built), timings on a cheap phone (profile mode on a real phone).

## Privacy (12.1)

Everything that leaves the phone apart from the API calls:

| What | Where | Fields | Could it identify a member? |
|---|---|---|---|
| Error reports | Sentry (servers outside South Africa), only when a DSN is passed | Exception type and message, stack trace, breadcrumbs, environment (flavour), the API's correlation id as a tag, app id, version and build number, device model and OS version | Not after the scrubber: names, emails, amounts, tokens, proof file names and query strings are removed (`lib/core/privacy/scrubber.dart`); `sendDefaultPii` is false; the user is replaced by a constant |
| Sentry session data | Sentry, on launch | Session start and end, release, environment | No member data |
| Analytics events | Not sent anywhere yet; the interface only allows `stokvelId` and `memberId` | Event name, stokvel id, member id | An id could identify a member to someone who also has the API's data, so it is treated as personal |
| Logs | Stay on the phone (debug builds only, no tokens) | Request line without tokens | Not sent |

Failures worth a report (question 7): server failures (5xx) and failures nobody planned for. Not reported because they are the app working as designed: no signal, validation (400/422), not found, forbidden, rate limited, an already-paid refusal, a refused refresh. The API puts its correlation id in `ProblemDetails.correlationId`; it goes to Sentry as the tag `correlation_id`.
Reporting happens through one `ErrorReporter` (`lib/core/privacy/error_reporter.dart`); no screen reports on its own. Wiring every failure through it: TODO.

Android versions (question 8): `minSdk` was `flutter.minSdkVersion` (24); it is now 26 because Sentry 10 needs Android 8.0. Phones on Android 7.x can no longer install the app. I have not measured which versions my members use: TODO.

## Running the tests (12.1)

- Everything: `flutter test`
- Coverage: `flutter test --coverage` then `dart run tool/check_coverage.dart`
- Set the floor from today's number: `dart run tool/check_coverage.dart --write-floor`
- Date tests in both zones (Linux or macOS): `TZ=UTC flutter test` and `TZ=Africa/Johannesburg flutter test`
- Run with Sentry on: add `--dart-define=SENTRY_DSN=<your dsn>` after `--dart-define-from-file`