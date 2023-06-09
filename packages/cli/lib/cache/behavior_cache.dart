import 'package:cli/behavior/behavior.dart';
import 'package:cli/cache/json_store.dart';
import 'package:file/file.dart';

typedef _Record = Map<String, BehaviorState>;

/// A class to manage the behavior cache.
class BehaviorCache extends JsonStore<_Record> {
  /// Create a new behavior cache.
  BehaviorCache(
    super.stateByShipSymbol, {
    required super.fs,
    super.path = defaultPath,
  });

  /// Load the cache from a file.
  factory BehaviorCache.load(
    FileSystem fs, {
    String path = defaultPath,
  }) {
    final record = JsonStore.load<_Record>(
          fs,
          path,
          (Map<String, dynamic> j) => j.map(
            (key, value) => MapEntry(
              key,
              BehaviorState.fromJson(value as Map<String, dynamic>),
            ),
          ),
        ) ??
        {};
    return BehaviorCache(record, fs: fs, path: path);
  }

  /// The default path to the cache file.
  static const String defaultPath = 'data/behaviors.json';

  /// The behavior state for each ship.
  Map<String, BehaviorState> get _stateByShipSymbol => record;

  /// Get the list of all behavior states.
  List<BehaviorState> get states => _stateByShipSymbol.values.toList();

  /// Get the behavior state for the given ship.
  BehaviorState? getBehavior(String shipSymbol) =>
      _stateByShipSymbol[shipSymbol];

  /// Delete the behavior state for the given ship.
  void deleteBehavior(String shipSymbol) {
    _stateByShipSymbol.remove(shipSymbol);
    save();
  }

  /// Set the behavior state for the given ship.
  void setBehavior(
    String shipSymbol,
    BehaviorState behaviorState,
  ) {
    _stateByShipSymbol[shipSymbol] = behaviorState;
    save();
  }

  /// Clear the behavior state for the given ship.
  void completeBehavior(String shipSymbol) {
    _stateByShipSymbol.remove(shipSymbol);
    save();
  }
}
