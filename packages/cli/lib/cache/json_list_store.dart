import 'dart:convert';

import 'package:file/file.dart';
import 'package:meta/meta.dart';

/// A class to manage a file containing a list of json objects.
/// The resulting file is valid json.
class JsonListStore<Record> {
  /// Create a new JsonListStore.
  JsonListStore(
    this.entries, {
    required FileSystem fs,
    required String path,
  })  : _fs = fs,
        _path = path;

  /// The entries in the store.
  @protected
  final List<Record> entries;

  /// The number of entries in the store.
  int get count => entries.length;

  final String _path;

  /// The file system to use.
  final FileSystem _fs;

  static List<Record> _parseRecords<Record>(
    String contents,
    Record Function(Map<String, dynamic>) recordFromJson,
  ) {
    final parsed = jsonDecode(contents) as List<dynamic>;
    return parsed
        .map<Record>(
          (e) => recordFromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  /// Save entries to a file.
  Future<void> save() async {
    await _fs.file(_path).writeAsString(jsonEncode(entries));
  }

  /// Load entries from a file.
  static Future<List<R>> load<R>(
    FileSystem fs,
    String path,
    R Function(Map<String, dynamic>) recordFromJson,
  ) async {
    final file = fs.file(path);
    if (await file.exists()) {
      return _parseRecords<R>(await file.readAsString(), recordFromJson);
    }
    return <R>[];
  }
}