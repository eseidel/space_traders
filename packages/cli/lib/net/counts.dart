import 'dart:async';

import 'package:cli/api.dart';
import 'package:cli/logger.dart';
import 'package:http/http.dart';

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
  Future<T> Function() fn, {
  required void Function(Duration duration, int requestCount) onComplete,
}) async {
  final before = DateTime.timestamp();
  final requestsBefore = requestCounts.totalRequests;
  final result = await fn();
  final after = DateTime.timestamp();
  final duration = after.difference(before);
  final requestsAfter = requestCounts.totalRequests;
  final requests = requestsAfter - requestsBefore;
  onComplete(duration, requests);
  return result;
}
