import 'package:cli/api.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/ships.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// In-memory cache of ships.
class ShipSnapshot {
  /// Creates a new ship cache.
  ShipSnapshot(Iterable<Ship> ships) : ships = List.of(ships);

  /// Loads the ship cache from the provided [db].
  static Future<ShipSnapshot> load(Database db) async {
    // It's nicer for callers if ships are in sorted order.
    final ships = (await db.allShips())
        .sorted((a, b) => a.shipSymbol.compareTo(b.shipSymbol));
    return ShipSnapshot(ships);
  }

  /// Ships in the cache.
  final List<Ship> ships;

  /// Returns a map of ship frame type to count in fleet.
  // TODO(eseidel): Unclear if this is still needed.
  Map<ShipFrameSymbolEnum, int> get frameCounts => countFrames(ships);

  /// Returns the number of ships with the given [frame].
  int countOfFrame(ShipFrameSymbolEnum frame) {
    // Frame is always a valid way to look up a ship, so null means 0 here.
    return countFrames(ships)[frame] ?? 0;
  }

  /// Returns true if the given [ship] matches the given [shipyardShip].
  static bool matchesShipyardShipMounts(Ship ship, ShipyardShip shipyardShip) {
    if (ship.frame.symbol != shipyardShip.frame.symbol) {
      return false;
    }
    return ShipTemplate.mountsSymbolSetEquals(
      ship.mountedMountSymbols,
      shipyardShip.mountedMountSymbols,
    );
  }

  /// Returns the number of ships with the given [shipType].
  int? countOfType(ShipyardShipCache shipyardShips, ShipType shipType) {
    final frame = shipyardShips.shipFrameFromType(shipType);
    // If we can't identify the frame, we can't identify the count.
    if (frame == null) {
      // This should only happen if our shipyard ship cache is missing data.
      return null;
    }
    // In the easy case this type is the only one of its frame.
    if (shipType == shipyardShips.shipTypeFromFrame(frame)) {
      return countOfFrame(frame);
    }
    // Otherwise we count up all the ships which match this frame
    // and match the mounts. This breaks in the case of multiple ships with
    // the same frame who have swapped mounts, but it's better than nothing.
    final shipyardShip = shipyardShips[shipType];
    if (shipyardShip == null) {
      // This should only happen if our ShipyardShipCache is missing data.
      return null;
    }
    return ships
        .where((s) => matchesShipyardShipMounts(s, shipyardShip))
        .length;
  }

  /// Returns all ship symbols.
  List<ShipSymbol> get shipSymbols => ships.map((s) => s.shipSymbol).toList();

  /// Returns the ship for the provided ShipSymbol.
  Ship operator [](ShipSymbol symbol) =>
      ships.firstWhere((s) => s.shipSymbol == symbol);
}

/// Returns a map of ship frame type to count in fleet.
Map<ShipFrameSymbolEnum, int> countFrames(List<Ship> ships) {
  final frameCounts = <ShipFrameSymbolEnum, int>{};
  for (final ship in ships) {
    final type = ship.frame.symbol;
    frameCounts[type] = (frameCounts[type] ?? 0) + 1;
  }
  return frameCounts;
}

/// Return a string describing the provided list of ships.
String describeShips(List<Ship> ships) {
  String capitalize(String s) =>
      s[0].toUpperCase() + s.substring(1).toLowerCase();

  final typeCounts = countFrames(ships);
  final frameNames = typeCounts.keys.map((t) {
    final name = t.value.substring('FRAME_'.length);
    final fixedCase = name.split('_').map(capitalize).join(' ');
    return '${typeCounts[t]} $fixedCase';
  }).join(', ');
  if (frameNames.isEmpty) {
    return '0 ships';
  }
  return frameNames;
}

/// Creates a new ShipCache from the Api or FileSystem if provided.
Future<ShipSnapshot> fetchShips(Database db, Api api) async {
  final ships = await allMyShips(api).toList();
  for (final ship in ships) {
    await db.upsertShip(ship);
  }
  return ShipSnapshot(ships);
}
