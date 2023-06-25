import 'dart:convert';

import 'package:cli/trading.dart';
import 'package:file/file.dart';

/// Enum to specify which behavior the ship should follow.
enum Behavior {
  /// Go to a shipyard and buy a ship.
  buyShip,

  /// Trade to fulfill the current contract.
  contractTrader,

  /// Trade for profit.
  arbitrageTrader,

  /// Mine asteroids and sell the ore.
  miner,

  /// Idle.
  idle,

  /// Explore the universe.
  explorer;

  /// encode the enum as Json.
  String toJson() => name;

  /// decode the enum from Json.
  static Behavior fromJson(String json) {
    return values.firstWhere((b) => b.name == json);
  }
}

/// Class holding the persistent state for a behavior.
// Want this to be lifetime managed in way such that Behavior's can clear it
// as well as that it's auto-cleaned up if not acknowledged by the behavior
// or on error.
// Also want a way for Behavior's to vote that they should not be the current
// behavior for that ship or ship-type for some timeout.
class BehaviorState {
  /// Create a new behavior state.
  BehaviorState(this.shipSymbol, this.behavior, {this.destination, this.deal});

  /// Create a new behavior state from JSON.
  factory BehaviorState.fromJson(Map<String, dynamic> json) {
    final behavior = Behavior.fromJson(json['behavior'] as String);
    final shipSymbol = json['shipSymbol'] as String;
    final destination = json['destination'] as String?;
    final deal = json['deal'] == null
        ? null
        : CostedDeal.fromJson(json['deal'] as Map<String, dynamic>);
    return BehaviorState(
      shipSymbol,
      behavior,
      destination: destination,
      deal: deal,
    );
  }

  /// The symbol of the ship this state is for.
  final String shipSymbol;

  /// The current behavior.
  final Behavior behavior;

  /// Current navigation destination.
  String? destination;

  /// Current deal.
  CostedDeal? deal;

  /// Convert this to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'behavior': behavior.toJson(),
      'shipSymbol': shipSymbol,
      'destination': destination,
      'deal': deal?.toJson(),
    };
  }
}

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
  static const String defaultPath = 'behaviors.json';

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
    await _fs.file(_path).writeAsString(jsonEncode(_stateByShipSymbol));
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
