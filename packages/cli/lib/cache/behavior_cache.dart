import 'package:cli/cache/json_store.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:types/types.dart';

typedef _Record = Map<ShipSymbol, BehaviorState>;

@immutable
class _ShipTimeout {
  const _ShipTimeout(this.shipSymbol, this.behavior, this.timeout);

  final ShipSymbol shipSymbol;
  final Behavior behavior;
  final DateTime timeout;
}

/// A class to manage the behavior cache.
class BehaviorCache extends JsonStore<_Record> {
  /// Create a new behavior cache.
  BehaviorCache(
    super.stateByShipSymbol, {
    required super.fs,
    super.path = defaultPath,
  }) : super(
          recordToJson: (_Record r) => r.map(
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
    final record = JsonStore.loadRecord<_Record>(
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

  /// Used for temporarily disabling a ship, not persisted.
  final List<_ShipTimeout> _shipTimeouts = [];

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

  /// Check if the given behavior is disabled for the given ship.
  bool isBehaviorDisabledForShip(Ship ship, Behavior behavior) {
    bool matches(_ShipTimeout timeout) {
      return timeout.shipSymbol == ship.shipSymbol &&
          timeout.behavior == behavior;
    }

    final timeouts = _shipTimeouts.where(matches).toList();
    if (timeouts.isEmpty) {
      return false;
    }
    final expiration = timeouts.first.timeout;
    if (DateTime.timestamp().isAfter(expiration)) {
      _shipTimeouts.removeWhere(matches);
      return false;
    }
    return true;
  }

  /// Disable the given behavior for [ship] for [duration].
  void disableBehaviorForShip(Ship ship, String why, Duration duration) {
    final shipSymbol = ship.shipSymbol;
    final currentState = getBehavior(shipSymbol);
    final behavior = currentState?.behavior;
    if (behavior == null) {
      shipWarn(ship, '$shipSymbol has no behavior to disable.');
      return;
    }
    shipWarn(
      ship,
      '$why Disabling $behavior for $shipSymbol '
      'for ${approximateDuration(duration)}.',
    );

    if (currentState == null || currentState.behavior == behavior) {
      deleteBehavior(shipSymbol);
    } else {
      shipInfo(ship, 'Not deleting ${currentState.behavior} for $shipSymbol.');
    }

    final expiration = DateTime.timestamp().add(duration);
    _shipTimeouts.add(_ShipTimeout(ship.shipSymbol, behavior, expiration));
  }

  /// Get the behavior state for the given ship, or call [ifAbsent] to create it
  /// if it doesn't exist.
  Future<BehaviorState> putIfAbsent(
    ShipSymbol shipSymbol,
    Future<BehaviorState> Function() ifAbsent,
  ) async {
    final currentState = getBehavior(shipSymbol);
    if (currentState != null) {
      return currentState;
    }
    final newState = await ifAbsent();
    setBehavior(shipSymbol, newState);
    return newState;
  }
}
