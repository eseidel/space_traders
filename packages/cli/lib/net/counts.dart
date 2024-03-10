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
    final response = await super.invokeAPI(
      path,
      method,
      queryParams,
      body,
      headerParams,
      formParams,
      contentType,
    );
    // logger.info(response.body);
    return response;
  }
}
