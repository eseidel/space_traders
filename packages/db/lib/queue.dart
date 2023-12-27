import 'dart:convert';

import 'package:db/query.dart';
import 'package:types/queue.dart';

/// Request queued for later execution.
// TODO(eseidel): Does this belong in types?
class RequestRecord {
  /// Creates a new [RequestRecord].
  const RequestRecord({
    required this.priority,
    required this.request,
    this.id,
  });

  /// id of the request in the database if it has been inserted.
  final int? id;

  /// Priority of the request.  Higher priority requests are executed first.
  final int priority;

  /// The queued request
  final QueuedRequest request;
}

/// Response record in the database.
class ResponseRecord {
  /// Creates a new [ResponseRecord].
  ResponseRecord({
    required this.requestId,
    required this.response,
    this.id,
  });

  /// id of the request in the database if it has been inserted.
  final int? id;

  /// request this is responding too
  final int requestId;

  /// The queued response
  final QueuedResponse response;
}

/// Query to insert a request into the database.
Query insertRequestQuery(RequestRecord request) => Query(
      'INSERT INTO request_ (priority, json) '
      'VALUES (@priority, @json) RETURNING id',
      substitutionValues: {
        'priority': request.priority,
        'json': jsonEncode(request.request),
      },
    );

/// Query to insert a response into the database.
Query insertResponseQuery(ResponseRecord response) => Query(
      'INSERT INTO response_ (request_id, json) '
      'VALUES (@request_id, @json)',
      substitutionValues: {
        'request_id': response.requestId,
        'json': jsonEncode(response.response),
      },
    );

/// Query to delete a request from the database.
Query deleteRequestQuery(RequestRecord request) => Query(
      'DELETE FROM request_ WHERE id = @request_id',
      substitutionValues: {'request_id': request.id},
    );

/// Query to delete a response from the database.
Query deleteResponseQuery(int responseId) => Query(
      'DELETE FROM response_ WHERE id = @response_id',
      substitutionValues: {'response_id': responseId},
    );

/// Query to get the next request from the database.
Query nextRequestQuery() => const Query(
      'SELECT id, priority, json FROM request_ '
      'ORDER BY priority DESC, id ASC LIMIT 1',
    );

/// Query to get a request from the database.
Query getRequestQuery(int requestId) => Query(
      'SELECT id, priority, json FROM request_ '
      'WHERE id = @request_id',
      substitutionValues: {'request_id': requestId},
    );

/// Query to get a response from the database.
Query getResponseForRequestQuery(int requestId) => Query(
      'SELECT id, request_id, json FROM response_ '
      'WHERE request_id = @request_id',
      substitutionValues: {'request_id': requestId},
    );

/// Convert a column map to a [ResponseRecord].
RequestRecord requestRecordFromColumnMap(Map<String, dynamic> map) {
  return RequestRecord(
    id: map['id'] as int,
    priority: map['priority'] as int,
    request: QueuedRequest.fromJson(
      map['json'] as Map<String, dynamic>,
    ),
  );
}

/// Convert a column map to a [ResponseRecord].
ResponseRecord responseRecordFromColumnMap(Map<String, dynamic> map) {
  return ResponseRecord(
    id: map['id'] as int,
    requestId: map['request_id'] as int,
    response: QueuedResponse.fromJson(
      map['json'] as Map<String, dynamic>,
    ),
  );
}
