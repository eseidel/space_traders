import 'dart:async';

import 'package:http/http.dart';
import 'package:postgres/postgres.dart';

/// Request queued for later execution.
class QueuedRequest {
  /// Creates a new [QueuedRequest].
  const QueuedRequest({
    required this.id,
    required this.priority,
    required this.method,
    required this.url,
    required this.body,
  });

  /// Creates an empty [QueuedRequest] with the given [url] and [priority].
  factory QueuedRequest.empty(String url, int priority) {
    return QueuedRequest(
      id: 0,
      priority: priority,
      method: 'GET',
      url: url,
      body: '',
    );
  }

  /// id of the request in the database, or 0 if not yet inserted.
  final int id;

  /// Priority of the request, higher numbers are executed first.
  final int priority;

  /// HTTP method of the request.
  final String method;

  /// URL of the request.
  final String url;

  /// Body of the request.
  final String body;
}

/// A queue of requests to be sent to the server.
/// Must be disconnected when no longer needed or main may not exit.
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

  /// Disconnects from the database.
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

  /// Sends the given request and waits for a response.
  Future<Response> sendAndWait(QueuedRequest request) async {
    final requestId = await _queueRequest(request);
    return _waitForResponse(requestId);
  }
}
