## 0.0.1+2

*Released: 2026-05-09*

**Bug Fixes**
- Fixed query parameter duplication when continuing a paused request.
- Fixed a bug where interception rules disappeared from the DevTools UI after navigating to a different tab. 
- Fixed `FormData` serialization so multipart requests are now properly readable as JSON in the DevTools panel.

**Improvements**
- Improved text selectability across the DevTools UI (URLs, headers, and query parameters can now be highlighted and copied).
- URLs are now properly decoded for better readability in the request list and detail view.
- Added a "Supported HTTP Clients" table to the README, detailing planned support for `graphql_flutter`, `chopper`, and `grpc`.

## 0.0.1

*Released: 2026-05-09*

Initial public release of Interceptify.

### Core Library

**Multi-client network interception**
- `InterceptifyDioInterceptor` — `QueuedInterceptor` implementation for Dio; captures requests, responses, and errors
- `InterceptifyHttpClient` — `BaseClient` wrapper for `package:http`; drop-in replacement for `http.Client()`

**Request lifecycle tracking**
- Unique request ID assigned to every intercepted request
- Start-time and duration measurement for response timing
- `clientType` field (`'dio'` | `'http'`) attached to every event for client-level differentiation

**Pause / Resume / Cancel**
- Pause any request or response using the Rules Engine or global toggle
- Completer-based async mechanism ensures the request is held until DevTools sends a continue or cancel signal
- Configurable timeout (default 30 s) auto-resumes the request if DevTools disconnects

**Rules Engine**
- Add, remove, and clear intercept rules programmatically or via DevTools UI
- Rule conditions: `urlContains`, `urlEquals`, `urlStartsWith`, `methodEquals`
- Global toggles: pause all requests, pause all responses, disable all interception

**DevTools Bridge**
- Full integration with Dart VM Service via `dart:developer` extension registration
- Registered extensions: `getPendingRequests`, `continueRequest`, `cancelRequest`, `addRule`, `removeRule`, `clearRules`, `toggleInterception`, `getInterceptionStatus`, `togglePauseAll`, `togglePauseAllResponses`, `continueResponse`, `retryRequest`, `getTimeout`, `setTimeout`
- Events streamed to DevTools: `requestEvent`, `responseEvent`, `errorEvent`

**Safety**
- All interception is guarded by `kDebugMode`; zero overhead in release builds
- No network calls, logging, or side-effects in production

---

### DevTools Extension

**Request List — Advanced Filters**
- Full-text search by URL and HTTP method (literal or regex mode)
- Regex mode with real-time invalid-pattern indicator
- Method chip filter (GET / POST / PUT / PATCH / DELETE), multi-select
- Status code family filter: Any / 2xx / 3xx / 4xx / 5xx
- Duration filter: Any / < 100ms / 100–500ms / > 500ms
- "Failed only" toggle (status ≥ 400 or error)
- Active filter chips displayed below the panel with individual dismiss buttons

**Smart Auto Grouping (Charles Proxy-style)**
- Default mode: flat list
- Switchable to grouped mode via **List / Grouped** toggle in the summary bar
- Five grouping strategies available from a dropdown:
  - By Domain (hostname)
  - By Path Prefix (first URL path segment)
  - By Method (HTTP method)
  - By HTTP Client (Dio / HTTP)
  - By Status Code family
- Group headers show request count badge and red error count badge

**Request Detail View**
- Headers tab: editable request headers, read-only response headers
- Body tab: editable request body with JSON syntax view
- Response tab: response body, status code, duration
- Interactive JSON viewer with node-level expand/collapse and copy
- Copy as cURL button
- Continue / Cancel actions for paused requests
- Retry button to re-send a captured request

**Summary Bar**
- Live counts: total requests, pending (paused), errors
- Clear All button

---

### Example App

- Hub home screen with navigation to example clients
- **Dio example** — GET, POST, PUT, DELETE against jsonplaceholder.typicode.com
- **HTTP example** (`package:http`) — GET, POST, PUT, DELETE, and a 404 error scenario
