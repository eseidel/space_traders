import 'dart:async';

import 'package:cli/logger.dart';
import 'package:http/http.dart';
import 'package:types/types.dart';

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
    requestCounts.record(path);
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

/// Log the counts.
void logCounts<T>(Counts<T> counts) {
  // Print the counts in order from most to least:
  final sorted = counts.counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in sorted) {
    logger.info('  ${entry.value}: ${entry.key}');
  }
}

/// Run a function and record time and request count and log if long.
Future<T> expectTime<T>(
  RequestCounts requestCounts,
  QueryCounts queryCounts,
  String name,
  Duration expected,
  Future<T> Function() fn,
) async {
  final result = await captureTimeAndRequests<T>(
    requestCounts,
    queryCounts,
    fn,
    onComplete: (
      Duration duration,
      int requestCount,
      QueryCounts queryCounts,
    ) {
      if (duration <= expected) {
        return;
      }
      final queryCount = queryCounts.total;
      logger.warn(
        '$name took too long ${duration.inMilliseconds}ms '
        '($requestCount requests, $queryCount queries)',
      );
      logCounts(queryCounts);
    },
  );
  return result;
}
