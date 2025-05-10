import 'package:db/db.dart';
import 'package:db/src/query.dart';
import 'package:db/src/queue.dart';

/// Store for network requests and responses.
class NetworkStore {
  /// Creates a new [NetworkStore].
  NetworkStore(this._db);

  final Database _db;

  /// Return the next request to be executed.
  Future<RequestRecord?> nextRequest() =>
      _db.queryOne(nextRequestQuery(), requestRecordFromColumnMap);

  /// Insert the given request into the database and return it's new id.
  Future<int> insertRequest(RequestRecord request) async {
    final query = insertRequestQuery(request);
    final result = await _db.execute(query);
    return result.first.first! as int;
  }

  /// Get the request with the given id.
  Future<RequestRecord?> getRequest(int requestId) async {
    final query = getRequestQuery(requestId);
    return _db.queryOne(query, requestRecordFromColumnMap);
  }

  /// Delete the given request from the database.
  Future<void> deleteRequest(RequestRecord request) async {
    final query = deleteRequestQuery(request);
    final result = await _db.execute(query);
    if (result.affectedRows != 1) {
      throw ArgumentError('Request not found: $request');
    }
  }

  /// Insert the given response into the database.
  Future<void> insertResponse(ResponseRecord response) async {
    await _db.execute(insertResponseQuery(response));
  }

  /// Get the response with the given id.
  Future<ResponseRecord?> getResponseForRequest(int requestId) async {
    final query = getResponseForRequestQuery(requestId);
    return _db.queryOne(query, responseRecordFromColumnMap);
  }

  /// Delete responses older than the given age.
  Future<void> deleteResponsesBefore(DateTime timestamp) {
    return _db.execute(
      Query(
        'DELETE FROM response_ WHERE created_at < @timestamp',
        parameters: {'timestamp': timestamp},
      ),
    );
  }
}
