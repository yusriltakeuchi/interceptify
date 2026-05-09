import 'package:gql_exec/gql_exec.dart';
import 'package:gql_link/gql_link.dart';
import 'package:interceptify/interceptify.dart';

/// Adapter yang membungkus [InterceptifyGraphQLLink] menjadi [Link] standard
/// sehingga bisa digunakan langsung dalam [GraphQLClient].
///
/// Diperlukan karena core package Interceptify tidak memiliki dependency pada
/// `gql_exec`/`gql_link` agar tetap ringan dan tidak memaksa pengguna
/// menginstall graphql_flutter.
///
/// Penggunaan:
/// ```dart
/// final httpLink = HttpLink('https://api.example.com/graphql');
/// final interceptLink = InterceptifyLinkAdapter(
///   interceptifyLink: Interceptify.graphqlLink(
///     next: httpLink,
///     endpoint: 'https://api.example.com/graphql',
///   ),
/// );
/// final client = GraphQLClient(link: interceptLink, cache: GraphQLCache());
/// ```
class InterceptifyLinkAdapter extends Link {
  final InterceptifyGraphQLLink interceptifyLink;

  InterceptifyLinkAdapter({required this.interceptifyLink});

  @override
  Stream<Response> request(Request request, [NextLink? forward]) {
    return interceptifyLink
        .request(request, forward != null ? (r) => forward(r as Request) : null)
        .cast<Response>();
  }
}
