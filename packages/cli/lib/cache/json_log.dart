import 'dart:convert';

import 'package:file/file.dart';

/// A class to manage a json log file.
/// The file as a whole is *not* valid json, each line of it is valid json.
class JsonLog<Record> {
  /// Create a new json log.
  JsonLog(
    List<Record> entries, {
    required FileSystem fs,
    required String path,
    required Map<String, dynamic> Function(Record) recordToJson,
  })  : _entries = entries,
        _fs = fs,
        _path = path,
        _recordToJson = recordToJson;

  final List<Record> _entries;
  final Map<String, dynamic> Function(Record) _recordToJson;

  /// The entries in the log.
  List<Record> get entries => List.unmodifiable(_entries);

  final String _path;

  /// The file system to use.
  final FileSystem _fs;

  static List<Record> _parseLogFile<Record>(
    String contents,
    Record Function(Map<String, dynamic>) recordFromJson,
  ) {
    final entries = <Record>[];
    for (final line in contents.split('\n')) {
      if (line.trim().isEmpty) {
        continue;
      }
      entries.add(recordFromJson(jsonDecode(line) as Map<String, dynamic>));
    }
    return entries;
  }

  /// Save the log to the file system.
  void save() {
    final file = _fs.file(_path)..createSync(recursive: true);
    final contents = _entries.map(_recordToJson).map(jsonEncode).join('\n');
    file.writeAsStringSync(contents);
  }

  /// Load the log from the file system.
  static Future<List<R>> load<R>(
    FileSystem fs,
    String path,
    R Function(Map<String, dynamic>) recordFromJson,
  ) async {
    final file = fs.file(path);
    if (await file.exists()) {
      return _parseLogFile<R>(await file.readAsString(), recordFromJson);
    }
    return <R>[];
  }

  /// Add an entry to the log.
  void log(Record record) {
    _entries.add(record);
    save();
  }
}
