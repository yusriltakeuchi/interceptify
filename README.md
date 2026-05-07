# Interceptify 🔍

A production-grade Flutter DevTools-integrated network interceptor for Dio. Intercept, inspect, and modify HTTP requests/responses in real-time—all directly within Flutter DevTools, no external apps or proxy setup required.

Think Charles Proxy / Proxyman, but built into Flutter DevTools.

## Features ✨

- **Live Network Inspection** — Capture all HTTP requests/responses with full details (headers, body, query params, status codes, timing)
- **Request Pausing** — Pause requests before they're sent, inspect them in DevTools
- **Request Modification** — Edit headers, body, and query parameters on-the-fly before sending
- **Rule-Based Interception** — Create rules to automatically pause requests matching:
  - All requests
  - Specific URL substrings
  - HTTP methods (GET, POST, etc.)
  - GraphQL requests
- **DevTools Integration** — Built-in Flutter DevTools extension tab (auto-registered, no manual setup)
- **Debug-Only** — Automatically disabled in release builds; zero overhead in production
- **Auto-Resume** — Requests auto-resume after 30 seconds if DevTools is disconnected (failsafe)
- **Searchable Request List** — Filter captured requests by URL or method

## Getting Started 🚀

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  interceptify:
```

Then run:

```bash
flutter pub get
```

### Basic Setup

```dart
import 'package:dio/dio.dart';
import 'package:interceptify/interceptify.dart';

void main() {
  // Initialize Interceptify (debug mode only)
  Interceptify.initialize();

  // Create Dio instance
  final dio = Dio();

  // Add the interceptor
  dio.interceptors.add(Interceptify.dioInterceptor);

  runApp(MyApp());
}
```

### Usage in DevTools

1. Run your app in debug mode: `flutter run`
2. Open Flutter DevTools: `flutter devtools`
3. Navigate to the **Interceptify** tab
4. Trigger HTTP requests from your app
5. View captured requests in real-time
6. Click any request to inspect details
7. Add interception rules to pause specific requests

### Adding Interception Rules

```dart
import 'package:interceptify/src/rules/intercept_rule.dart';
import 'package:uuid/uuid.dart';

// Pause all requests
Interceptify.addRule(
  InterceptRule(
    id: const Uuid().v4(),
    condition: RuleCondition.always,
  ),
);

// Pause requests to URLs containing '/auth'
Interceptify.addRule(
  InterceptRule(
    id: const Uuid().v4(),
    condition: RuleCondition.urlContains,
    value: '/auth',
  ),
);

// Pause POST requests only
Interceptify.addRule(
  InterceptRule(
    id: const Uuid().v4(),
    condition: RuleCondition.methodEquals,
    value: 'POST',
  ),
);

// Pause GraphQL requests
Interceptify.addRule(
  InterceptRule(
    id: const Uuid().v4(),
    condition: RuleCondition.graphql,
  ),
);
```

### Managing Rules

```dart
// Get all rules
final rules = Interceptify.getRules();

// Remove a rule
Interceptify.removeRule(ruleId);

// Clear all rules
Interceptify.clearRules();

// Disable/enable interception
Interceptify.disableInterception();
Interceptify.enableInterception();

// Check pending requests
final pendingCount = Interceptify.getPendingRequestCount();
```

## Architecture 🏗️

```
┌─────────────────────────────────────────┐
│  Your Flutter App                       │
│  ┌───────────────────────────────────┐  │
│  │ Dio + InterceptifyDioInterceptor  │  │
│  └──────────────┬────────────────────┘  │
│                 │                       │
│  ┌──────────────▼────────────────────┐  │
│  │ DevtoolsBridge                    │  │
│  │ (VM Service Extensions)           │  │
│  └──────────────┬────────────────────┘  │
│                 │                       │
│                 │ (postEvent)           │
│                 │                       │
└─────────────────┼───────────────────────┘
                  │
                  │ (VM Service)
                  │
┌─────────────────▼───────────────────────┐
│  Flutter DevTools                       │
│  ┌───────────────────────────────────┐  │
│  │ Interceptify Extension Tab        │  │
│  │ ┌─────────────────────────────┐   │  │
│  │ │ Request List View           │   │  │
│  │ ├─────────────────────────────┤   │  │
│  │ │ Request Detail View         │   │  │
│  │ │ • Headers, Body, Query      │   │  │
│  │ │ • Response Details          │   │  │
│  │ │ • [Continue] [Cancel]       │   │  │
│  │ ├─────────────────────────────┤   │  │
│  │ │ Rule Editor View            │   │  │
│  │ └─────────────────────────────┘   │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

## How It Works 🔧

### Request Interception Flow

