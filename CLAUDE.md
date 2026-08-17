# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Companion doc:** [AGENTS.md](AGENTS.md) holds patterns, gotchas, and debugging tips from deep codebase analysis (controller lifecycle, defensive JSON parsing, socket reconnect rules, 401 handling, emoji logging). Read it alongside this file before non-trivial work.

## Project Overview

OutSpot is a Flutter mobile app — a social, location-based platform with features for exploration, challenges, messaging, communities, and gamification. Targets Android, iOS, Web, macOS, and Windows.

- **Flutter version:** 3.32.4 (managed via FVM — see `.fvmrc`)
- **Dart SDK:** ^3.7.2
- **Package name:** `outspot` (version 1.0.0+10)

## Common Commands

```bash
# Dependencies
flutter pub get

# Run on device/emulator
flutter run -d <device_id>

# Static analysis
flutter analyze

# Tests
flutter test                    # all tests
flutter test test/widget_test.dart  # single test file

# Build
flutter build apk              # Android
flutter build ios               # iOS
flutter build web               # Web

# Clean rebuild
flutter clean && flutter pub get
```

If using FVM: prefix commands with `fvm` (e.g., `fvm flutter pub get`).

## Architecture

### State Management & Routing: GetX

The entire app uses **GetX** (`get: ^4.7.2`) for state management, dependency injection, and routing.

**Feature structure pattern** — each screen follows this convention:
```
Views/FeatureName/
├── feature_screen.dart        # UI widget (extends GetView<Controller>)
├── feature_controller.dart    # Business logic (extends GetxController)
└── feature_binding.dart       # DI setup (extends Bindings, uses Get.lazyPut with fenix: true)
```

**Observable pattern:**
```dart
var isLoading = false.obs;           // primitive
RxList<Item> items = RxList([]);     // list
Rxn<Model> data = Rxn();            // nullable
```

**Routing:** 65 named routes defined in `lib/Utils/routes.dart`. Navigation uses `Get.toNamed(Routes.routeName)` with optional `arguments` map.

### Main Screen (5 Tabs)

`lib/Views/Mainscreen/` — bottom navigation with tabs:
- 0: Messages
- 1: Map (Google Maps)
- 2: Camera
- 3: Challenges
- 4: Explore

Tab switching via arguments: `Get.offAllNamed(Routes.mainscreen, arguments: {"tab": 2})`

### Networking Layer (`lib/Network_Manager/`)

| File | Purpose |
|---|---|
| `api_service.dart` | Static API methods (~70+ endpoints, ~2200 lines) |
| `api_provider.dart` | HTTP wrapper around `dart:http` |
| `api_constains.dart` | Endpoint path constants |
| `user_preference.dart` | SharedPreferences wrapper (token, profile cache, search history) |
| `socketService.dart` | Socket.IO client for real-time messaging |
| `notification_badge_service.dart` | Unread/badge count tracking |
| `video_cache_service.dart` | Video caching layer |

- **Host (single source of truth):** `ApiConstants.host` = `https://api-app.outspot.app` in `api_constains.dart`
- **Base URL:** `$host/api` (`https://api-app.outspot.app/api`)
- **Socket URL:** `$host` (no `/api` prefix; https upgrades to wss via websocket transport)
- **Auth:** Bearer token in `Authorization` header

### Data Models (`lib/Model/`)

36 model files using factory constructors with defensive JSON parsing (null checks, type coercion via `int.tryParse`, fallback defaults). No validation — parsers assume backend may send wrong types, so always coerce. See [AGENTS.md](AGENTS.md) for the parsing pattern.

### Firebase Integration

- **Project:** `outspot-dfae2`
- **Services used:** Firebase Auth, Cloud Messaging (FCM), configured in `firebase_options.dart`
- **FCM setup:** Background handler, foreground listener, notification-based routing — all in `main.dart`

### UI Conventions

- **Responsive sizing:** `flutter_screenutil` with design size 360×690 (configured in `main.dart`)
- **Color palette:** `lib/Utils/colors.dart` — dark theme with purple (#7B51F3) to dark purple (#0F0114) gradients
- **Typography:** Google Fonts
- **Assets:** `assets/Images/` directory

### Key Directories

- `lib/Views/` — all screens (43 feature directories)
- `lib/Model/` — data models
- `lib/Network_Manager/` — API, socket, and local storage services
- `lib/CommonWidgets/` — shared UI components (custom widgets, explore widgets, map widgets)
- `lib/Utils/` — routes and colors

## Conventions

- **Commit style:** Conventional commits (`feat:`, `fix:`, `refactor:`)
- **File naming:** snake_case for files, PascalCase for classes
- **Logging:** Uses `dart:developer` `log()` function
- **Error handling:** try-catch with log output in controllers and API methods; emoji-prefixed `log()` (❌ error, ⚠️ warning, ℹ️ info). 401s handled centrally in `api_provider.dart` (clears session, navigates to login)
- **Controller lifecycle:** use `fenix: true` in bindings for tab/bottom-nav controllers — tab switch disposes them, fenix auto-recreates on return
- **Analysis:** `analysis_options.yaml` extends `flutter_lints/flutter.yaml`; `invalid_use_of_protected_member` is suppressed (allows GetX private member access). Note: `flutter_lints` is currently **commented out** in `pubspec.yaml` dev_dependencies and absent from `pubspec.lock`, so `flutter analyze` may warn that the included lint package is missing — uncomment it in pubspec if the analyzer complains.
