import 'package:cli/api.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/plan/ships.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// Tools to update Ship objects.
extension ShipUpdateUtils on Ship {
  /// Updates the ship's cooldown and nav for the provided [now].
  void updateForServerTime(DateTime now) {
    final expiration = cooldown.expiration;
    if (expiration != null) {
      if (expiration.isBefore(now)) {
        cooldown = Cooldown(
          shipSymbol: cooldown.shipSymbol,
          remainingSeconds: 0,
          totalSeconds: 0,
        );
      } else {
        cooldown = Cooldown(
          shipSymbol: cooldown.shipSymbol,
          // The server seems to round rather than floor?
          remainingSeconds: (expiration.difference(now).inMilliseconds / 1000)
              .round(),
          totalSeconds: cooldown.totalSeconds,
          expiration: expiration,
        );
      }
    }
    if (isInTransit && nav.route.arrival.isBefore(now)) {
      nav.status = ShipNavStatus.IN_ORBIT;
    }
  }
}

/// In-memory cache of ships.
class ShipSnapshot {
  /// Creates a new ship cache.
  ShipSnapshot(Iterable<Ship> ships) : ships = List.of(ships);

  /// Loads the ship cache from the provided [db].
  static Future<ShipSnapshot> load(Database db) async {
    // It's nicer for callers if ships are in sorted order.
    final ships = (await db.allShips()).sortedBy((a) => a.symbol);
    return ShipSnapshot(ships);
  }

  /// Ships in the cache.
  final List<Ship> ships;

  /// Returns a map of ship frame type to count in fleet.
  // TODO(eseidel): Unclear if this is still needed.
  Map<ShipFrameSymbol, int> get frameCounts => countFrames(ships);

  /// Returns the number of ships with the given [frame].
  int countOfFrame(ShipFrameSymbol frame) {
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
  int? countOfType(ShipyardShipSnapshot shipyardShips, ShipType shipType) {
    final shipyardShip = shipyardShips[shipType];
    // If we can't identify the frame, we can't identify the count.
    if (shipyardShip == null) {
      // This should only happen if our shipyard ship cache is missing data.
      return null;
    }

    final frame = shipyardShip.frame.symbol;
    // In the easy case this type is the only one of its frame.
    if (shipType == shipyardShips.shipTypeFromFrame(frame)) {
      return countOfFrame(frame);
    }
    // Otherwise we count up all the ships which match this frame
    // and match the mounts. This breaks in the case of multiple ships with
    // the same frame who have swapped mounts, but it's better than nothing.
    return ships
        .where((s) => matchesShipyardShipMounts(s, shipyardShip))
        .length;
  }

  /// Updates the ships in the cache for the provided [now].
  // This is a bit of a hack, but makes our server checks less noisy.
  void updateForServerTime(DateTime now) {
    for (final ship in ships) {
      ship.updateForServerTime(now);
    }
  }

  /// Returns all ship symbols.
  List<ShipSymbol> get shipSymbols => ships.map((s) => s.symbol).toList();

  /// Returns the ship for the provided ShipSymbol.
  Ship? operator [](ShipSymbol symbol) =>
      ships.firstWhereOrNull((s) => s.symbol == symbol);
}

/// Returns a map of ship frame type to count in fleet.
Map<ShipFrameSymbol, int> countFrames(List<Ship> ships) {
  final frameCounts = <ShipFrameSymbol, int>{};
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
  final frameNames = typeCounts.keys
      .map((t) {
        final name = t.value.substring('FRAME_'.length);
        final fixedCase = name.split('_').map(capitalize).join(' ');
        return '${typeCounts[t]} $fixedCase';
      })
      .join(', ');
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
