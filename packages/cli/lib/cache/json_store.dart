import 'dart:convert';

import 'package:file/file.dart';
import 'package:meta/meta.dart';

/// A class to manage a file containing a json object.
/// The resulting file is valid json.
class JsonStore<MapType> {
  /// Create a new JsonStore.
  JsonStore(
    this.map, {
    required FileSystem fs,
    required String path,
  })  : _fs = fs,
        _path = path;

  /// The root object of the store.
  @protected
  final MapType map;

  final String _path;

  /// The file system to use.
  final FileSystem _fs;

  static MapType _parseMap<MapType>(
    String contents,
    MapType Function(Map<String, dynamic>) recordFromJson,
  ) {
    final parsed = jsonDecode(contents) as Map<String, dynamic>;
    return recordFromJson(parsed);
  }

  /// Save entries to a file.
  Future<void> save() async {
    final file = _fs.file(_path);
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(map));
  }

  /// Load entries from a file.
  static MapType? load<MapType>(
    FileSystem fs,
    String path,
    MapType Function(Map<String, dynamic>) recordFromJson,
  ) {
    final file = fs.file(path);
    if (file.existsSync()) {
      return _parseMap<MapType>(file.readAsStringSync(), recordFromJson);
    }
    return null;
  }
}
