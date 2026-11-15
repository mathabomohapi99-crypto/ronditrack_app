
# RondiTrack Mobile

## Contract notes
API commit read: d6daa2562b18de11da3a355cc6378c02f513b2b3 (copy of the contract in `contract/`).
1. Spellings (case included): CycleStatus Open/Closed/PaidOut; ContributionStatus Pending/Paid/Confirmed; StokvelRole Member/Treasurer. <VERIFY against Domain/*.cs>
2. Role comes from `GET /api/me/stokvels` (`myRole` per stokvel) and `GET /api/stokvels/{id}` (`myRole`), never from the token or user. <VERIFY>
3. `GET /api/me/stokvels` returns paid and owed this cycle and next payout date per stokvel; the app never computes totals. Arrears: <FILL from HomeDtos.cs>. Nullable: <FILL>.
4. Due dates: <FILL date-only or instant; check ContributionCycleDtos.cs>
5. Seed personas: Thandi (Treasurer of Ubuntu Savers, Member of Festive Grocery Club, in arrears R250,00), Sipho (Member of Ubuntu Savers), Bongani (in no stokvels).
Backend PRs: <link or "none needed">

## Running it
Flutter 3.47.7. API: `dotnet run --project API --launch-profile http` (port 5134) from the API repo (Week 11 uses it).
- dev: `flutter run --flavor dev --dart-define-from-file=config/dev.json`
- staging: `flutter run --flavor staging --dart-define-from-file=config/staging.json`
- prod: `flutter run --flavor prod --dart-define-from-file=config/prod.json`
Each config file holds FLAVOR and API_BASE_URL only (no secrets). iOS flavours not done (needs Xcode/macOS).

## Generated code
Not committed (gitignored); CI runs build_runner before analyze/test. Reason: no merge conflicts in generated files, and CI proves the code generates from scratch.

## Money
Cents is an extension type over int; formatter and parser use integer maths only. Parser accepts 150, 150,50, R150, R 1 500, 1 500,50 (space or U+00A0). Refuses 1,500.50, 150,505, 150., empty, letters. Full-stop decision: a single "." is a decimal separator (phones without a comma) only with 1-2 digits after it; "1.500" is refused as ambiguous.

## When the API adds a status
<PASTE exactly what `dart analyze` prints after you add e.g. `archived` to CycleStatus>. On an old install, the new string maps to `unknown` (fromWire), shows "Unknown status", and the actions match treats it as "no actions", so nothing crashes.

## Provider lifetimes
| Provider | Holds | Lifetime | Why / cost |
|---|---|---|---|
| currentPersona | demo identity | keepAlive | Must outlive screens; tiny. Cleared on sign-out. |
| homeRepository / stokvelRepository | repository object | keepAlive | Cheap, stateless; disposing = rebuild for nothing. |
| home | list of home cards | autoDispose | Refetch + spinner when reopened, but no stale money on a shared phone. |
| stokvelDetail(id) | one stokvel + contributions | autoDispose | Holds the most data; disposing frees memory/data on cheap phones; cost is a refetch. |
Sign-out (Week 11): invalidate every keepAlive provider (`ref.invalidate(...)`) or recreate the root ProviderContainer on sign-out, so the next person on a shared phone sees nothing of the previous one.
Disposal evidence: <screenshot of Run console "stokvelDetail disposed id=...">.



## Routes
| Address | Screen and tab | Signed out | Not a member | Back goes to |
|---|---|---|---|---|
| `/` | Home (Home tab) | sign-in, then Home | n/a | leaves the app |
| `/stokvels` | Stokvel list (Stokvels tab); list + detail pane at 840 dp+ | sign-in, then here | n/a | leaves the app |
| `/stokvels/:id` | Stokvel detail (Stokvels tab); side by side at 840 dp+ | sign-in, then here | "Not found" | `/stokvels` (also from a cold start) |
| `/stokvels/:id/cycles/:cycleId` | Cycle (Stokvels tab) | sign-in, then here | "Not found" (also when the cycle belongs to another stokvel) | `/stokvels/:id` |
| `/join/:code` | Invite preview (under Home) | sign-in, then the invite | n/a (preview only) | `/` |
| `/activity` | Activity feed (Activity tab) | sign-in, then here | n/a | leaves the app |
| `/profile` | Profile + sign out (Profile tab) | sign-in, then here | n/a | leaves the app |
| `/sign-in` | Fake sign-in by email | stays | n/a | leaves the app; signed in goes to the remembered address or `/` |
| anything else | "Not found" | sign-in | "Not found" | leaves the app |

Tapping the tab you are already on returns to that tab's first screen (decision: it matches what most apps do and gives a way back to the list).

## The gate
One pure function, `redirectFor(user, uri)` in `lib/app/redirect.dart`, decides every navigation. Signed out: anything except `/sign-in` goes to `/sign-in?from=<address>`. Signed in: `/sign-in` goes to `from`, or to `/` if there is none. Only addresses inside the app (`/`, `/stokvels...`, `/join/...`, `/activity`, `/profile`) are remembered; `https://...`, `//host` and unknown paths are dropped and the person lands on Home. `GoRouter.refreshListenable` is pinged whenever the Riverpod auth state changes, so signing in or out re-runs the redirect without a tap. Signing out also invalidates every provider that held the last person's data.

## Deep links
Scheme choice: custom scheme per flavour (`ronditrack-dev`, `ronditrack-staging`, `ronditrack`) with host `app`. Reason: free, needs no domain, and each flavour has its own scheme so a dev link reaches only the dev build. Force-stop first to test a cold start. Ids: Ubuntu Savers `20000000-0000-0000-0000-000000000001`.
dev (application id za.co.mathabo.ronditrack.dev)

adb shell am force-stop za.co.mathabo.ronditrack.dev
adb shell am start -a android.intent.action.VIEW -d "ronditrack-dev://app/stokvels/20000000-0000-0000-0000-000000000001" za.co.mathabo.ronditrack.dev
adb shell am start -a android.intent.action.VIEW -d "ronditrack-dev://app/stokvels/20000000-0000-0000-0000-000000000001/cycles/ubuntu-cycle-3" za.co.mathabo.ronditrack.dev
adb shell am start -a android.intent.action.VIEW -d "ronditrack-dev://app/join/ABC123" za.co.mathabo.ronditrack.dev

staging: replace ronditrack-dev with ronditrack-staging and the package with za.co.mathabo.ronditrack.staging
prod: replace ronditrack-dev with ronditrack and the package with za.co.mathabo.ronditrack
What an App Link would add: an `https` link on a domain I own, a `/.well-known/assetlinks.json` file on it listing each flavour's package and signing fingerprint, and `android:autoVerify="true"` on the intent filter, so Android opens the app without a chooser and a link tapped in a messaging app works. An adb test only proves the app handles the address and the router builds the right screen; it does not prove domain verification, and it bypasses the system's link-verification check.

## Theme
Seed colour `#0B6E4F`, Material 3, light and dark (follows the phone). Status tokens live in a theme extension (`StatusColors`), each with a light and a dark pair. Contrast measured with a script (WCAG 2.x relative luminance) over the values in `status_colors.dart`; text needs 4.5:1.

<!-- TOKENS:START -->
Checked with the WCAG 2.x relative-luminance formula (script over status_colors.dart). Text needs 4.5:1.

| Token | Theme | Text | Background | Contrast |
|---|---|---|---|---|
| pending | light | #3E2723 | #FFE082 | 10.69:1 |
| paid | light | #0D47A1 | #BBDEFB | 6.15:1 |
| confirmed | light | #1B5E20 | #C8E6C9 | 5.85:1 |
| unknown | light | #212121 | #E0E0E0 | 12.2:1 |
| open | light | #004D40 | #B2DFDB | 6.78:1 |
| closed | light | #3E2723 | #D7CCC8 | 8.79:1 |
| paidOut | light | #4A148C | #E1BEE7 | 7.19:1 |
| arrears | light | #9B1C1C | #FFCDD2 | 5.79:1 |
| pending | dark | #FFE082 | #5D4037 | 7.2:1 |
| paid | dark | #90CAF9 | #1A3A5C | 6.65:1 |
| confirmed | dark | #A5D6A7 | #1B3D1F | 7.37:1 |
| unknown | dark | #E0E0E0 | #3A3A3A | 8.62:1 |
| open | dark | #80CBC4 | #0F3D38 | 6.45:1 |
| closed | dark | #D7CCC8 | #3E2F2B | 8.12:1 |
| paidOut | dark | #CE93D8 | #3B1F5C | 5.72:1 |
| arrears | dark | #FFB4A9 | #5C1A1A | 7.64:1 |
<!-- TOKENS:END -->


## Layouts
Breakpoints (written once in `lib/core/breakpoints.dart`, taken from the window width): compact < 600 dp, medium 600 to 839 dp, expanded 840 dp or wider. Compact: bottom navigation bar, stokvel detail on its own screen. Medium: side navigation rail, detail on its own screen. Expanded: side rail, and `/stokvels/:id` shows the list and the detail side by side; back returns to the list.