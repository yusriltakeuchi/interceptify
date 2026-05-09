import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../bridge/devtools_bridge.dart';
import '../models/intercepted_request.dart';
import '../utils/logging.dart';

/// A GraphQL Link that intercepts all GraphQL operations and posts
/// them to the Interceptify DevTools bridge.
///
/// This class uses duck-typing / abstract interface to avoid a hard compile-time
/// dependency on `gql_exec` / `graphql_flutter` in the core package.
/// Users who want GraphQL interception import
/// `package:interceptify/src/interceptor/interceptify_graphql_link.dart`
/// **after** adding `graphql_flutter` to their own pubspec.
///
/// **Usage with graphql_flutter:**
/// ```dart
/// import 'package:graphql_flutter/graphql_flutter.dart';
/// import 'package:interceptify/interceptify.dart';
/// import 'package:interceptify/src/interceptor/interceptify_graphql_link.dart';
///
/// final httpLink = HttpLink('https://api.example.com/graphql');
/// final interceptLink = InterceptifyGraphQLLink(next: httpLink);
///
/// final client = GraphQLClient(
///   link: interceptLink,
///   cache: GraphQLCache(),
/// );
/// ```
///
/// Because `graphql_flutter` is NOT a dependency of this package, this class
/// provides a standalone implementation that mirrors the `Link` interface.
/// If your project uses `graphql_flutter`, you can pass an `HttpLink` (or any
/// other Link) as `next`.
///
/// The class exposes [request] which matches the `Link` contract from gql_exec,
/// so it is drop-in compatible:
/// ```dart
/// class InterceptifyGraphQLLink extends Link { ... } // same signature
/// ```
///
/// In practice this file IS used by importing graphql_flutter alongside it.
/// The bridge integration is done via [Interceptify.devtoolsBridge].

// ---------------------------------------------------------------------------
// Minimal interface — mirrors gql_exec types so we don't need a hard dep.
// Users must have graphql_flutter/gql_exec themselves.
// ---------------------------------------------------------------------------

/// Typedef for the `forward` function passed by the Link chain.
typedef GraphQLForward = Stream<dynamic> Function(dynamic request);

/// Minimal representation of what we extract from a GraphQL request object.
class _GQLRequestInfo {
  final String? operationName;
  final String? documentText;
  final Map<String, dynamic>? variables;
  final String operationType; // 'query' | 'mutation' | 'subscription'

  _GQLRequestInfo({
    this.operationName,
    this.documentText,
    this.variables,
    required this.operationType,
  });
}

/// Intercepts GraphQL operations and sends them to the Interceptify DevTools
/// panel. Wire it into your Link chain before your [HttpLink]:
///
/// ```dart
/// final link = InterceptifyGraphQLLink(next: HttpLink('https://...'));
/// ```
class InterceptifyGraphQLLink {
  final dynamic next; // Any Link — kept dynamic to avoid hard dep
  final DevtoolsBridge _bridge;
  final String _endpoint;

  InterceptifyGraphQLLink({
    required this.next,
    required DevtoolsBridge bridge,
    String endpoint = 'GraphQL',
  }) : _bridge = bridge,
       _endpoint = endpoint;

  /// Entry-point called by the gql_exec Link chain. Matches `Link.request`.
  Stream<dynamic> request(dynamic gqlRequest, [GraphQLForward? forward]) {
    if (!kDebugMode) {
      return _forwardRequest(gqlRequest, forward);
    }

    const uuid = Uuid();
    final requestId = uuid.v4();
    final startTime = DateTime.now();

    final info = _extractInfo(gqlRequest);

    final intercepted = InterceptedRequest(
      id: requestId,
      method: 'GRAPHQL',
      url: _endpoint,
      headers: const {},
      queryParameters: const {},
      body: {
        'operationName': info.operationName,
        'query': info.documentText,
        'variables': info.variables,
        'type': info.operationType,
      },
      timestamp: startTime,
      clientType: 'graphql',
    );

    _bridge.postRequestEvent(intercepted);
    InterceptifyLogger.info(
      'GraphQL ${info.operationType}: ${info.operationName ?? '(anonymous)'} [$requestId]',
    );

    final resultStream = _forwardRequest(gqlRequest, forward);

    return resultStream.map((result) {
      final duration = DateTime.now().difference(startTime);

      // Attempt to read statusCode from result if available
      int? statusCode;
      dynamic body;
      try {
        // graphql_flutter's QueryResult has `.data` and `.exception`
        final hasException =
            (result as dynamic).hasException as bool? ?? false;
        body = hasException
            ? {'errors': result.exception?.toString()}
            : result.data;
        statusCode = hasException ? 200 : 200;
      } catch (_) {
        body = result;
        statusCode = 200;
      }

      _bridge.postResponseEvent(requestId, statusCode, body, null, duration);
      InterceptifyLogger.info(
        'GraphQL response: $requestId - ${duration.inMilliseconds}ms',
      );
      return result;
    }).handleError((e, st) {
      final duration = DateTime.now().difference(startTime);
      _bridge.postErrorEvent(requestId, e.toString(), e.runtimeType.toString());
      InterceptifyLogger.error('GraphQL error: $requestId', e);
      _bridge.postResponseEvent(requestId, null, null, null, duration);
      // Re-throw so the caller still gets the error
      throw e; // ignore: only_throw_errors
    });
  }

  Stream<dynamic> _forwardRequest(
    dynamic gqlRequest,
    GraphQLForward? forward,
  ) {
    try {
      // If a forward function is provided (Link chain style)
      if (forward != null) {
        return forward(gqlRequest);
      }
      // Otherwise, call `next.request(gqlRequest)` directly
      if (next != null) {
        return (next as dynamic).request(gqlRequest) as Stream<dynamic>;
      }
    } catch (e) {
      InterceptifyLogger.error('GraphQL forward error', e);
    }
    return const Stream.empty();
  }

  /// Extract operation info from a gql_exec `Request` object via duck typing.
  _GQLRequestInfo _extractInfo(dynamic gqlRequest) {
    String? operationName;
    String? documentText;
    Map<String, dynamic>? variables;
    String operationType = 'query';

    try {
      operationName = gqlRequest.operation?.operationName as String?;
      variables =
          (gqlRequest.variables as Map<String, dynamic>?) ?? const {};
    } catch (_) {}

    try {
      final doc = gqlRequest.operation?.document;
      if (doc != null) {
        documentText = jsonEncode(doc);
        // Try to guess type from definition list
        final defs = doc.definitions as List<dynamic>?;
        if (defs != null) {
          for (final def in defs) {
            final typeStr = def.runtimeType.toString().toLowerCase();
            if (typeStr.contains('mutation')) {
              operationType = 'mutation';
              break;
            } else if (typeStr.contains('subscription')) {
              operationType = 'subscription';
              break;
            }
          }
        }
      }
    } catch (_) {}

    return _GQLRequestInfo(
      operationName: operationName,
      documentText: documentText,
      variables: variables,
      operationType: operationType,
    );
  }
}
