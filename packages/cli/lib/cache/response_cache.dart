import 'dart:convert';

import 'package:cli/api.dart';
import 'package:cli/logger.dart';
import 'package:cli/third_party/compare.dart';
import 'package:file/file.dart';

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

/// In-memory cache of List<T> responses.
class ResponseListCache<T> {
  /// Creates a new ResponseListCache.
  ResponseListCache(
    this.entries, {
    required Map<String, dynamic> Function(T t) entryToJson,
    required Future<List<T>> Function(Api api) refreshEntries,
    FileSystem? fs,
    String? path,
    this.checkEvery = 100,
  })  : _entryToJson = entryToJson,
        _refreshEntries = refreshEntries,
        _fs = fs,
        _path = path;

  final Map<String, dynamic> Function(T t) _entryToJson;
  final Future<List<T>> Function(Api api) _refreshEntries;

  /// Entries in the cache.
  final List<T> entries;

  final String? _path;

  /// The file system to use.
  final FileSystem? _fs;

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

  static List<T> _parseEntries<T>(
    String contents,
    T Function(Map<String, dynamic>) entryFromJson,
  ) {
    final parsed = jsonDecode(contents) as List<dynamic>;
    return parsed
        .map<T>(
          (e) => entryFromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  /// Load entries from a file.
  static List<R>? load<R>(
    FileSystem fs,
    String path,
    R Function(Map<String, dynamic>) entryFromJson,
  ) {
    final file = fs.file(path);
    if (!file.existsSync()) {
      return null;
    }
    return _parseEntries<R>(file.readAsStringSync(), entryFromJson);
  }

  /// Saves the entries to disk.
  Future<void> save() async {
    if (_path == null || _fs == null) {
      return;
    }
    final file = _fs!.file(_path);
    await file.create(recursive: true);
    const encoder = JsonEncoder.withIndent(' ');
    final prettyprint = encoder.convert(entries.map(_entryToJson).toList());
    await file.writeAsString(prettyprint);
  }
}
