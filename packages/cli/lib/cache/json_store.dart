import 'dart:convert';

import 'package:file/file.dart';
import 'package:meta/meta.dart';

/// A class to manage a file containing a json object.
/// The resulting file is valid json.
class JsonStore<Record> {
  /// Create a new JsonStore.
  JsonStore(
    this.record, {
    required FileSystem fs,
    required String path,
    required Map<String, dynamic> Function(Record) recordToJson,
  })  : _fs = fs,
        _path = path,
        _toJson = recordToJson;

  /// The root object of the store.
  @protected
  Record record;

  final Map<String, dynamic> Function(Record) _toJson;

  /// Replace the root object of the store.
  void setRecord(Record newRecord) {
    record = newRecord;
    save();
  }

  final String _path;

  /// The file system to use.
  final FileSystem _fs;

  /// Save entries to a file.
  void save() {
    final file = _fs.file(_path)..createSync(recursive: true);
    const encoder = JsonEncoder.withIndent(' ');
    final prettyprint = encoder.convert(_toJson(record));
    file.writeAsStringSync(prettyprint);
  }

  /// Load entries from a file.
  static Record? load<Record>(
    FileSystem fs,
    String path,
    Record Function(Map<String, dynamic>) recordFromJson,
  ) {
    final file = fs.file(path);
    if (file.existsSync()) {
      final contents = file.readAsStringSync();
      return recordFromJson(jsonDecode(contents) as Map<String, dynamic>);
    }
    return null;
  }
}
