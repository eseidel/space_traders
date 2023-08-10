import 'package:cli/cli.dart';
import 'package:cli/net/queue.dart';
import 'package:http/http.dart';

class NetExecutor {
  final Client _client = Client();

  Future<Response> sendRequest(QueuedRequest request) async {
    final method = request.method;
    final uri = Uri.parse(request.url);
    final body = request.body;
    final headers = request.headers;
    switch (method) {
      case 'POST':
        return _client.post(uri, headers: headers, body: body);
      case 'PUT':
        return _client.put(uri, headers: headers, body: body);
      case 'DELETE':
        return _client.delete(uri, headers: headers, body: body);
      case 'PATCH':
        return _client.patch(uri, headers: headers, body: body);
      case 'HEAD':
        return _client.head(uri, headers: headers);
      case 'GET':
        return _client.get(uri, headers: headers);
    }
    throw Exception('Unknown method: $method');
  }
}

Future<void> command(FileSystem fs, List<String> args) async {
  final queue = NetQueue(QueueRole.responder);
  final executor = NetExecutor();
  while (true) {
    final request = await queue.nextRequest();
    if (request == null) {
      logger.info('Waiting...');
      await queue.waitForRequest();
      continue;
    }
    logger.info('Got request: $request');
    final response = await executor.sendRequest(request.request);
    logger.info('Got response: ${response.statusCode} ${response.body}');
    await queue.respondToRequest(
      request,
      QueuedResponse.fromResponse(response),
    );
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
