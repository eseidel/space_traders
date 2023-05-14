import 'package:http/http.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/logger.dart';

// This does not yet support "burst" requests which the api allows.
// This also could hold a queue of recent request times to allow for more
// accurate rate limiting.
/// Rate limiting api client.
class RateLimitedApiClient extends ApiClient {
  final int requestsPerSecond;
  DateTime _nextRequestTime = DateTime.now();

  RateLimitedApiClient({required this.requestsPerSecond, super.authentication});

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
    final beforeRequest = DateTime.now();
    if (beforeRequest.isBefore(_nextRequestTime)) {
      logger.detail(
          "Rate limiting request. Next request time: $_nextRequestTime");
      await Future.delayed(_nextRequestTime.difference(beforeRequest));
    }
    final response = await super.invokeAPI(
        path, method, queryParams, body, headerParams, formParams, contentType);
    final afterRequest = DateTime.now();
    _nextRequestTime =
        afterRequest.add(Duration(milliseconds: 1000 ~/ requestsPerSecond));
    return response;
  }
}
