import 'dart:async';

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
    var serverErrorRetryLimit = 5;
    var backoffSeconds = 1;
    while (true) {
      stats.printIfNeeded();
      if (nextRequestTime != null) {
        final waitTime = nextRequestTime.difference(DateTime.timestamp());
        if (waitTime > Duration.zero) {
          // logger.detail('Waiting until $nextRequestTime');
          await Future<void>.delayed(waitTime);
        }
      }
      // Don't pull the next request until we're about to send it or we might
      // end up pulling a request we don't need to send or is low priority.
      final request = await queue.nextRequest();
      if (request == null) {
        final timeoutSeconds = backoffSeconds * 30;
        try {
          await queue.waitForRequest(timeoutSeconds);
        } on TimeoutException {
          logger.err('Timed out (${timeoutSeconds}s) waiting for request?');
          backoffSeconds *= 2;
        }
        continue;
      }
      final before = DateTime.timestamp();
      final path = _removeExpectedPrefix(request.request.url);
      nextRequestTime = DateTime.timestamp().add(minWaitTime);
      final Response response;
      try {
        response = await sendRequest(request.request);
      } on ClientException catch (e) {
        logger.err(
          'Network error: ${e.message}'
          'Waiting for $backoffSeconds seconds.',
        );
        backoffSeconds *= 2;
        continue;
      }
      stats.record(response);
      final duration = DateTime.timestamp().difference(before);
      logger.detail(
        '${approximateDuration(duration).padRight(5)} ${request.priority} '
        '${response.statusCode} ${request.request.method.padRight(5)} $path',
      );
      if (response.statusCode == 429) {
        final resetTime = _parseResetTime(response);
        if (resetTime != null) {
          final duration = resetTime.difference(DateTime.timestamp());
          logger.warn('Rate limited, waiting ${approximateDuration(duration)}');
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
      if (response.statusCode >= 500) {
        logger.err(
          'Server error ${response.statusCode}, waiting for $backoffSeconds '
          'seconds.',
        );
        backoffSeconds *= 2;
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
      // Success, reset the backoff.
      backoffSeconds = 1;
      serverErrorRetryLimit = 5;

      // Delete all responses older than 5 minutes.
      await queue.deleteResponsesBefore(
        DateTime.timestamp().subtract(const Duration(minutes: 5)),
      );
    }
  }
}

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final connection = await defaultDatabase();
  await NetExecutor(connection).run();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
