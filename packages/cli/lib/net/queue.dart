import 'dart:async';
import 'dart:convert';

import 'package:cli/logger.dart';
import 'package:http/http.dart';
import 'package:postgres/postgres.dart';

/// Connect to the default local database.
/// Logs and returns null on failure.
Future<PostgreSQLConnection?> defaultDatabase() async {
  final connection = PostgreSQLConnection(
    'localhost',
    5432,
    'spacetraders',
    username: 'postgres',
    password: 'password',
  );
  try {
    await connection.open();
  } on PostgreSQLException catch (e) {
    logger.err('Failed to connect to database: $e');
    return null;
  }
  return connection;
}

/// An http Client implementation which sends requests to another process
/// through a postgres queue.
class QueuedClient extends BaseClient {
  /// Creates a new [QueuedClient].
  QueuedClient(PostgreSQLConnection connection, [this.getPriority])
      : _connection = connection,
        _queue = NetQueue(connection, QueueRole.requestor);

  /// Callback to get the priority of the next request.
  int Function()? getPriority;

  final PostgreSQLConnection _connection;
  final NetQueue _queue;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final stream = request.finalize();
    final body = await stream.toBytes();

    final queuedRequest = QueuedRequest(
      method: request.method,
      url: request.url.toString(),
      body: String.fromCharCodes(body),
      headers: request.headers,
    );
    final priority = getPriority?.call() ?? 0;
    final response = await _queue.sendAndWait(priority, queuedRequest);
    return StreamedResponse(
      Stream.fromIterable([response.bodyBytes]),
      response.statusCode,
      contentLength: response.bodyBytes.length,
      request: request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() {
    _connection.close();
  }
}

/// Request queued for later execution.
class RequestRecord {
  /// Creates a new [RequestRecord].
  const RequestRecord({
    required this.id,
    required this.priority,
    required this.request,
  });

  /// id of the request in the database, or 0 if not yet inserted.
  final int id;

  /// Priority of the request
  final int priority;

  /// The queued request
  final QueuedRequest request;
}

/// Request queued for later execution.
class QueuedRequest {
  /// Creates a new [QueuedRequest].
  const QueuedRequest({
    required this.method,
    required this.url,
    required this.body,
    required this.headers,
  });

  /// Creates an empty [QueuedRequest] with the given [url].
  factory QueuedRequest.empty(String url) {
    return QueuedRequest(
      method: 'GET',
      url: url,
      body: '',
      headers: {},
    );
  }

  /// Creates a [QueuedRequest] from json.
  factory QueuedRequest.fromJson(Map<String, dynamic> json) {
    return QueuedRequest(
      method: json['method'] as String,
      url: json['url'] as String,
      body: json['body'] as String,
      headers: (json['headers'] as Map<String, dynamic>).cast(),
    );
  }

  /// Converts this to json.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'method': method,
      'url': url,
      'body': body,
      'headers': headers,
    };
  }

  /// HTTP method of the request.
  final String method;

  /// URL of the request.
  final String url;

  /// Body of the request.
  final String body;

  /// Headers of the request.
  final Map<String, String> headers;
}

/// Response record in the database.
class ResponseRecord {
  /// Creates a new [ResponseRecord].
  ResponseRecord({
    required this.id,
    required this.requestId,
    required this.response,
  });

  /// id of the request in the database, or 0 if not yet inserted.
  final int id;

  /// request this is responding too
  final int requestId;

  /// The queued response
  final QueuedResponse response;
}

/// Response queued for later execution.
class QueuedResponse {
  /// Creates a new [QueuedResponse].
  QueuedResponse({
    required this.body,
    required this.statusCode,
    required this.headers,
  });

  /// Creates a [QueuedResponse] from json.
  factory QueuedResponse.fromJson(Map<String, dynamic> json) {
    return QueuedResponse(
      body: json['body'] as String,
      statusCode: json['statusCode'] as int,
      headers: (json['headers'] as Map<String, dynamic>).cast(),
    );
  }

  /// Creates a [QueuedResponse] from a [Response].
  QueuedResponse.fromResponse(Response response)
      : this(
          body: response.body,
          statusCode: response.statusCode,
          headers: response.headers,
        );

  /// Body of the response.
  final String body;

  /// Status code of the response.
  final int statusCode;

  /// Headers of the response.
  final Map<String, String> headers;

  /// Converts this to a [Response].
  Response toResponse() => Response(body, statusCode, headers: headers);

