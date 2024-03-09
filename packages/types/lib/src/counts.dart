/// RequestCounts tracks the number of requests made to each path.
class Counts<T> {
  /// Construct a RequestCounts.
  Counts([Map<T, int>? counts]) : counts = Map<T, int>.from(counts ?? {});

  /// The counts.
  final Map<T, int> counts;

  /// Get the number of requests made to the given path.
  void record(T path) => counts[path] = (counts[path] ?? 0) + 1;

  /// Diff two count maps.
  static Map<T, int> diffCounts<T>(
    Map<T, int> before,
    Map<T, int> after,
  ) {
    final result = <T, int>{};
    for (final key in after.keys) {
      final diff = after[key]! - (before[key] ?? 0);
      if (diff != 0) {
        result[key] = diff;
      }
    }
    return result;
  }

  /// Get the total number of requests made.
  int get total => counts.values.fold(0, (a, b) => a + b);

  /// Reset the counts.
  void reset() => counts.clear();
}

/// QueryCounts tracks the number of queries made.
class QueryCounts extends Counts<String> {
  /// Construct a QueryCounts.
  QueryCounts([super.counts]);

  /// Diff the counts with the given QueryCounts.
  QueryCounts diff(QueryCounts before) =>
      QueryCounts(Counts.diffCounts(before.counts, counts));

  /// Make a copy of the QueryCounts.
  QueryCounts copy() => QueryCounts(counts);
}

/// RequestCounts tracks the number of requests made to each path.
class RequestCounts extends Counts<String> {
  /// Construct a RequestCounts.
  RequestCounts([super.counts]);

  /// Diff the counts with the given RequestCounts.
  RequestCounts diff(RequestCounts before) =>
      RequestCounts(Counts.diffCounts(before.counts, counts));

  /// Make a copy of the RequestCounts.
  RequestCounts copy() => RequestCounts(counts);
}

/// Run a function and record time and request count.
Future<T> captureTimeAndRequests<T>(
  RequestCounts requestCounts,
  QueryCounts queryCounts,
  Future<T> Function() fn, {
  required void Function(
    Duration duration,
    int requestCount,
    QueryCounts queryCounts,
  ) onComplete,
}) async {
  final before = DateTime.timestamp();
  final requestsBefore = requestCounts.total;
  final queriesBefore = queryCounts.copy();
  final result = await fn();
  final after = DateTime.timestamp();
  final duration = after.difference(before);
  final requestsAfter = requestCounts.total;
  final requests = requestsAfter - requestsBefore;
  final queriesDiff = queryCounts.diff(queriesBefore);
  onComplete(duration, requests, queriesDiff);
  return result;
}
