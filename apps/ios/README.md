# London Platforms (native iOS)

SwiftUI app implementing [docs/SERVICE_SPEC.md](../../docs/SERVICE_SPEC.md). Behaviour matches the legacy [apps/flutter-deprecated](../flutter-deprecated/) client (departures/arrivals list, time filter, station catalogue, service detail, about copy).

## Requirements

- **Xcode 26+** and **iOS 26** minimum deployment.
- RealTime Trains API credentials (HTTP Basic), supplied at build time — see below.

## Product / HIG notes

- **Adaptive navigation** — `NavigationSplitView` with board + detail on regular width (e.g. iPad); `NavigationStack` with push for compact width (iPhone).
- **String Catalog** — user-facing copy lives in [LondonPlatforms/Localizable.xcstrings](LondonPlatforms/Localizable.xcstrings); add locales there.
- **Privacy manifest** — [LondonPlatforms/PrivacyInfo.xcprivacy](LondonPlatforms/PrivacyInfo.xcprivacy) (no tracking; no collected-data types declared).
- **HIG audit checklist** — [HIG_CHECKLIST.md](HIG_CHECKLIST.md) (living checklist; App **icon** assets are still TODO separately).

## RealTime Trains credentials

Per the service spec, avoid shipping long-lived API keys in the binary when possible. For local development this project uses an optional **gitignored** xcconfig:

1. Copy `LocalSecrets.xcconfig.example` to `apps/ios/LocalSecrets.xcconfig`.
2. Set `RTT_BASIC_AUTH_HEADER` to the full `Authorization` header value (including the `Basic ` prefix), same shape as the Flutter app’s `Authorization` header.
3. `Base.xcconfig` includes `LocalSecrets.xcconfig` when present; the value is injected into `LondonPlatforms/Info.plist` as `RTTBasicAuthHeader`.

If credentials are missing, the app builds and runs but API requests surface a clear configuration error.

## Open and run

```bash
open /path/to/repo/apps/ios/LondonPlatforms.xcodeproj
```

Select the **LondonPlatforms** scheme and an **iOS 26** simulator or device, then Run.

## Command-line build

```bash
cd apps/ios
xcodebuild -scheme LondonPlatforms -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build
```

Adjust the simulator name to match your installed runtimes (`xcrun simctl list devices available`).

## Build and deploy to Will’s iPhone (primary device)

Use the device UDID as the destination, then install and launch with `devicectl`:

```bash
cd apps/ios
DEVICE_ID=00008110-000C093921D1401E
xcodebuild -scheme LondonPlatforms -destination "id=$DEVICE_ID" -configuration Debug -allowProvisioningUpdates build
APP="$HOME/Library/Developer/Xcode/DerivedData/LondonPlatforms-*/Build/Products/Debug-iphoneos/LondonPlatforms.app"
xcrun devicectl device install app --device "$DEVICE_ID" $APP
xcrun devicectl device process launch --device "$DEVICE_ID" com.platforms.LondonPlatforms
```

Resolve `LondonPlatforms-*` to your actual DerivedData folder if the glob matches more than one path.
