import 'package:cli/api.dart';
import 'package:cli/cache/response_cache.dart';
import 'package:cli/net/queries.dart';

/// In-memory cache of ships.
// Should this just be called Fleet?
class ShipCache extends ResponseListCache<Ship> {
  /// Creates a new ship cache.
  ShipCache(super.ships, {super.checkEvery = 100})
      : super(
          entryToJson: (s) => s.toJson(),
          refreshEntries: (Api api) => allMyShips(api).toList(),
        );

  /// Creates a new ShipCache from the API.
  static Future<ShipCache> load(Api api) async =>
      ShipCache(await allMyShips(api).toList());

  /// Ships in the cache.
  List<Ship> get ships => entries;

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
