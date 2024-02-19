import 'dart:async';

import 'package:cli/cli.dart';
import 'package:cli/config.dart';
import 'package:cli/net/queue.dart';
import 'package:cli/net/rate_limit.dart';
import 'package:cli/printing.dart';
import 'package:http/http.dart';

class NetExecutor {
  NetExecutor(
    Database db, {
    required this.targetRequestsPerSecond,
  }) : queue = NetQueue(db, QueueRole.responder);

  final double targetRequestsPerSecond;
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

  Future<void> run({DateTime Function() getNow = defaultGetNow}) async {
    logger.info('Servicing network requests...');
    final minWaitTime =
        Duration(milliseconds: (1000 / targetRequestsPerSecond).ceil());
    final stats = RateLimitStatPrinter();
    DateTime? nextRequestTime;
    var serverErrorRetryLimit = 5;
    while (true) {
      stats.printIfNeeded();

      if (nextRequestTime != null) {
        final waitTime = nextRequestTime.difference(getNow());
        if (waitTime > Duration.zero) {
          await Future<void>.delayed(waitTime);
        }
      }
      // Don't pull the next request until we're about to send it or we might
      // end up pulling a request we don't need to send or is low priority.
      final request = await queue.nextRequest();
      if (request == null) {
        const timeoutSeconds = 30;
        try {
          await queue.waitForRequest(timeoutSeconds);
        } on TimeoutException {
          logger.err('Timed out (${timeoutSeconds}s) waiting for request?');
        }
        continue;
      }
      final before = getNow();
      final path = _removeExpectedPrefix(request.request.url);
      nextRequestTime = getNow().add(minWaitTime);
      final Response response;
      try {
        response = await sendRequest(request.request);
      } on ClientException catch (e) {
        logger.err('Network error: ${e.message}');
        continue;
      }
      stats.record(response);
      final duration = getNow().difference(before);
      logger.detail(
        '${approximateDuration(duration).padRight(5)} ${request.priority} '
        '${response.statusCode} ${request.request.method.padRight(5)} $path',
      );
      if (response.statusCode == 429) {
        final resetTime = _parseResetTime(response);
        if (resetTime != null) {
          final duration = resetTime.difference(getNow());
          logger.warn('Rate limited, waiting ${approximateDuration(duration)}');
          // TODO(eseidel): Just set nextRequestTime to resetTime?
          await Future<void>.delayed(duration);
        } else {
          logger.err('Rate limited, but no reset time found?');
        }
        // No need to reply to the request, since it will be retried.
        continue;
      }
      if (response.statusCode >= 500) {
        logger.err('Server error ${response.statusCode}.');
        if (serverErrorRetryLimit-- > 0) {
          continue;
        }
        logger.err('Too many server errors, giving up.');
      }

      await queue.deleteRequest(request);
      await queue.respondToRequest(
        request,
        QueuedResponse.fromResponse(response),
      );
      // Success, reset the retry limit.
      serverErrorRetryLimit = 5;

      // Delete all responses older than 5 minutes.
      await queue.deleteResponsesBefore(
        getNow().subtract(const Duration(minutes: 5)),
      );
    }
  }
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final connection = await defaultDatabase();
  await NetExecutor(
    connection,
    targetRequestsPerSecond: config.targetRequestsPerSecond,
  ).run();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
