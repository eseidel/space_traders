import 'package:types/queue.dart';

/// Request queued for later execution.
// TODO(eseidel): Does this belong in types?
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
