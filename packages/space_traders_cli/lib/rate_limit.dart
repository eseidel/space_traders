import 'package:http/http.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/logger.dart';

// This does not yet support "burst" requests which the api allows.
// This also could hold a queue of recent request times to allow for more
// accurate rate limiting.
/// Rate limiting api client.
class RateLimitedApiClient extends ApiClient {
  /// Construct a rate limited api client.
  RateLimitedApiClient({required this.requestsPerSecond, super.authentication});

  /// The number of requests per second to allow.
  final int requestsPerSecond;

  DateTime _nextRequestTime = DateTime.now();

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
        'Rate limiting request. Next request time: $_nextRequestTime',
      );
      await Future<void>.delayed(_nextRequestTime.difference(beforeRequest));
    }
    final response = await super.invokeAPI(
      path,
      method,
      queryParams,
      body,
      headerParams,
      formParams,
      contentType,
    );
    final afterRequest = DateTime.now();
    _nextRequestTime =
        afterRequest.add(Duration(milliseconds: 1000 ~/ requestsPerSecond));
    return response;
  }
}
