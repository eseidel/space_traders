import 'package:cli/cli.dart';
import 'package:cli/net/queue.dart';
import 'package:http/http.dart';
import 'package:postgres/postgres.dart';

class NetExecutor {
  NetExecutor(PostgreSQLConnection connection, {this.maxRequestsPerSecond = 3})
      : queue = NetQueue(connection, QueueRole.responder);

  final int maxRequestsPerSecond;
  final Client _client = Client();
  final NetQueue queue;

  static DateTime? _parseResetTime(Response response) {
    final resetString = response.headers['x-ratelimit-reset'];
    if (resetString == null) {
      return null;
    }
    return DateTime.parse(resetString);
  }

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

  Future<void> run() async {
    final minWaitTime = const Duration(seconds: 1) ~/ maxRequestsPerSecond;
    DateTime? nextRequestTime;
    var backoffSeconds = 1;
    while (true) {
      final request = await queue.nextRequest();
      if (request == null) {
        logger.info('Waiting...');
        await queue.waitForRequest();
        continue;
      }
      logger.info('${request.request.method} ${request.request.url}');
      if (nextRequestTime != null) {
        final waitTime = nextRequestTime.difference(DateTime.timestamp());
        if (waitTime > Duration.zero) {
          logger.detail('Waiting until $nextRequestTime');
          await Future<void>.delayed(waitTime);
        }
      }
      nextRequestTime = DateTime.timestamp().add(minWaitTime);
      final response = await sendRequest(request.request);
      logger.info('Got response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 429) {
        final resetTime = _parseResetTime(response);
        if (resetTime != null) {
          logger.info('Rate limited, waiting until $resetTime');
          final duration = resetTime.difference(DateTime.timestamp());
          await Future<void>.delayed(duration);
        } else {
          logger.err(
            'Rate limited, but no reset time found? '
            'Waiting for $backoffSeconds seconds.',
          );
          backoffSeconds *= 2;
        }
        // No need to reply to the request, since it will be retried.
        continue;
      }
      await queue.deleteRequest(request);
      await queue.respondToRequest(
        request,
        QueuedResponse.fromResponse(response),
      );
      // Success, reset the backoff.
      backoffSeconds = 1;
    }
  }
}

Future<void> command(FileSystem fs, List<String> args) async {
  final connection = await defaultDatabase();
  await NetExecutor(connection!).run();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
