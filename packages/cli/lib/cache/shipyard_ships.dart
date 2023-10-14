import 'dart:convert';

import 'package:cli/cache/caches.dart';
import 'package:cli/cache/json_list_store.dart';
import 'package:cli/logger.dart';
import 'package:cli/third_party/compare.dart';
import 'package:collection/collection.dart';

extension on ShipyardShip {
  /// Returns a copy of this ship with the same properties.
  ShipyardShip deepCopy() {
    // ShipyardShip.toJson doesn't recurse (openapi gen bug), so use jsonEncode.
    return ShipyardShip.fromJson(jsonDecode(jsonEncode(toJson())))!;
  }
}

bool _shipyardShipsMatch(ShipyardShip actual, ShipyardShip expected) {
  final diff = findDifferenceBetweenStrings(
    jsonEncode(actual.toJson()),
    jsonEncode(expected.toJson()),
  );
  if (diff != null) {
    logger.info('ShipyardShip differs from expected: ${diff.which}');
    return false;
  }
  return true;
}

/// A cache of shipyard ships.
class ShipyardShipCache extends JsonListStore<ShipyardShip> {
  /// Creates a new shipyard ship cache.
  ShipyardShipCache(
    super.shipyardShips, {
    required super.fs,
    super.path = defaultCacheFilePath,
  });

  /// Loads the shipyard ship cache from the given file system.
  factory ShipyardShipCache.load(
    FileSystem fs, {
    String path = defaultCacheFilePath,
  }) {
    final shipyardShips = JsonListStore.load<ShipyardShip>(
          fs,
          path,
          (Map<String, dynamic> j) => ShipyardShip.fromJson(j)!,
        ) ??
        [];
    return ShipyardShipCache(shipyardShips, fs: fs, path: path);
  }

  /// The default path to the cache file.
  static const String defaultCacheFilePath = 'data/shipyard_ships.json';

  /// Lookup the shipyard ship by its type.
  ShipyardShip? lookup(ShipType type) {
    return entries.firstWhereOrNull((record) => record.type == type);
  }

  /// Adds a shipyard ship to the cache.
  void addShipyardShip(ShipyardShip shipyardShip, {bool shouldSave = true}) {
    final cached = lookup(shipyardShip.type!);

    // Copy the shipyard ship so that we don't mutate the original.
    // Normalize all prices to 0.
    final copy = shipyardShip.deepCopy()..purchasePrice = 0;

    if (cached != null && _shipyardShipsMatch(cached, copy)) {
      return;
    }

    // Remove any existing shipyard ships of the same type.
    // Add the new shipyard ship.
    entries
      ..removeWhere((record) => record.type == copy.type)
      ..add(copy);

    // This is just a minor optimization to allow addShipyardShips to only
    // save once.
    if (shouldSave) {
      save();
    }
  }

  @override
  void save() {
    // Make sure the entries are always sorted by type to avoid needless
    // diffs in the cache.
    entries.sort((a, b) => a.type!.value.compareTo(b.type!.value));
    super.save();
  }

  /// Adds a list of traits to the cache.
  void addShipyardShips(Iterable<ShipyardShip> ships) {
    for (final ship in ships) {
      addShipyardShip(ship, shouldSave: false);
    }
    save();
  }
}
