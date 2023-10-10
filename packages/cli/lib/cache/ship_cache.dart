import 'package:cli/api.dart';
import 'package:cli/cache/json_list_store.dart';
import 'package:cli/cache/response_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/queries.dart';
import 'package:file/file.dart';
import 'package:types/types.dart';

/// In-memory cache of ships.
// Should this just be called Fleet?
class ShipCache extends ResponseListCache<Ship> {
  /// Creates a new ship cache.
  ShipCache(
    super.ships, {
    required super.fs,
    super.checkEvery = 100,
    super.path = defaultPath,
  }) : super(
          entryToJson: (s) => s.toJson(),
          refreshEntries: (Api api) => allMyShips(api).toList(),
        );

  /// Loads a ShipCache from cache if it exists.
  static ShipCache? loadCached(
    FileSystem fs, {
    String path = defaultPath,
  }) {
    final ships = JsonListStore.load<Ship>(
      fs,
      path,
      (j) => Ship.fromJson(j)!,
    );
    if (ships != null) {
      return ShipCache(ships, fs: fs, path: path);
    }
    return null;
  }

  /// Creates a new ShipCache from the Api or FileSystem if provided.
  static Future<ShipCache> load(
    Api api, {
    required FileSystem fs,
    String path = defaultPath,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = loadCached(fs, path: path);
      if (cached != null) {
        return cached;
      }
    }
    final ships = await allMyShips(api).toList();
    return ShipCache(ships, fs: fs, path: path);
  }

  /// The default path to the contracts cache.
  static const String defaultPath = 'data/ships.json';

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
    save();
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

  /// Returns the number of ships of the given [shipType] in the fleet.
  int countOfType(ShipType shipType) {
    final frameForType = {
      ShipType.ORE_HOUND: ShipFrameSymbolEnum.MINER,
      ShipType.PROBE: ShipFrameSymbolEnum.PROBE,
      ShipType.LIGHT_HAULER: ShipFrameSymbolEnum.LIGHT_FREIGHTER,
      ShipType.HEAVY_FREIGHTER: ShipFrameSymbolEnum.HEAVY_FREIGHTER,
      ShipType.MINING_DRONE: ShipFrameSymbolEnum.DRONE,
    }[shipType];
    if (frameForType == null) {
      logger.err('Unknown frame mapping for type: $shipType');
    }
    return frameCounts[frameForType] ?? 0;
  }

  /// Returns all ship symbols.
  List<ShipSymbol> get shipSymbols => ships.map((s) => s.shipSymbol).toList();

  /// Currently assumes ships can never be removed from the cache.
  Ship ship(ShipSymbol symbol) =>
      ships.firstWhere((s) => s.shipSymbol == symbol);
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
  if (frameNames.isEmpty) {
    return 'Fleet: 0 ships';
  }
  return 'Fleet: $frameNames';
}
