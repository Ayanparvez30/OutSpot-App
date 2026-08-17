# AI Agent Guide for OutSpot

**Status:** Initial comprehensive analysis complete. Use [CLAUDE.md](CLAUDE.md) for architecture overview.

This guide captures patterns, gotchas, and architectural decisions discovered through codebase analysis. Agents should reference this first, then CLAUDE.md for details.

---

## Quick Start for Agents

1. **GetX is everything** — state, DI, routing. Learn [feature binding pattern](CLAUDE.md#architecture) immediately.
2. **Error handling is decentralized** — each API method handles its own 401/5xx responses (see [patterns](#error-handling--debugging)).
3. **Models parse defensively** — null coercion everywhere, no validation. Expect backend sometimes sends wrong types.
4. **Tab switching destroys controllers** — use `fenix: true` in bindings to auto-recreate (see [gotchas](#controller-lifecycle-gotchas)).
5. **Socket.IO requires explicit reconnection** — Ensure `userId` passed when switching chats.

---

## Error Handling & Debugging

### Logging Pattern
All errors use **emoji-prefixed `log()` from `dart:developer`**:
```dart
import 'dart:developer' show log;

log('❌ Server error: ${res.statusCode}');        // error
log('⚠️ Parse error: $e');                        // warning
log('ℹ️ Socket connected');                       // info
```

**Gotcha:** Project mixes `print()` (stdout) and `log()` (debugger). Standardize to `log()` for all non-UI messages.

### 401 Response Pattern
Centralized cleanup in [api_provider.dart](lib/Network_Manager/api_provider.dart#L20):
```dart
static void _handleUnauthorized(http.Response response) {
  if (response.statusCode == 401 && !_handlingSessionExpiry) {
    _handlingSessionExpiry = true;
    SettingController.cleanupAllSessionData().then((_) {
      Get.offAllNamed(Routes.loginScreen);
    });
  }
}
```
Clears user preferences, stops socket listener, navigates to login.

### Try-Catch Pattern
Wrap API calls in controllers, log parse errors with **raw data**:
```dart
try {
  final data = FriendsModel.fromJson(json);
  // use data
} catch (e) {
  log('⚠️ Parse error: $e | data=$raw');  // Include raw for debugging
  // Use fallback or notify UI
}
```

### Network Layer Debugging
- **Socket errors:** [socketService.dart](lib/Network_Manager/socketService.dart) — check connection state before emit
- **Multipart uploads:** [api_service.dart](lib/Network_Manager/api_service.dart#L63) — ensure Content-Type not overwritten
- **Base URL:** Hardcoded as `http://52.54.126.36:4000/api` — no env config

---

## State Management & GetX Patterns

### Feature Binding Pattern
Every screen follows this **exactly**:
```
lib/Views/FeatureName/
├── feature_screen.dart        # UI: extends GetView<Controller>
├── feature_controller.dart    # Logic: extends GetxController
└── feature_binding.dart       # DI: extends Bindings, uses Get.lazyPut
```

### Controller Lifecycle Gotchas

**Problem:** Tab switching (bottom nav) disposes controllers. Returning to tab doesn't recreate them → "Controller not found" crash.

**Solution:** Use `fenix: true` in binding:
```dart
// Ensures controller auto-recreates if disposed
Get.lazyPut(() => DirectmassagescreenController(), fenix: true);
```

**When to use:**
- ✅ Tab/bottom-nav controllers (Messages, Map, Camera, Challenges, Explore)
- ✅ Multi-tab flows with shared data
- ❌ Single-screen features (one-way navigation)

### Observable Patterns
```dart
// Primitive
var isLoading = false.obs;

// List
RxList<Item> items = RxList([]);

// Nullable
Rxn<Model> data = Rxn();  // null by default

// In UI
Obx(() => Text(controller.isLoading.value ? 'Loading...' : 'Done'))
```

---

## Data Models & JSON Parsing

### Defensive Parsing Pattern
All models use factory constructors with **null coercion**:
```dart
factory UserModel.fromJson(Map<String, dynamic> json) {
  return UserModel(
    id: json['id'] ?? 0,              // Coerce missing/null
    username: json['username'] ?? '',
    points: int.tryParse(json['points'].toString()) ?? 0,  // Type coercion
  );
}
```

### Gotchas
1. **No validation** — Parser assumes backend sends correct types. Will crash if backend sends string where int expected, unless using `tryParse`.
2. **Nested parsing** — Manually map lists:
   ```dart
   users: (json['users'] as List<dynamic>?)
       ?.map((e) => FriendsModel.fromJson(e))
       .toList() ?? [],
   ```
3. **Mutable fields** — Some models (e.g., [challenge_card_model.dart](lib/Model/challenge_card_model.dart)) have mutable properties. Risk: state inconsistency if UI modifies without syncing to backend.

### Best Practice
Always provide `.toJson()` for upload operations, test with malformed backend responses (null fields, wrong types).

---

## Socket.IO Real-Time Messaging

### Connection Pattern
[socketService.dart](lib/Network_Manager/socketService.dart) manages Socket.IO at `http://52.54.126.36:4000`:

```dart
final Socket socket = Socket.io(baseUrl, options);

void connectSocket(String userId) {
  socket.emit('userId', userId);  // MUST emit userId after connect
  socket.on('message', (data) => handleIncoming(data));
}

void onChatSwitch(String newChatId) {
  socket.disconnect();  // Explicit disconnect
  socket.connect();     // Reconnect with new userId
  socket.emit('userId', _getCurrentUserId());
}
```

### Gotchas
1. **UserId not persisted** — Must emit after every reconnect (switching chats, app resume).
2. **No auto-reconnect on network loss** — App goes silent until manual disconnect/connect.
3. **Foreground notification logic** — Checks if user already in chat before showing notification ([main.dart](lib/main.dart#L130)).

---

## Firebase & Notifications

### Setup
Project: `outspot-dfae2` (configured in [firebase_options.dart](lib/firebase_options.dart))

### FCM Foreground Handler Pattern
In [main.dart](lib/main.dart):
```dart
// Only show notification if user NOT already in this chat
FirebaseMessaging.onMessage.listen((message) {
  final data = message.data;
  if (GetPlatform.isWeb || GetPlatform.isAndroid) {
    // Android: Use local notifications
    showLocalNotification(message);
  }
  // iOS: System handles it
});
```

### Background Handler
Runs in isolate — can't access GetX context. Route navigation triggered by tapping notification via data payload routing.

---

## Testing

**Current State:** Minimal coverage
- Only [test/widget_test.dart](test/widget_test.dart) — basic counter smoke test
- No unit tests for models, controllers, or API calls
- No CI/CD pipeline detected

### How to Add Tests
1. **Unit tests** for models (JSON parsing defensive cases)
   ```bash
   flutter test test/model_test.dart
   ```
2. **Controller tests** (mock API responses, verify state changes)
3. **Widget tests** (UI components in CommonWidgets)

**Commands:**
```bash
flutter test                     # Run all
flutter test test/model_test.dart  # Single file
```

---

## Build & Environment

### Commands
See [CLAUDE.md](CLAUDE.md#common-commands) for build commands. Key ones:
```bash
fvm flutter pub get              # Dependencies (uses FVM for 3.32.0)
flutter analyze                  # Static analysis (suppresses invalid_use_of_protected_member)
flutter run -d <device_id>       # Run
```

### Environment Issues
1. **FVM Lock:** Flutter 3.32.0 in [.fvmrc](.fvmrc) — must use `fvm` prefix if FVM installed
2. **Hardcoded API URL:** `http://52.54.126.36:4000/api` in [api_constains.dart](lib/Network_Manager/api_constains.dart) — no env config
3. **Analysis Suppression:** `invalid_use_of_protected_member: ignore` in [analysis_options.yaml](analysis_options.yaml#L13) — allows GetX private member access

### Debugging Tips
- Check `crashlog.crash` if app crashes
- `devtools_options.yaml` configures DevTools connection
- `feedback.json` stores local debug feedback (ignore)

---

## Routing & Navigation

### 65 Named Routes
Defined in [lib/Utils/routes.dart](lib/Utils/routes.dart). Use GetX named routing:

```dart
// Simple navigation
Get.toNamed(Routes.profileScreen);

// With arguments
Get.toNamed(Routes.mainscreen, arguments: {'tab': 2});  // Go to Camera tab

// Replace (no back)
Get.offAllNamed(Routes.loginScreen);
```

### Tab Switching
Main screen tabs (0-4) accept `arguments: {'tab': index}` to jump to specific tab on load.

---

## UI & Responsive Design

### Responsive Sizing
Uses [flutter_screenutil](https://pub.dev/packages/flutter_screenutil) — design size **360×690**:
```dart
// In main.dart (already configured)
ScreenUtilInit(
  designSize: Size(360, 690),
  builder: () => MyApp(),
);

// In widgets
SizedBox(height: 10.h, width: 20.w)  // Responsive sizing
```

### Color Palette
[lib/Utils/colors.dart](lib/Utils/colors.dart) — Dark theme with purple gradients:
- Primary: `#7B51F3` (purple)
- Background: `#0F0114` (very dark purple)

### Custom Widgets
- **[CustomWidgets/](lib/CommonWidgets/CustomWidgets)** — `customLoading`, `textField`, `shimmer_placeholder`
- **[ExploreWidgets/](lib/CommonWidgets/ExploreWidgets)** — Category-specific explore components
- **[MapWidgets/](lib/CommonWidgets/MapWidgets)** — Google Maps integration helpers

---

## Recommended Next Steps for Agents

When you encounter issues or need to add features:

1. ✅ **Check [CLAUDE.md](CLAUDE.md) first** for project overview and architecture
2. ✅ **Refer to this guide** for patterns, gotchas, and debugging tips
3. ✅ **Search existing code** in `lib/Views/*/` for similar implementations
4. ⚠️ **Add defensive parsing** to all new models (null coercion, type safety)
5. ⚠️ **Use `fenix: true`** for tab-based controllers
6. ⚠️ **Log with emoji prefixes** for consistency
7. 🧪 **Add unit tests** when implementing new controllers or models (currently missing)

---

## Links to Key Files

| File | Purpose |
|------|---------|
| [CLAUDE.md](CLAUDE.md) | Architecture & project overview |
| [lib/main.dart](lib/main.dart) | GetX setup, Firebase, responsive config |
| [lib/Utils/routes.dart](lib/Utils/routes.dart) | 65 named routes |
| [lib/Network_Manager/api_service.dart](lib/Network_Manager/api_service.dart) | ~70 API endpoints (~1800 lines) |
| [lib/Network_Manager/api_provider.dart](lib/Network_Manager/api_provider.dart) | HTTP wrapper, 401 handling |
| [lib/Network_Manager/socketService.dart](lib/Network_Manager/socketService.dart) | Socket.IO real-time messaging |
| [lib/CommonWidgets/](lib/CommonWidgets/) | Reusable UI components |
| [analysis_options.yaml](analysis_options.yaml) | Lint rules |

---

**Last Updated:** May 25, 2026 | **Analysis:** Subagent-driven codebase exploration
