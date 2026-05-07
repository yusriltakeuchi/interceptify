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
  static void applyBodyModification(
    RequestOptions options,
    dynamic newBody,
  ) {
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
  ///   'queryParameters': {'param': 'value', ...}
  /// }
  static void applyAllModifications(
    RequestOptions options,
    Map<String, dynamic> modifications,
  ) {
    if (modifications.containsKey('headers')) {
      final headers = modifications['headers'];
      if (headers is Map<String, dynamic>) {
        applyHeaderModifications(options, headers);
      }
    }

    if (modifications.containsKey('body')) {
      final body = modifications['body'];
      applyBodyModification(options, body);
    }

    if (modifications.containsKey('queryParameters')) {
      final queryParams = modifications['queryParameters'];
      if (queryParams is Map<String, dynamic>) {
        applyQueryParamModifications(options, queryParams);
      }
    }

    if (modifications.containsKey('url')) {
      final url = modifications['url'];
      if (url is String && url.isNotEmpty) {
        options.path = url;
      }
    }

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
