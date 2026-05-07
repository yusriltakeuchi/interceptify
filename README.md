# Interceptify

Interceptify is a Flutter DevTools extension designed to help developers intercept, inspect, and modify network requests and responses in real-time. It works as an interceptor for the Dio package, bridging the gap between your running application and the Flutter DevTools suite.

## Features

- **Real-time Interception**: Capture all outgoing requests and incoming responses from your Dio instances.
- **Dynamic Rules**: Create rules to automatically pause requests based on URL patterns or HTTP methods.
- **Interactive Inspection**: View request and response details, including headers, query parameters, and bodies.
- **On-the-fly Modification**: Edit request URLs, headers, and bodies before they are sent. Modify response status codes and bodies before they reach your app's logic.
- **Interactive JSON Viewer**: Easily navigate complex JSON structures with node-level expand and collapse functionality.
- **Global Controls**: Toggle interception globally or enable "Pause All" modes for quick debugging.
- **Request Retry**: Trigger a retry of any captured request directly from the DevTools UI.
- **Configurable Timeouts**: Set a custom timeout for paused requests to ensure your app doesn't hang indefinitely if you forget to take action.

## Installation

Add Interceptify to your project's dependencies:

```yaml
dependencies:
  interceptify: ^latest_version
```

## Setup

To start using Interceptify, you need to initialize the bridge and add the interceptor to your Dio instance.

```dart
import 'package:interceptify/interceptify.dart';
import 'package:dio/dio.dart';

void main() async {
  // 1. Initialize Interceptify (usually at the start of your app)
  final interceptify = await Interceptify.initialize();

  final dio = Dio();

  // 2. Register your Dio instance (required for Retry functionality)
  interceptify.registerDioInstance(dio);

  // 3. Add the interceptor to Dio
  dio.interceptors.add(interceptify.interceptor);

  runApp(MyApp());
}
```

## How to Use

1. Run your Flutter application in debug mode.
2. Open **Flutter DevTools** in your browser or IDE.
3. Look for the **Interceptify** tab (it might be under the "More Actions" menu or marked with a Shield icon).
4. In the Interceptify tab:
   - Go to the **Rules** menu to enable interception.
   - Add rules to specify which requests you want to pause.
   - When a request is paused, it will appear in the list with a "PENDING" status.
   - Select the request to view details and use the **Edit** or **Continue** buttons at the bottom to manage the transaction.

## Additional Tips

- **Retry Support**: To use the "Retry" button in the Detail View, ensure you have called `interceptify.registerDioInstance(dio)` during initialization.
- **JSON Navigation**: For large JSON bodies, click the arrow icon next to objects or arrays to collapse them and focus on the data you need.
- **Timeout Management**: If you are working on long debugging sessions, go to the **Rules > Settings** section to increase the "Interception Timeout". This prevents the app from auto-resuming before you've finished your modifications.
- **GraphQL Support**: You can create rules specifically for GraphQL by selecting the "GraphQL Only" condition, which looks for typical GraphQL endpoints.

## License

MIT
