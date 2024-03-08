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
