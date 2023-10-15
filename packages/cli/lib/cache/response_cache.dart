import 'package:cli/api.dart';
import 'package:cli/cache/json_list_store.dart';
import 'package:cli/compare.dart';
import 'package:cli/logger.dart';

/// Cache of response values which can be refreshed.
class ResponseListCache<T> extends JsonListStore<T> {
  /// Creates a new ResponseListCache.
  ResponseListCache(
    super.entries, {
    required Future<List<T>> Function(Api api) refreshEntries,
    required super.fs,
    required super.path,
    this.checkEvery = 100,
  }) : _refreshEntries = refreshEntries;

  final Future<List<T>> Function(Api api) _refreshEntries;

  /// Number of requests between checks to ensure entries are up to date.
  final int checkEvery;

  int _iterationsSinceLastCheck = 0;

  /// Ensures the entries in the cache are up to date.
  Future<void> ensureUpToDate(Api api) async {
    _iterationsSinceLastCheck++;
    if (_iterationsSinceLastCheck < checkEvery) {
      return;
    }
    final newEntries = await _refreshEntries(api);
    _iterationsSinceLastCheck = 0;
    if (jsonListMatch(entries, newEntries)) {
      return;
    }
    logger.warn('$T list changed, updating cache.');
    replaceEntries(newEntries);
  }

  /// Updates the entries in the cache.
  void replaceEntries(List<T> newEntries) {
    entries
      ..clear()
      ..addAll(newEntries);
    save();
  }
}
