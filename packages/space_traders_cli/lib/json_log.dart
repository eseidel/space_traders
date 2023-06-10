import 'dart:convert';

import 'package:file/file.dart';

/// A class to manage a json log file.
class JsonLog<Record> {
  /// Create a new json log.
  JsonLog(
    List<Record> entries, {
    required FileSystem fs,
    required String path,
  })  : _entries = entries,
        _fs = fs,
        _path = path;

  final List<Record> _entries;

  final String _path;

  /// The file system to use.
  final FileSystem _fs;

  static List<Record> _parseLogFile<Record>(String contents) {
    final entries = <Record>[];
    for (final line in contents.split('\n')) {
      if (line.trim().isEmpty) {
        continue;
      }
      final record = jsonDecode(line);
      entries.add(record as Record);
    }
    return entries;
  }

  /// Save the log to the file system.
  void save() {
    _fs.file(_path).writeAsStringSync(_entries.map(jsonEncode).join('\n'));
  }

  /// Load the log from the file system.
  static Future<List<R>> load<R>(
    FileSystem fs,
    String path,
  ) async {
    final file = fs.file(path);
    if (await file.exists()) {
      return _parseLogFile<R>(await file.readAsString());
    }
    return <R>[];
  }

  /// Add an entry to the log.
  void log(Record record) {
    _entries.add(record);
    save();
  }
}
