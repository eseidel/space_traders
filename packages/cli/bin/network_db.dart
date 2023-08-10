import 'dart:async';

import 'package:cli/api.dart';
import 'package:cli/cli.dart';
import 'package:cli/net/auth.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/net/queue.dart';
import 'package:http/http.dart';

class QueuedClient extends BaseClient {
  QueuedClient(int Function() getPriority) : _getPriority = getPriority;

  final int Function() _getPriority;

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
    final response = await _queue.sendAndWait(_getPriority(), queuedRequest);
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
  // Don't want to use defaultApi, since it uses RateLimitedApiClient.
  final token = loadAuthToken(fs);
  final auth = HttpBearerAuth()..accessToken = token;
  final api = Api(ApiClient(authentication: auth));
  int getPriority() => 0;
  final queuedClient = QueuedClient(getPriority);
  api.apiClient.client = queuedClient;
  final agent = await getMyAgent(api);
  logger.info('Got agent: $agent');
  queuedClient.close();
  logger.info('Done!');
}

void main(List<String> args) async {
  await runOffline(args, command);
}
