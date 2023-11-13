import 'dart:convert';

import 'package:file/file.dart';
import 'package:meta/meta.dart';

/// A class to manage a file containing a list of json objects.
/// The resulting file is valid json.
class JsonListStore<Record extends Object> {
  /// Create a new JsonListStore.
  JsonListStore(
    this.records, {
    required FileSystem fs,
    required String path,
  })  : _fs = fs,
        _path = path;

  /// The records in the store.
  @protected
  @visibleForTesting
  final List<Record> records;

  /// The number of records in the store.
  int get count => records.length;

  final String _path;

  /// The file system to use.
  final FileSystem _fs;

  static List<Record> _parseRecords<Record>(
    String contents,
    Record Function(Map<String, dynamic>) recordFromJson,
  ) {
    final parsed = jsonDecode(contents) as List<dynamic>;
    return parsed
        .map<Record>((e) => recordFromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Save records to a file.
  void save() {
    final file = _fs.file(_path)..createSync(recursive: true);
    const encoder = JsonEncoder.withIndent(' ');
    final prettyprint = encoder.convert(records);
    file.writeAsStringSync(prettyprint);
  }

  /// Load records from a file.
  static List<R>? loadRecords<R>(
    FileSystem fs,
    String path,
    R Function(Map<String, dynamic>) recordFromJson,
  ) {
    final file = fs.file(path);
    if (file.existsSync()) {
      return _parseRecords<R>(file.readAsStringSync(), recordFromJson);
    }
    return null;
  }
}
