import 'dart:convert';

import 'package:cli/behavior/behavior.dart';
import 'package:file/file.dart';

/// A class to manage the behavior cache.
class BehaviorCache {
  /// Create a new behavior cache.
  BehaviorCache(
    Map<String, BehaviorState> stateByShipSymbol, {
    required FileSystem fs,
    String path = defaultPath,
  })  : _stateByShipSymbol = stateByShipSymbol,
        _fs = fs,
        _path = path;

  /// The default path to the cache file.
  static const String defaultPath = 'data/behaviors.json';

  /// The behavior state for each ship.
  final Map<String, BehaviorState> _stateByShipSymbol;

  /// The path to the cache file.
  final String _path;

  /// The file system to use.
  final FileSystem _fs;

  /// Get the list of all behavior states.
  List<BehaviorState> get states => _stateByShipSymbol.values.toList();

  /// Save entries to a file.
  Future<void> save() async {
    const encoder = JsonEncoder.withIndent(' ');
    final prettyprint = encoder.convert(_stateByShipSymbol);
    final file = _fs.file(_path);
    await file.create(recursive: true);
    await file.writeAsString(prettyprint);
  }

  /// Load the cache from a file.
  static Future<BehaviorCache> load(
    FileSystem fs, {
    String path = defaultPath,
  }) async {
    final file = fs.file(path);
    if (await file.exists()) {
      final jsonMap =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final behaviorStates = jsonMap.map<String, BehaviorState>(
        (key, value) => MapEntry(
          key,
          BehaviorState.fromJson(value as Map<String, dynamic>),
        ),
      );
      return BehaviorCache(behaviorStates, fs: fs, path: path);
    }
    return BehaviorCache({}, fs: fs, path: path);
  }

  /// Get the behavior state for the given ship.
  BehaviorState? getBehavior(String shipSymbol) =>
      _stateByShipSymbol[shipSymbol];

  /// Delete the behavior state for the given ship.
  Future<void> deleteBehavior(String shipSymbol) async =>
      _stateByShipSymbol.remove(shipSymbol);

  /// Set the behavior state for the given ship.
  Future<void> setBehavior(
    String shipSymbol,
    BehaviorState behaviorState,
  ) async {
    _stateByShipSymbol[shipSymbol] = behaviorState;
    await save();
  }

  /// Clear the behavior state for the given ship.
  Future<void> completeBehavior(String shipSymbol) async {
    _stateByShipSymbol.remove(shipSymbol);
    await save();
  }
}
