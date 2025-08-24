import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:types/queue.dart';

/// A type alias for a JSON object.
typedef Json = Map<String, dynamic>;

/// An extension on [http.Response] to decode the body as a JSON object.
extension JsonDecode on http.Response {
  /// Decodes the body of the response as a JSON object.
  Json get json => jsonDecode(body) as Json;
}

/// Request queued for later execution.
@immutable
class RequestRecord extends Equatable {
  /// Creates a new [RequestRecord].
  const RequestRecord({required this.priority, required this.request, this.id});

  /// id of the request in the database if it has been inserted.
  final int? id;

  /// Priority of the request.  Higher priority requests are executed first.
  final int priority;

  /// The queued request
  final QueuedRequest request;

  @override
  List<Object?> get props => [id, priority, request];
}

/// Response record in the database.
@immutable
class ResponseRecord extends Equatable {
  /// Creates a new [ResponseRecord].
  const ResponseRecord({
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

  @override
  List<Object?> get props => [id, requestId, response];
}
