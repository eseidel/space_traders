import 'package:cli/cache/json_store.dart';
import 'package:file/file.dart';
import 'package:types/types.dart';

typedef _Record = Map<ShipSymbol, BehaviorState>;

/// A class to manage the behavior cache.
class BehaviorCache extends JsonStore<_Record> {
  /// Create a new behavior cache.
  BehaviorCache(
    super.stateByShipSymbol, {
    required super.fs,
    super.path = defaultPath,
  }) : super(
          recordToJson: (r) => r.map(
            (key, value) => MapEntry(
              key.toJson(),
              value.toJson(),
            ),
          ),
        );

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
              ShipSymbol.fromJson(key),
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
  Map<ShipSymbol, BehaviorState> get _stateByShipSymbol => record;

  /// Get the list of all behavior states.
  List<BehaviorState> get states => _stateByShipSymbol.values.toList();

  /// Get the behavior state for the given ship.
  BehaviorState? getBehavior(ShipSymbol shipSymbol) =>
      _stateByShipSymbol[shipSymbol];

  /// Delete the behavior state for the given ship.
  void deleteBehavior(ShipSymbol shipSymbol) {
    _stateByShipSymbol.remove(shipSymbol);
    save();
  }

  /// Set the behavior state for the given ship.
  void setBehavior(ShipSymbol shipSymbol, BehaviorState behaviorState) {
    _stateByShipSymbol[shipSymbol] = behaviorState;
    save();
  }

  /// Clear the behavior state for the given ship.
  void completeBehavior(ShipSymbol shipSymbol) {
    _stateByShipSymbol.remove(shipSymbol);
    save();
  }
}