1. **Request Captured** — Dio interceptor's `onRequest()` captures the HTTP request
2. **Request Sent to DevTools** — Event posted via VM Service extension
3. **Rule Matching** — Check if any enabled rule matches the request
4. **Paused (Optional)** — If matched, request is paused using a `Completer`
5. **DevTools Display** — Request appears in DevTools UI
6. **User Action** — User clicks "Continue" or "Cancel" in DevTools
7. **Modifications Applied** — Any edits (headers, body, query params) are applied
8. **Request Sent** — Modified request is sent to the server
9. **Response Captured** — Response details are captured and sent to DevTools
10. **Auto-Timeout** — If DevTools doesn't respond within 30 seconds, request auto-resumes

### Debug-Only Behavior

Interceptify automatically disables itself in release builds:

- No VM Service extensions registered
- No interception overhead
- No code changes needed

```dart
// This is safe—automatically skipped in release builds
Interceptify.initialize();
```

### Request Timeout & Failsafe

If DevTools disconnects or becomes unresponsive:

- Paused requests auto-resume after **30 seconds**
- Request continues with original data (no modifications)
- App networking is never permanently blocked

This ensures your app continues functioning even if DevTools crashes.

## DevTools Extension Structure 📦

The DevTools extension is built into this package:

```
interceptify/
├── lib/
│   └── src/
│       ├── bridge/           # VM Service integration
│       ├── interceptor/      # Dio interceptor
│       ├── manager/          # Request state management
│       ├── models/           # Data models
│       ├── rules/            # Interception rules
│       └── utils/            # Helpers & constants
├── devtools/
│   ├── lib/
│   │   ├── main.dart         # Extension entry point
│   │   ├── ui/               # Flutter UI (list, detail, rules)
│   │   └── services/         # VM Service client & event listener
│   ├── extension_config.yaml # DevTools auto-registration
│   ├── pubspec.yaml
│   └── web/                  # Flutter web boilerplate
└── example/                  # Demo app
```

**No separate installation needed** — Everything is packaged together.

## Configuration 🎛️

### Initialize with Custom Debug Logging

```dart
Interceptify.initialize(debugLogging: true);
```

### Access Managers Directly

```dart
// For advanced use cases
final ruleManager = Interceptify.ruleManager;
final pendingRequestManager = Interceptify.pendingRequestManager;
final vmBridge = Interceptify.devtoolsBridge;
```

## Release Build Behavior 📤

In release mode:

- `Interceptify.initialize()` returns early (no-op)
- No VM extensions are registered
- No interception hooks are installed
- Zero runtime overhead
- Requests pass through Dio normally

## Error Handling 🛡️

Interceptify handles gracefully:

- Malformed JSON in request bodies → logged, request continues
- Disconnected DevTools → auto-resume after timeout
- Invalid modifications → logged, original request used
- Request cancellation from DevTools → request fails with appropriate error
- Network timeouts → logged as error event in DevTools

## Example App 📱

See [`example/`](./example/) for a complete demo app:

```bash
cd example
flutter run
```

The example app provides:

- Sample GET, POST, PUT, DELETE requests to httpbin.org
- Integration with Interceptify
- Response display
- DevTools integration walkthrough

## Limitations & Known Issues ⚠️

- **V1 Features Only** — This is an MVP. See [Roadmap](#roadmap) below for future features
- **Single Isolate** — Currently works with single-isolate apps. Multi-isolate support planned
- **Request Body Size** — No hard limit enforced yet; very large payloads may impact memory
- **Rules Persistence** — Rules reset on app restart (session memory only)
- **Mock Responses** — Not yet supported; planned for v2

## Roadmap 🗺️

**Phase 2 (Future)**

- [ ] Mock response injection
- [ ] Request replay functionality
- [ ] HAR file export
- [ ] GraphQL introspection & support
- [ ] WebSocket inspection
- [ ] Request scripting / automation
- [ ] AI-generated mock responses
- [ ] Rules persistence (saved to device storage)
- [ ] Multi-isolate support
- [ ] Performance profiling integration

**Phase 3**

- [ ] Response mocking rules
- [ ] Request composition/templating
- [ ] Integration with Charles / Proxyman formats
- [ ] Request/response comparison tools
- [ ] Performance timeline integration

## Contributing 🤝

Contributions are welcome! Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

## License 📄

MIT License — see [LICENSE](./LICENSE) file

## Support 💬

- **Issues** — Report bugs at [github.com/yourusername/interceptify/issues](https://github.com/yourusername/interceptify/issues)
- **Discussions** — Ask questions at [github.com/yourusername/interceptify/discussions](https://github.com/yourusername/interceptify/discussions)

---

Built with ❤️ for Flutter developers. Inspect like a pro! 🚀
