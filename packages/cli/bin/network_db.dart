import 'dart:async';

import 'package:cli/api.dart';
import 'package:cli/cli.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/net/queue.dart';
import 'package:http/http.dart';

class DatabaseApiClient extends ApiClient {
  /// Construct a rate limited api client.
  DatabaseApiClient({super.authentication}) : _queue = NetQueue();

  final NetQueue _queue;

  Future<void> disconnect() => _queue.disconnect();

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
    final urlEncodedQueryParams = queryParams.map((param) => '$param');
    final queryString = urlEncodedQueryParams.isNotEmpty
        ? '?${urlEncodedQueryParams.join('&')}'
        : '';

    final request = QueuedRequest(
      id: 0,
      priority: 0,
      method: method,
      url: '$path$queryString',
      body: body.toString(),
    );
    final response = await _queue.sendAndWait(request);
    return response;
  }
}

Future<void> command(FileSystem fs, List<String> args) async {
  final apiClient = DatabaseApiClient();
  final api = Api(apiClient);
  final agent = await getMyAgent(api);
  logger.info('Got agent: $agent');
  await apiClient.disconnect();
  logger.info('Done!');
}

void main(List<String> args) async {
  await runOffline(args, command);
}
