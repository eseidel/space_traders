import 'dart:async';

import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:http/http.dart';
import 'package:types/types.dart';

/// RequestCounts tracks the number of requests made to each path.
class RequestCounts {
  /// The counts.
  final Map<String, int> counts = {};

  /// Get the number of requests made to the given path.
  void recordRequest(String path) {
    counts[path] = (counts[path] ?? 0) + 1;
  }

  /// Get the total number of requests made.
  int get totalRequests => counts.values.fold(0, (a, b) => a + b);

  /// Reset the counts.
  void reset() {
    counts.clear();
  }
}

/// ApiClient that counts the number of requests made.
class CountingApiClient extends ApiClient {
  /// Construct a rate limited api client.
  CountingApiClient({super.authentication, super.basePath});

  /// RequestCounts tracks the number of requests made to each path.
  final RequestCounts requestCounts = RequestCounts();

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
    logger.detail(path);
    requestCounts.recordRequest(path);
    return super.invokeAPI(
      path,
      method,
      queryParams,
      body,
      headerParams,
      formParams,
      contentType,
    );
  }
}

/// Run a function and record time and request count.
Future<T> captureTimeAndRequests<T>(
  RequestCounts requestCounts,
  QueryCounts queryCounts,
  Future<T> Function() fn, {
  required void Function(Duration duration, int requestCount, int queryCount)
      onComplete,
}) async {
  final before = DateTime.timestamp();
  final requestsBefore = requestCounts.totalRequests;
  final queriesBefore = queryCounts.totalQueries;
  final result = await fn();
  final after = DateTime.timestamp();
  final duration = after.difference(before);
  final requestsAfter = requestCounts.totalRequests;
  final queriesAfter = queryCounts.totalQueries;
  final requests = requestsAfter - requestsBefore;
  final queries = queriesAfter - queriesBefore;
  onComplete(duration, requests, queries);
  return result;
}

Map<String, int> _diffCounts(
  Map<String, int> before,
  Map<String, int> after,
) {
  final result = <String, int>{};
  for (final key in after.keys) {
    final diff = after[key]! - (before[key] ?? 0);
    if (diff != 0) {
      result[key] = diff;
    }
  }
  return result;
}

/// Run a function and record time and request count and log if long.
Future<T> expectTime<T>(
  RequestCounts requestCounts,
  QueryCounts queryCounts,
  String name,
  Duration expected,
  Future<T> Function() fn,
) async {
  final before = DateTime.timestamp();
  final requestsBefore = requestCounts.totalRequests;
  final queryCountBefore = queryCounts.totalQueries;
  final queriesBefore = Map<String, int>.from(queryCounts.counts);
  final result = await fn();
  final after = DateTime.timestamp();
  final duration = after.difference(before);
  final requestsAfter = requestCounts.totalRequests;
  final queryCountAfter = queryCounts.totalQueries;
  final requests = requestsAfter - requestsBefore;
  final queryCount = queryCountAfter - queryCountBefore;
  final queriesDiff = _diffCounts(queriesBefore, queryCounts.counts);
  if (duration > expected) {
    logger.warn(
      '$name took too long ${duration.inMilliseconds}ms '
      '($requests requests, $queryCount queries)',
    );
    // Print the counts in order from most to least:
    final sorted = queriesDiff.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sorted) {
      logger.info('  ${entry.value}: ${entry.key}');
    }
  }
  return result;
}
