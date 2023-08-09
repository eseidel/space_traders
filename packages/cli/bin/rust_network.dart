import 'package:postgres/postgres.dart';

// class DatabaseApiClient extends ApiClient {
//   /// Construct a rate limited api client.
//   DatabaseApiClient({super.authentication}) {
//     _connection = PostgreSQLConnection(
//       'localhost',
//       5432,
//       'dart_ci',
//       username: 'dart_ci',
//       password: 'dart_ci',
//     );
//   }

//   PostgreSQLConnection _connection;

//   @override
//   Future<Response> invokeAPI(
//     String path,
//     String method,
//     List<QueryParam> queryParams,
//     Object? body,
//     Map<String, String> headerParams,
//     Map<String, String> formParams,
//     String? contentType,
//   ) async {
//     final urlEncodedQueryParams = queryParams.map((param) => '$param');
//     final queryString = urlEncodedQueryParams.isNotEmpty
//         ? '?${urlEncodedQueryParams.join('&')}'
//         : '';

//     return response;
//   }
// }

class Request {
  const Request({
    required this.id,
    required this.priority,
    required this.method,
    required this.url,
    required this.body,
  });

  factory Request.empty(String url, int priority) {
    return Request(
      id: 0,
      priority: priority,
      method: 'GET',
      url: url,
      body: '',
    );
  }

  final int id;
  final int priority;
  final String method;
  final String url;
  final String body;
}

/// Inserts a request into the database, notifying listeners that a new request
/// is available and returning the id of the request.
Future<int> queueRequest(
  PostgreSQLConnection connection,
  Request request,
) async {
  final result = await connection.query(
    'INSERT INTO request_ (priority, method, url, body) '
    'VALUES (@priority, @method, @url, @body) RETURNING id',
    substitutionValues: {
      'priority': request.priority,
      'method': request.method,
      'url': request.url,
      'body': request.body,
    },
  );
  await connection.execute('NOTIFY request_');
  return result[0][0] as int;
}

void main() async {
  final connection = PostgreSQLConnection(
    'localhost',
    5432,
    'spacetraders',
    username: 'postgres',
    password: 'password',
  );
  await connection.open();

  final requests = [
    Request.empty('https://api.spacetraders.io/v2/my/3', 3),
    Request.empty('https://api.spacetraders.io/v2/my/2', 2),
    Request.empty('https://api.spacetraders.io/v2/my/1', 1),
    Request.empty('https://api.spacetraders.io/v2/my/3', 3),
    Request.empty('https://api.spacetraders.io/v2/my/2', 2),
    Request.empty('https://api.spacetraders.io/v2/my/1', 1),
  ];

  for (final request in requests) {
    await queueRequest(connection, request);
  }

  print('Added ${requests.length} requests to the database');

  await connection.close();
}
