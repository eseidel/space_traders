import 'package:cli/api.dart';
import 'package:collection/collection.dart';

/// Keeps track of when we expect to interact with a ship next.
class ShipWaiter {
  final Map<ShipSymbol, DateTime> _waitUntilByShipSymbol = {};
  List<Ship> _latestShips = [];

  void _removeExpiredWaits() {
    final now = DateTime.now();
    final entries = _waitUntilByShipSymbol.entries.toList();
    for (final entry in entries) {
      final symbol = entry.key;
      final waitUntil = entry.value;
      if (waitUntil.isBefore(now)) {
        _waitUntilByShipSymbol.remove(symbol);
      }
    }
  }

  void _removeUnknownShips() {
    final entries = _waitUntilByShipSymbol.entries.toList();
    for (final entry in entries) {
      final symbol = entry.key;
      final ship =
          _latestShips.firstWhereOrNull((s) => s.symbol == symbol.symbol);
      if (ship == null) {
        _waitUntilByShipSymbol.remove(symbol);
      }
    }
  }

  /// Updates the list of ships we know about.
  void updateForShips(List<Ship> ships) {
    _latestShips = ships;
    _removeUnknownShips();
    _removeExpiredWaits();
  }

  /// Updates the wait time for a ship.
  void updateWaitUntil(ShipSymbol shipSymbol, DateTime? waitUntil) {
    if (waitUntil == null) {
      _waitUntilByShipSymbol.remove(shipSymbol);
    } else {
      _waitUntilByShipSymbol[shipSymbol] = waitUntil;
    }
  }

  /// Returns the wait time for a ship.
  DateTime? waitUntil(ShipSymbol shipSymbol) {
    return _waitUntilByShipSymbol[shipSymbol];
  }

  /// Returns the earliest wait time for any ship.
  /// Returns null to mean no wait.
  DateTime? earliestWaitUntil() {
    if (_waitUntilByShipSymbol.isEmpty) {
      return null;
    }
    // At least one ship might be ready.
    if (_waitUntilByShipSymbol.length < _latestShips.length) {
      return null;
    }
    final nextEventTimes = _waitUntilByShipSymbol.values;
    // This could also check against "now" to avoid waiting?
    return nextEventTimes.reduce((a, b) => a.isBefore(b) ? a : b);
  }
}
