import 'dart:async';

import 'package:cli/api.dart';
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
  int totalRequests() {
    return counts.values.fold(0, (a, b) => a + b);
  }

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
