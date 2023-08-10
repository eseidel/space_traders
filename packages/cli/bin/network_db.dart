import 'dart:async';

import 'package:cli/cli.dart';
import 'package:cli/net/auth.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/net/queue.dart';
import 'package:http/http.dart';

// class DatabaseApiClient extends ApiClient {
//   /// Construct a rate limited api client.
//   DatabaseApiClient({super.authentication}) : _queue = NetQueue();

//   final NetQueue _queue;

//   Future<void> disconnect() => _queue.disconnect();

//   @override
//   Future<Response> invokeAPI(
//     String path,
//     String method,
//     List<QueryParam> queryParams,
//     Object? body,
//     Map<String, String> headerParams,
//     Map<String, String> formParams,
//     String? contentType,
//   ) async {
//     final urlEncodedQueryParams = queryParams.map((param) => '$param');
//     final queryString = urlEncodedQueryParams.isNotEmpty
//         ? '?${urlEncodedQueryParams.join('&')}'
//         : '';
//     final uri = Uri.parse('$basePath$path$queryString');

//     final request = QueuedRequest(
//       id: 0,
//       priority: 0,
//       method: method,
//       url: uri.toString(),
//       body: body == null ? '' : body.toString(),
//     );
//     final response = await _queue.sendAndWait(request);
//     return response;
//   }
// }

class QueuedClient extends BaseClient {
  final NetQueue _queue = NetQueue(QueueRole.requestor);

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final stream = request.finalize();
    final body = await stream.toBytes();

    final queuedRequest = QueuedRequest(
      method: request.method,
      url: request.url.toString(),
      body: String.fromCharCodes(body),
      headers: request.headers,
    );
    const priority = 0;
    final response = await _queue.sendAndWait(priority, queuedRequest);
    return StreamedResponse(
      Stream.fromIterable([response.bodyBytes]),
      response.statusCode,
      contentLength: response.bodyBytes.length,
      request: request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() {
    _queue.disconnect();
  }
}

Future<void> command(FileSystem fs, List<String> args) async {
  final api = defaultApi(fs);
  final queuedClient = QueuedClient();
  api.apiClient.client = queuedClient;
  final agent = await getMyAgent(api);
  logger.info('Got agent: $agent');
  queuedClient.close();
  logger.info('Done!');
}

void main(List<String> args) async {
  await runOffline(args, command);
}
