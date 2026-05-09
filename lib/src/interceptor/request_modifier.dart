import 'package:dio/dio.dart';

/// Utility for applying modifications to intercepted requests
class RequestModifier {
  RequestModifier._(); // Private constructor to prevent instantiation

  /// Apply header modifications to request options
  static void applyHeaderModifications(
    RequestOptions options,
    Map<String, dynamic> headerModifications,
  ) {
    for (final entry in headerModifications.entries) {
      options.headers[entry.key] = entry.value;
    }
  }

  /// Apply body modification to request options
  static void applyBodyModification(RequestOptions options, dynamic newBody) {
    options.data = newBody;
  }

  /// Apply query parameter modifications to request options
  static void applyQueryParamModifications(
    RequestOptions options,
    Map<String, dynamic> queryParamModifications,
  ) {
    final currentParams = options.queryParameters;
    currentParams.addAll(queryParamModifications);
    options.queryParameters = currentParams;
  }

  /// Apply all modifications from a modification map
  /// Expected structure:
  /// {
  ///   'headers': {'Header-Name': 'value', ...},
  ///   'body': {...},
  ///   'queryParameters': {'param': 'value', ...},
  ///   'url': '...',
  ///   'method': '...'
  /// }
  static void applyAllModifications(
    RequestOptions options,
    Map<String, dynamic> modifications,
  ) {
    // 1. Headers
    if (modifications.containsKey('headers')) {
      final headers = modifications['headers'];
      if (headers is Map<String, dynamic>) {
        applyHeaderModifications(options, headers);
      }
    }

    // 2. Body
    if (modifications.containsKey('body')) {
      final body = modifications['body'];
      applyBodyModification(options, body);
    }

    // 3. URL & Query Parameters
    // We handle these together to prevent duplication if params are in both
    String? modifiedUrl = modifications['url'] as String?;
    Map<String, dynamic>? modifiedQueryParams =
        modifications['queryParameters'] as Map<String, dynamic>?;

    if (modifiedUrl != null && modifiedUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(modifiedUrl);
        if (uri.hasQuery) {
          // If the URL string has query parameters, move them to the map
          // and keep only the base URL in options.path
          options.path = uri.replace(query: null).toString();

          // Merge: queryParameters from the table take precedence over the URL string
          final urlParams = uri.queryParameters;
          modifiedQueryParams = {...urlParams, ...?modifiedQueryParams};
        } else {
          options.path = modifiedUrl;
        }
      } catch (_) {
        // If URL is invalid, fall back to setting it directly
        options.path = modifiedUrl;
      }
    }

    if (modifiedQueryParams != null) {
      // Use replace instead of addAll to avoid duplication with original options.queryParameters
      replaceQueryParameters(options, modifiedQueryParams);
    }

    // 4. Method
    if (modifications.containsKey('method')) {
      final method = modifications['method'];
      if (method is String && method.isNotEmpty) {
        options.method = method;
      }
    }
  }

  /// Remove a header from request options
  static void removeHeader(RequestOptions options, String headerName) {
    options.headers.remove(headerName);
  }

  /// Remove query parameters from request options
  static void removeQueryParameter(
    RequestOptions options,
    String parameterName,
  ) {
    options.queryParameters.remove(parameterName);
  }

  /// Replace all headers with provided headers
  static void replaceHeaders(
    RequestOptions options,
    Map<String, dynamic> newHeaders,
  ) {
    options.headers.clear();
    options.headers.addAll(newHeaders);
  }

  /// Replace all query parameters with provided parameters
  static void replaceQueryParameters(
    RequestOptions options,
    Map<String, dynamic> newQueryParameters,
  ) {
    // Clear existing and add new ones
    options.queryParameters.clear();
    options.queryParameters.addAll(newQueryParameters);
  }
}
