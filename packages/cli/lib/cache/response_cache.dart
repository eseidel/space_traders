import 'dart:convert';

import 'package:cli/api.dart';
import 'package:cli/cache/json_list_store.dart';
import 'package:cli/logger.dart';
import 'package:cli/third_party/compare.dart';

/// Returns true if the two lists of T match when converted to Json.
bool jsonListMatch<T>(
  List<T> actual,
  List<T> expected,
  Map<String, dynamic> Function(T t) toJson,
) {
  if (actual.length != expected.length) {
    logger.info(
      "$T list lengths don't match: "
      '${actual.length} != ${expected.length}',
    );
    return false;
  }

  for (var i = 0; i < actual.length; i++) {
    final diff = findDifferenceBetweenStrings(
      jsonEncode(toJson(actual[i])),
      jsonEncode(toJson(expected[i])),
    );
    if (diff != null) {
      logger.info('$T list differs at index $i: ${diff.which}');
      return false;
    }
  }
  return true;
}

/// Cache of response values which can be refreshed.
class ResponseListCache<T> extends JsonListStore<T> {
  /// Creates a new ResponseListCache.
  ResponseListCache(
    super.entries, {
    required Map<String, dynamic> Function(T t) entryToJson,
    required Future<List<T>> Function(Api api) refreshEntries,
    required super.fs,
    required super.path,
    this.checkEvery = 100,
  })  : _entryToJson = entryToJson,
        _refreshEntries = refreshEntries;

  final Map<String, dynamic> Function(T t) _entryToJson;
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
    if (jsonListMatch(entries, newEntries, _entryToJson)) {
      return;
    }
    logger.warn('$T list changed, updating cache.');
    await update(newEntries);
  }

  /// Updates the entries in the cache.
  Future<void> update(List<T> newEntries) async {
    entries
      ..clear()
      ..addAll(newEntries);
  }
}
