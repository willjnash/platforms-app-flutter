# London Platforms

Monorepo for **London Platforms** train departure and platform information clients. Shared behaviour and API contracts are defined in [docs/SERVICE_SPEC.md](docs/SERVICE_SPEC.md).

## Apps

| Path | Description |
|------|-------------|
| [apps/flutter-deprecated/](apps/flutter-deprecated/) | Legacy **Flutter** app (deprecated). Run Flutter commands from this directory. |
| [apps/ios/](apps/ios/) | Native **iOS** app (SwiftUI). Add the Xcode project here when implemented. |
| [apps/android/](apps/android/) | Native **Android** app (placeholder for a future Kotlin implementation). |

## Documentation

- [docs/SERVICE_SPEC.md](docs/SERVICE_SPEC.md) — language-agnostic product and RealTime Trains integration spec.

## Repository layout

```
docs/                      # Shared specifications
apps/
  flutter-deprecated/      # pubspec.yaml, lib/, test/, Flutter android/ & ios/
  ios/                     # Native iOS (SwiftUI)
  android/                 # Native Android (future)
```

Renaming the remote repository (for example away from `platforms-app-flutter`) is optional; update your `git remote` after the host rename.
