import 'dart:convert';

import 'package:cli/api.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/third_party/compare.dart';

bool _shipListsMatch(List<Ship> actual, List<Ship> expected) {
  if (actual.length != expected.length) {
    logger.info(
      "Ship list lengths don't match: ${actual.length} != ${expected.length}",
    );
    return false;
  }

  for (var i = 0; i < actual.length; i++) {
    final diff = findDifferenceBetweenStrings(
      jsonEncode(actual[i].toJson()),
      jsonEncode(expected[i].toJson()),
    );
    if (diff != null) {
      logger.info('Ship list differs at index $i: ${diff.which}');
      return false;
    }
  }
  return true;
}

/// In-memory cache of ships.
// Should this just be called Fleet?
class ShipCache {
  /// Creates a new ship cache.
  ShipCache(this.ships, {this.requestsBetweenChecks = 100});

  /// Creates a new ShipCache from the API.
  static Future<ShipCache> load(Api api) async =>
      ShipCache(await allMyShips(api).toList());

  /// Ships in the cache.
  final List<Ship> ships;

  /// Number of requests between checks to ensure ships are up to date.
  final int requestsBetweenChecks;

  int _requestsSinceLastCheck = 0;

  /// Ensures the ships in the cache are up to date.
  Future<void> ensureShipsUpToDate(Api api) async {
    _requestsSinceLastCheck++;
    if (_requestsSinceLastCheck < requestsBetweenChecks) {
      return;
    }
    final newShips = await allMyShips(api).toList();
    _requestsSinceLastCheck = 0;
    // This check races with the code in continueNavigationIfNeeded which
    // knows how to update the ShipNavStatus from IN_TRANSIT to IN_ORBIT when
    // a ship has arrived.  We could add some special logic here to ignore
    // that false positive.  This check is called at the top of every loop
    // and might notice that a ship has arrived before the ship logic gets
    // to run and update the status.
    if (_shipListsMatch(ships, newShips)) {
      return;
    }
    logger.warn('Ship list changed, updating cache.');
    updateShips(newShips);
  }

  /// Updates the ships in the cache.
  void updateShips(List<Ship> newShips) {
    ships
      ..clear()
      ..addAll(newShips);
  }

  /// Updates a single ship in the cache.
  void updateShip(Ship ship) {
    final index = ships.indexWhere((s) => s.symbol == ship.symbol);
    if (index == -1) {
      ships.add(ship);
    } else {
      ships[index] = ship;
    }
  }

  /// Returns a map of ship frame type to count in fleet.
  Map<ShipFrameSymbolEnum, int> get frameCounts {
    final typeCounts = <ShipFrameSymbolEnum, int>{};
    for (final ship in ships) {
      final type = ship.frame.symbol;
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }
    return typeCounts;
  }

  /// Returns all ship symbols.
  List<String> get shipSymbols => ships.map((s) => s.symbol).toList();

  /// Currently assumes ships can never be removed from the cache.
  Ship ship(String symbol) => ships.firstWhere((s) => s.symbol == symbol);
}

/// Return a string describing the given [shipCache]. p
String describeFleet(ShipCache shipCache) {
  String capitalize(String s) =>
      s[0].toUpperCase() + s.substring(1).toLowerCase();

  final typeCounts = shipCache.frameCounts;
  final frameNames = typeCounts.keys.map((t) {
    final name = t.value.substring('FRAME_'.length);
    final fixedCase = name.split('_').map(capitalize).join(' ');
    return '${typeCounts[t]} $fixedCase';
  }).join(', ');
  return 'Fleet: $frameNames';
}
