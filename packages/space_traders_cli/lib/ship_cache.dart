import 'package:space_traders_api/api.dart';

/// In-memory cache of ships.
class ShipCache {
  /// Creates a new ship cache.
  ShipCache(this.ships);

  /// Ships in the cache.
  final List<Ship> ships;

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

  /// Returns all ship symbols.
  List<String> get shipSymbols => ships.map((s) => s.symbol).toList();

  /// Currently assumes ships can never be removed from the cache.
  Ship ship(String symbol) => ships.firstWhere((s) => s.symbol == symbol);
}
