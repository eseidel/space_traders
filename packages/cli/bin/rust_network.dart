import 'dart:async';

import 'package:cli/api.dart';
import 'package:http/http.dart';
import 'package:postgres/postgres.dart';

class QueuedRequest {
  const QueuedRequest({
    required this.id,
    required this.priority,
    required this.method,
    required this.url,
    required this.body,
  });

  factory QueuedRequest.empty(String url, int priority) {
    return QueuedRequest(
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

class NetQueue {
  final PostgreSQLConnection _connection = PostgreSQLConnection(
    'localhost',
    5432,
    'spacetraders',
    username: 'postgres',
    password: 'password',
  );

  bool _connected = false;

  Future<void> _connect() async {
    if (_connected) {
      return;
    }
    await _connection.open();
    await _connection.execute('LISTEN response_');
    _connected = true;
  }

  Future<void> disconnect() async {
    if (!_connected) {
      return;
    }
    await _connection.close();
    _connected = false;
  }

  /// Inserts a request into the database, notifying listeners that a new
  /// request is available and returning the id of the request.
  Future<int> _queueRequest(
    QueuedRequest request,
  ) async {
    await _connect();
    final result = await _connection.query(
      'INSERT INTO request_ (priority, method, url, body) '
      'VALUES (@priority, @method, @url, @body) RETURNING id',
      substitutionValues: {
        'priority': request.priority,
        'method': request.method,
        'url': request.url,
        'body': request.body,
      },
    );
    await _connection.execute('NOTIFY request_');
    return result[0][0] as int;
  }

  /// Waits for a response to be available for the given request id, returning
  /// the response.
  Future<Response> _waitForResponse(
    int requestId,
  ) async {
    await _connect();
    final _ = await _connection.notifications.firstWhere(
      (notification) => notification.channel == 'response_',
    );
    // TODO(eseidel): This does not yet handle queuing multiple requests
    // and waiting on all of them.
    final result = await _connection.query(
      'SELECT status_code, body FROM response_ WHERE request_id = @requestId',
      substitutionValues: {
        'requestId': requestId,
      },
    );
    return Response(
      result[0][1] as String,
      result[0][0] as int,
    );
  }

  Future<Response> sendAndWait(QueuedRequest request) async {
    final requestId = await _queueRequest(request);
    return _waitForResponse(requestId);
  }
}

class DatabaseApiClient extends ApiClient {
  /// Construct a rate limited api client.
  DatabaseApiClient({super.authentication}) : _queue = NetQueue();

  final NetQueue _queue;

  @override
  Future<Response> invokeAPI(
    String path,
    String method,
    List<QueryParam> queryParams,
    Object? body,
    Map<String, String> headerParams,
    Map<String, String> formParams,
    String? contentType,
  ) async {
    final urlEncodedQueryParams = queryParams.map((param) => '$param');
    final queryString = urlEncodedQueryParams.isNotEmpty
        ? '?${urlEncodedQueryParams.join('&')}'
        : '';

    final request = QueuedRequest(
      id: 0,
      priority: 0,
      method: method,
      url: '$path$queryString',
      body: body.toString(),
    );
    final response = await _queue.sendAndWait(request);
    return response;
  }
}

void main() async {
  final queue = NetQueue();

  final requests = [
    QueuedRequest.empty('https://api.spacetraders.io/v2/my/3', 3),
    QueuedRequest.empty('https://api.spacetraders.io/v2/my/2', 2),
    QueuedRequest.empty('https://api.spacetraders.io/v2/my/1', 1),
    QueuedRequest.empty('https://api.spacetraders.io/v2/my/3', 3),
    QueuedRequest.empty('https://api.spacetraders.io/v2/my/2', 2),
    QueuedRequest.empty('https://api.spacetraders.io/v2/my/1', 1),
  ];

  // We don't yet have support for waiting on multiple requests, so sending
  // one at a time.
  for (final request in requests) {
    final response = await queue.sendAndWait(request);
    print('Got response: ${response.statusCode} ${response.body}');
  }

  await queue.disconnect();
  print('Done!');
}
