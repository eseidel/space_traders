import 'package:cli/logger.dart';
import 'package:http/http.dart';
import 'package:types/types.dart';

/// Prints stats about rate limiting.
class RateLimitStatPrinter {
  /// Total number of requests since last reset.
  int _total = 0;

  /// Number of successful requests since last reset.
  int _successes = 0;

  /// Number of rate limited requests since last reset.
  int _rateLimits = 0;

  DateTime _lastPrintTime = DateTime.timestamp();

  void _printStatsIfNonZero(Duration duration) {
    if (_total > 0) {
      logger.info(
        '$_successes ($_rateLimits) in '
        '${approximateDuration(duration)} total: $_total',
      );
    }
  }

  void _reset() {
    _total = 0;
    _successes = 0;
    _rateLimits = 0;
  }

  /// Print the stats if it's been at least a minute since the last print.
  void printIfNeeded() {
    final sinceLastPrint = DateTime.timestamp().difference(_lastPrintTime);
    if (sinceLastPrint >= const Duration(minutes: 1)) {
      _printStatsIfNonZero(sinceLastPrint);
      _reset();
      _lastPrintTime = DateTime.timestamp();
    }
  }

  /// Record a response.
  void record(Response response) {
    _total++;
    if (response.statusCode == 429) {
      _rateLimits++;
    } else {
      _successes++;
    }
  }
}
