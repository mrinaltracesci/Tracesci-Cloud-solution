# TraceSci Mobile App

Flutter client for the TraceSci product authenticity and supply chain platform.
Built against the mobile API in the `tracescimaster` Laravel project.

## First run

The `lib/` tree, `pubspec.yaml` and `analysis_options.yaml` are complete. The
native Android and iOS folders still need to be generated:

```bash
cd tracesci_app
flutter create . --platforms=android,ios --org com.tracesci --project-name tracesci_app
flutter pub get
flutter run
```

`flutter create .` fills in the missing platform folders without touching `lib/`
or `pubspec.yaml`.

### Point the app at your backend

`lib/core/config/app_config.dart`

```dart
static Environment environment = Environment.local;
```

| Environment | URL |
|---|---|
| `local` | `http://192.168.2.118:8000/api` |
| `staging` | `https://staging.tracesci.in/api` |
| `production` | `https://tracesci.in/api` |

Update the local IP to your machine's LAN address. Self-signed certificates are
accepted in every environment except production.

### Android permissions

Add to `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

For plain-HTTP local development, add to the `<application>` tag:

```xml
android:usesCleartextTraffic="true"
```

### iOS permissions

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Used to scan product QR codes.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Used to record where a product was scanned.</string>
```

Set the iOS deployment target to 12.0 or higher in `ios/Podfile`.

## Architecture

```
lib/
  core/
    config/        environment and base URLs
    constants/     server icon key to IconData mapping
    models/        shared models (StatTile)
    navigation/    named routes and route generator
    network/       Dio client, response envelope, endpoints, pagination
    state/         LoadableNotifier base with loading/error/empty states
    storage/       token, profile, bootstrap and masters cache
    theme/         colours, typography, ThemeData
    utils/         json parsing, location, formatting, snackbars
    widgets/       buttons, cards, chips, stat tiles, timeline, paged list
  features/
    auth/          splash, phone OTP, password login, session provider
    shell/         bootstrap models and the role-driven bottom nav
    scanner/       camera scanner and overlay
    consumer/      home, scan history, scan detail, reports, notifications
    rewards/       wallet, catalog, ledger, orders
    supplychain/   dashboard, consignments, timeline, check-in/checkout
    inspector/     case queue, case detail, seizure
    brand/         KPI dashboard, products, scans, alerts, network
```

Each feature follows the same shape: `models/` → `data/` (repository) →
`providers/` (ChangeNotifier) → `screens/`.

## How the app decides what to show

After login the app calls `POST /app/bootstrap` once. The response drives
everything:

- `role` and `role_label` — who the user is
- `capabilities` — boolean feature map used to show or hide whole sections
- `tabs` — bottom navigation items, in order
- `quick_actions` — home screen buttons
- `scanner` — which scan mode to run and where to submit

No role logic is hard-coded in Dart. Adding a role server-side needs no app
release. The result is cached so cold starts render instantly, then refresh in
the background.

## Networking

`ApiClient` (Dio) attaches the session token three ways for compatibility with
the existing API: as an `Authorization: Bearer` header, an `X-Api-Token` header,
and a `token` field injected into the request body.

Every response is parsed into `ApiResponse` (`success` / `message` / `data`,
plus `meta` for paginated lists). Failures become a typed `ApiException` with a
`kind` (`network`, `timeout`, `unauthorized`, `validation`, `server`, ...). A
401 clears the session and bounces to login automatically.

## State

`LoadableNotifier` gives every provider `idle / loading / refreshing / success /
empty / error` plus `errorMessage`. Screens render skeletons, empty states and
error states from that single enum, so behaviour is consistent everywhere.

## Known follow-ups

- `rewards/redeem-cash` requires RazorpayX keys configured on the backend.
- Map screens currently return coordinate lists; a map widget is not wired up
  yet (`inspector/map` and `brand/scan-map` are ready server-side).
- Offline scan queueing is not implemented.
