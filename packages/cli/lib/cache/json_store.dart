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
  })  : _fs = fs,
        _path = path;

  /// The root object of the store.
  @protected
  Record record;

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
    _fs.file(_path)
      ..createSync(recursive: true)
      ..writeAsStringSync(jsonEncode(record));
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