  /// Converts this to json.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'body': body,
      'statusCode': statusCode,
      'headers': headers,
    };
  }
}

/// Role of the user of this queue.
enum QueueRole {
  /// The sender sends requests to the queue.
  requestor,

  /// The receiver responds to requests in the queue.
  responder,
}

/// A queue of requests to be sent to the server.
/// Must be disconnected when no longer needed or main may not exit.
// TODO(eseidel): This could be a generic "prioritized database queue"?
class NetQueue {
  /// Creates a new [NetQueue].
  NetQueue(PostgreSQLConnection connection, this.role)
      : _connection = connection;

  final PostgreSQLConnection _connection;

  /// Role of the user of this queue.
  final QueueRole role;

  bool _listening = false;

  Future<void> _listenIfNeeded() async {
    if (_listening) {
      return;
    }
    if (role == QueueRole.requestor) {
      await _connection.execute('LISTEN response_');
    } else {
      await _connection.execute('LISTEN request_');
    }
    _listening = true;
  }

  /// Inserts a request into the database, notifying listeners that a new
  /// request is available and returning the id of the request.
  Future<int> _queueRequest(
    int priority,
    QueuedRequest request,
  ) async {
    assert(role == QueueRole.requestor, 'Only requestors can queue requests.');
    final result = await _connection.query(
      'INSERT INTO request_ (priority, json) '
      'VALUES (@priority, @json) RETURNING id',
      substitutionValues: {
        'priority': priority,
        'json': jsonEncode(request),
      },
    );
    // TODO(eseidel): This could be a trigger.
    await _connection.execute('NOTIFY request_');
    return result[0][0] as int;
  }

  /// Waits for a response to be available for the given request id, returning
  /// the response.
  Future<Response> _waitForResponse(
    int requestId,
  ) async {
    assert(
      role == QueueRole.requestor,
      'Only requestors can wait for responses.',
    );
    await _listenIfNeeded();
    final _ = await _connection.notifications.firstWhere(
      (notification) => notification.channel == 'response_',
    );
    // TODO(eseidel): This does not yet handle queuing multiple requests
    // and waiting on all of them.
    final result = await _connection.query(
      'SELECT json FROM response_ WHERE request_id = @requestId',
      substitutionValues: {
        'requestId': requestId,
      },
    );
    final queued = QueuedResponse.fromJson(
      jsonDecode(result[0][0] as String) as Map<String, dynamic>,
    );
    return queued.toResponse();
  }

  /// Sends the given request and waits for a response.
  Future<Response> sendAndWait(int priority, QueuedRequest request) async {
    assert(role == QueueRole.requestor, 'Only requestors can send requests.');
    final requestId = await _queueRequest(priority, request);
    return _waitForResponse(requestId);
  }

  /// Gets the next request from the queue, or null if there are no requests.
  Future<RequestRecord?> nextRequest() async {
    assert(role == QueueRole.responder, 'Only responders can get requests.');
    final result = await _connection.query(
      'SELECT id, priority, json FROM request_ ORDER BY priority DESC LIMIT 1',
    );
    if (result.isEmpty) {
      return null;
    }
    final row = result[0];
    return RequestRecord(
      id: row[0] as int,
      priority: row[1] as int,
      request: QueuedRequest.fromJson(
        jsonDecode(row[2] as String) as Map<String, dynamic>,
      ),
    );
  }

  /// Deletes the given request from the queue.
  Future<void> deleteRequest(RequestRecord request) async {
    await _connection.query(
      'DELETE FROM request_ WHERE id = @id',
      substitutionValues: {
        'id': request.id,
      },
    );
  }

  /// Responds to the given request with the given response.
  Future<void> respondToRequest(
    RequestRecord request,
    QueuedResponse response,
  ) async {
    assert(role == QueueRole.responder, 'Only responders can respond.');
    await _connection.query(
      'INSERT INTO response_ (request_id, json) '
      'VALUES (@requestId, @json)',
      substitutionValues: {
        'requestId': request.id,
        'json': jsonEncode(response),
      },
    );
    // TODO(eseidel): This could be a trigger.
    await _connection.execute('NOTIFY response_');
  }

  /// Waits for a notification that a new request is available.
  Future<void> waitForRequest() async {
    assert(role == QueueRole.responder, 'Only responders can wait.');
    await _listenIfNeeded();
    await _connection.notifications.firstWhere(
      (notification) => notification.channel == 'request_',
    );
  }
}
