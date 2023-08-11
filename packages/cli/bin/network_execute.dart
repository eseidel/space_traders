import 'package:cli/cli.dart';
import 'package:cli/net/queue.dart';
import 'package:cli/net/rate_limit.dart';
import 'package:cli/printing.dart';
import 'package:db/db.dart';
import 'package:http/http.dart';

class NetExecutor {
  NetExecutor(
    Database db, {
    this.targetRequestsPerSecond = 3,
  }) : queue = NetQueue(db, QueueRole.responder);

  final int targetRequestsPerSecond;
  final Client _client = Client();
  final NetQueue queue;

  static DateTime? _parseResetTime(Response response) {
    final resetString = response.headers['x-ratelimit-reset'];
    if (resetString == null) {
      return null;
    }
    return DateTime.parse(resetString);
  }

  Future<Response> _dispatchRequest(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) {
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

  Future<Response> sendRequest(QueuedRequest request) async {
    final method = request.method;
    final uri = Uri.parse(request.url);
    final body = request.body;
    final headers = request.headers;
    final response =
        await _dispatchRequest(method, uri, headers: headers, body: body);
    return response;
  }

  String _removeExpectedPrefix(String url) {
    const expectedPrefix = 'https://api.spacetraders.io/v2';
    if (!url.startsWith(expectedPrefix)) {
      return url;
    }
    return url.substring(expectedPrefix.length);
  }

  Future<void> run() async {
    logger.info('Servicing network requests...');
    final minWaitTime = const Duration(seconds: 1) ~/ targetRequestsPerSecond;
    final stats = RateLimitStatPrinter();
    DateTime? nextRequestTime;
    var backoffSeconds = 1;
    while (true) {
      stats.printIfNeeded();
      final request = await queue.nextRequest();
      if (request == null) {
        await queue.waitForRequest();
        continue;
      }
      if (nextRequestTime != null) {
        final waitTime = nextRequestTime.difference(DateTime.timestamp());
        if (waitTime > Duration.zero) {
          logger.detail('Waiting until $nextRequestTime');
          await Future<void>.delayed(waitTime);
        }
      }
      final before = DateTime.timestamp();
      final path = _removeExpectedPrefix(request.request.url);
      nextRequestTime = DateTime.timestamp().add(minWaitTime);
      final response = await sendRequest(request.request);
      stats.record(response);
      final duration = DateTime.timestamp().difference(before);
      logger.detail(
        '${approximateDuration(duration)} ${response.statusCode} '
        '${request.request.method.padRight(5)} $path',
      );
      if (response.statusCode == 429) {
        final resetTime = _parseResetTime(response);
        if (resetTime != null) {
          logger.warn('Rate limited, waiting until $resetTime');
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
  await NetExecutor(connection).run();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
