# Interceptify Example App

A simple Flutter example demonstrating the Interceptify network interceptor library.

## About

This example app shows how to:
- Initialize Interceptify in your Flutter app
- Add the Interceptify Dio interceptor
- Make HTTP requests to a public API (JSONPlaceholder)
- View all network requests in real-time using the Flutter DevTools Interceptify extension

## Prerequisites

- Flutter SDK (3.9.2 or higher)
- A physical device or emulator to run the app
- Internet connectivity (to reach JSONPlaceholder API)

## Getting Started

### 1. Install Dependencies

From the example directory:

```bash
cd example
flutter pub get
```

### 2. Run the App

```bash
flutter run
```

Choose your target device when prompted (iOS, Android, Web, etc.).

### 3. View Network Requests in DevTools

While the app is running, open Flutter DevTools:

```bash
flutter devtools
```

Navigate to the **Interceptify** tab to see all captured network requests in real-time.

## How It Works

This example provides a simple UI with buttons to trigger different types of API calls to JSONPlaceholder:

### GET Requests
- **Fetch All Posts** — Get a list of blog posts
- **Fetch Single Post** — Get a single post by ID
- **Fetch All Users** — Get user profile data
- **Fetch Comments** — Get comments for a specific post

### Modify Requests (POST/PUT/DELETE)
- **Create New Post** — Creates a new post via POST request
- **Update Post** — Updates an existing post via PUT request
- **Delete Post** — Deletes a post via DELETE request

## Viewing Requests in Interceptify

1. Tap any button to make an API call
2. Open Flutter DevTools and navigate to the **Interceptify** tab
3. You'll see:
   - Full request details (method, URL, status code)
   - Request headers and body
   - Response headers and data
   - Request/response timing information

## Project Structure

```
lib/
├── main.dart                 # App entry point, Interceptify initialization
├── services/
│   └── api_service.dart      # Dio wrapper for JSONPlaceholder API calls
├── models/
│   ├── post.dart             # Post data model
│   ├── user.dart             # User data model
│   └── comment.dart          # Comment data model
└── screens/
    └── home_screen.dart      # Main UI with API call buttons
```

## Dependencies

- **dio** (^5.4.0) — HTTP client library
- **interceptify** (local path) — Network interceptor library
- **flutter** — UI framework
- **cupertino_icons** — iOS style icons

## API Used

This example uses the free [JSONPlaceholder](https://jsonplaceholder.typicode.com/) API:
- `/posts` — Blog post data
- `/users` — User profile data
- `/comments` — Comment data
- Full CRUD support (GET, POST, PUT, DELETE)

No authentication required!

## Tips

- Results are displayed in dialogs
- Each API call shows status in the info bar (✓ success, ✗ error)
- Requests are automatically captured in DevTools (debug mode only)
- Production builds have zero overhead (debug-only initialization)

## Troubleshooting

**DevTools not showing network requests?**
- Ensure Interceptify was initialized before the Dio instance
- Check that the Interceptify interceptor was added to Dio
- Confirm the app is running in debug mode (DevTools doesn't work in release)

**Getting connection errors?**
- Ensure your device/emulator has internet connectivity
- Check firewall settings if behind a corporate network
- JSONPlaceholder should be accessible from most networks

**App crashes on startup?**
- Run `flutter clean` and `flutter pub get` again
- Make sure the interceptify package in the parent directory is building correctly

## Testing the Example

The example includes a simple widget test. Run tests with:

```bash
flutter test
```

## Next Steps

After testing the basic example, try:
1. **Adding interception rules** — Pause specific requests based on conditions
2. **Modifying requests** — Edit headers and body before sending
3. **Creating a custom API service** — Adapt the example for your own API
4. **Building production apps** — Use Interceptify during development for debugging

See the main Interceptify documentation for advanced features and examples.
