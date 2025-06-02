import 'dart:async';

import 'package:cli/logger.dart';
import 'package:http/http.dart';
import 'package:types/types.dart';

/// ApiClient that counts the number of requests made.
class CountingApiClient extends ApiClient {
  /// Construct a rate limited api client.
  CountingApiClient({super.baseUri, super.client, super.defaultHeaders});

  /// RequestCounts tracks the number of requests made to each path.
  final RequestCounts requestCounts = RequestCounts();

  @override
  Future<Response> invokeApi({
    required Method method,
    required String path,
    Map<String, String> queryParameters = const {},
    Map<String, dynamic>? body = const {},
  }) async {
    logger.detail(path);
    requestCounts.record(path);
    final response = await super.invokeApi(
      method: method,
      path: path,
      queryParameters: queryParameters,
      body: body,
    );
    // logger.info(response.body);
    return response;
  }
}
