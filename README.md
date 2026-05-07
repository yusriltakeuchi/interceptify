# Interceptify

Interceptify is a powerful Flutter DevTools extension that gives you total control over your application's network layer. It allows you to **intercept, inspect, and modify** network requests and responses in real-time, directly from your Flutter DevTools suite.

Built specifically for the [Dio](https://pub.dev/packages/dio) package, Interceptify bridges the gap between your running app and your development environment, making it an essential tool for debugging complex API flows, testing edge cases, and simulating server responses.

---

## 🚀 Features

### Real-Time Network Control
*   **Live Interception**: Capture all outgoing requests and incoming responses as they happen.
*   **On-the-Fly Modification**: Edit URLs, Headers, Query Parameters, and Bodies before they reach their destination.
*   **Response Mocking**: Change status codes and response bodies to test how your app handles different server states.

### Intelligent Rules Engine
*   **Conditional Pausing**: Create rules based on URL patterns (contains, equals, starts with) or HTTP methods.
*   **Granular Control**: Focus only on specific API endpoints while letting others pass through.
*   **GraphQL Support**: Built-in logic to easily identify and target GraphQL transactions.

### Premium Developer Experience
*   **Interactive JSON Viewer**: Navigate deep and complex JSON structures with node-level expand/collapse.
*   **Global Toggles**: One-click to pause all requests or responses, or disable interception entirely.
*   **Request Retry**: Instantly retry any captured request with its original or modified data.
*   **Dynamic Timeouts**: Configure how long requests should wait for your input before auto-resuming.

---

## 📦 Installation

Add `interceptify` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  interceptify: ^latest_version
```

Then run:
```bash
flutter pub get
```

---

## 🛠️ Getting Started

### 1. Initialize the Bridge
Initialize Interceptify at the start of your application to establish the communication bridge with DevTools.

```dart
import 'package:interceptify/interceptify.dart';

void main() async {
  // Initialize the bridge
  final interceptify = await Interceptify.initialize();
  
  runApp(MyApp(interceptify: interceptify));
}
```

### 2. Configure Dio
Add the Interceptify interceptor to your Dio instance. To enable the **Retry** feature, make sure to register the Dio instance as well.

```dart
final dio = Dio();

// Add the interceptor
dio.interceptors.add(interceptify.interceptor);

// Register the instance (required for Retry functionality)
interceptify.registerDioInstance(dio);
```

---

## 📖 How to Use

1.  **Launch Your App**: Run your app in **Debug Mode**.
2.  **Open DevTools**: Open Flutter DevTools in your browser or IDE.
3.  **Find Interceptify**: Look for the **Interceptify** tab (represented by a **Shield** icon).
4.  **Manage Rules**: 
    *   Navigate to the **Rules** tab.
    *   Choose a specific rule.
    *   Create the rule that you want to pause.
5.  **Intercept & Modify**:
    *   When a matching request is made, it will appear as **PENDING** in the list.
    *   Select the request, modify its details in the **Request** or **Response** tabs.
    *   Click **Continue** at the bottom to let the transaction proceed.

---

## 💡 Pro Tips

*   **Quick Debugging**: Use the **Pause All Requests** or **Pause All Responses** toggles in the Rules tab to stop all traffic instantly without creating specific rules.
*   **Avoiding Hangs**: If you are in a long debugging session, increase the **Interception Timeout** in **Rules > Settings** to prevent the app from auto-resuming too early.
*   **JSON Shortcuts**: Use the arrow icons in the JSON viewer to collapse large objects/arrays and focus on relevant data.

---

## 🤝 Support & Contribution

Interceptify is an open-source project. If you encounter bugs, have feature requests, or want to contribute, please visit our GitHub repository.

**License**: MIT
