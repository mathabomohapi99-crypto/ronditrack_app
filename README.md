> STATUS: Parts 1-6 code complete, 17 tests passing (money, config refusals, domain, actions, family provider, frame test, Home states). Not done: green CI with strict-lint cleanup (dart analyze --fatal-infos still reports doc/line-length infos), red-CI proof PR, emulator screenshots, screen recording, 3-flavour launcher screenshot, contract copy, README FILL/VERIFY placeholders.

# RondiTrack Mobile (Assignment 10.1)

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
