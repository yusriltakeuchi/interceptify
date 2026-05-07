## 0.0.1 - 2026-05-06

### Initial Release ✨

#### Features
- **Network Interception** — Capture all HTTP requests/responses with full details
- **Live DevTools Integration** — Built-in Flutter DevTools extension tab
- **Request Pause/Resume** — Pause requests, inspect in DevTools, continue with modifications
- **Header/Body/Query Mutation** — Edit request data before sending
- **Rule-Based Filtering** — Automatic pause rules:
  - Pause all requests
  - Pause specific URL substrings
  - Pause specific HTTP methods
  - Pause GraphQL requests
- **Auto DevTools Registration** — No manual setup required
- **Debug-Only Mode** — Automatically disabled in release builds
- **Failsafe Timeout** — Auto-resume after 30 seconds if DevTools disconnects
- **Request Searching** — Filter captured requests by URL or method
- **VM Service Extensions** — Full integration with Dart VM Service

#### Architecture
- Single package repository (no separate extension package)
- Dio `QueuedInterceptor` implementation
- Completer-based pause/resume mechanism
- Material 3 DevTools UI

#### Example App
- Demo application with GET, POST, PUT, DELETE endpoints
- httpbin.org integration
- DevTools UI walkthrough

#### Known Limitations
- MVP version (Phase 1)
- Single isolate support only
- Rules reset on app restart
- No mock response support yet

#### TODO Comments (Future Roadmap)
- Mock response injection
- WebSocket inspection
- HAR export
- GraphQL introspection
- Request replay
- AI-generated mocks
- Request scripting
- Multi-isolate support
- Rules persistence
