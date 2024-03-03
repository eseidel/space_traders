import 'dart:async';

import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:db/src/queue.dart';
import 'package:http/http.dart';
import 'package:types/queue.dart';

export 'package:types/queue.dart';

/// Default priority for executing network requests.
// Belongs in NetworkQueue?
const int networkPriorityDefault = 0;

/// Low priority for executing network requests.
const int networkPriorityLow = -1;

/// An http Client implementation which sends requests to another process
/// through a postgres queue.
class QueuedClient extends BaseClient {
  /// Creates a new [QueuedClient].
  QueuedClient(Database db, [this.getPriority])
      : _db = db,
        _queue = NetQueue(db, QueueRole.requestor);

  /// Callback to get the priority of the next request.
  int Function()? getPriority;

  final Database _db;
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
    final priority = getPriority?.call() ?? networkPriorityDefault;
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
  void close() => _db.close();
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
  NetQueue(Database db, this.role) : _db = db;

  final Database _db;

  /// Role of the user of this queue.
  final QueueRole role;

  bool _listening = false;

  Future<void> _listenIfNeeded() async {
    if (_listening) {
      return;
    }
    if (role == QueueRole.requestor) {
      await _db.listen('response_');
    } else {
      await _db.listen('request_');
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
    // TODO(eseidel): Move this into db package.
    final requestId = await _db.insertRequest(
      RequestRecord(
        priority: priority,
        request: request,
      ),
    );
    // TODO(eseidel): This could be a trigger.
    await _db.notify('request_', '$requestId');
    return requestId;
  }

  /// Waits for a response to be available for the given request id, returning
  /// the response.
  Future<Response> _waitForResponse(int requestId) async {
    assert(
      role == QueueRole.requestor,
      'Only requestors can wait for responses.',
    );
    await _listenIfNeeded();
    var timeoutSeconds = 1;
    while (true) {
      // TODO(eseidel): This does not yet handle queuing multiple requests
      // and waiting on all of them.
      final result = await _db.getResponseForRequest(requestId);
      // If we don't yet have a response, wait for one.
      if (result != null) {
        return result.response.toResponse();
      }
      try {
        await _db
            .waitOnChannel('response_')
            .timeout(Duration(seconds: timeoutSeconds));
      } on TimeoutException {
        logger.err('Timed out (${timeoutSeconds}s) waiting for response?');
        timeoutSeconds *= 2;
      }
    }
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
    final request = await _db.nextRequest();
    return request;
  }

  /// Deletes the given request from the queue.
  Future<void> deleteRequest(RequestRecord request) async {
    await _db.deleteRequest(request);
  }

  /// Responds to the given request with the given response.
  Future<void> respondToRequest(
    RequestRecord request,
    QueuedResponse response,
  ) async {
    assert(role == QueueRole.responder, 'Only responders can respond.');
    await _db.insertResponse(
      ResponseRecord(requestId: request.id!, response: response),
    );
    // TODO(eseidel): This could be a trigger.
    await _db.notify('response_', '${request.id}');
  }

  /// Waits for a notification that a new request is available.
  Future<void> waitForRequest(int timeoutSeconds) async {
    assert(role == QueueRole.responder, 'Only responders can wait.');
    await _listenIfNeeded();
    await _db
        .waitOnChannel('request_')
        .timeout(Duration(seconds: timeoutSeconds));
  }

  /// Deletes all responses older than the given cutoff.
  Future<void> deleteResponsesBefore(DateTime cutoff) async {
    await _db.deleteResponsesBefore(cutoff);
  }
}
