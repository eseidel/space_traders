import 'package:cli/logger.dart';
import 'package:collection/collection.dart';
import 'package:types/types.dart';

/// A ship that is waiting to be processed.
class ShipWaiterEntry {
  /// Creates a new ship waiter entry.
  ShipWaiterEntry(this.shipSymbol, this.waitUntil);

  /// The ship symbol.
  final ShipSymbol shipSymbol;

  /// The time to wait until.
  final DateTime? waitUntil;
}

// Elements which compare less have higher priority.
// null sorts first (highest priority).
// Otherwise sorts by waitUntil with sooner times having higher priority.
int _compareEntries(ShipWaiterEntry a, ShipWaiterEntry b) {
  if (a.waitUntil == null) {
    return -1;
  }
  if (b.waitUntil == null) {
    return 1;
  }
  return a.waitUntil!.compareTo(b.waitUntil!);
}

/// Keeps track of when we expect to interact with a ship next.
class ShipWaiter {
  final _queue = PriorityQueue<ShipWaiterEntry>(_compareEntries);

  /// Schedules any ships that are missing.
  void scheduleMissingShips(List<Ship> ships, {bool suppressWarnings = false}) {
    // Get the set of existing ships we've scheduled.
    // schedule any missing.
    final existing = _queue.toUnorderedList().map((e) => e.shipSymbol).toSet();
    for (final ship in ships) {
      if (!existing.contains(ship.shipSymbol)) {
        if (!suppressWarnings) {
          logger.warn('Adding missing ship ${ship.shipSymbol}');
        }
        scheduleShip(ship.shipSymbol, null);
      }
    }
  }

  /// Updates the wait time for a ship.
  void scheduleShip(ShipSymbol shipSymbol, DateTime? waitUntil) {
    _queue.add(ShipWaiterEntry(shipSymbol, waitUntil));
  }

  /// Returns the next ship to be processed.
  ShipWaiterEntry nextShip() => _queue.removeFirst();

  /// Returns a list of ShipSymbols that have been waiting too long.
  Iterable<ShipSymbol> starvedShips(DateTime starvationThreshold) sync* {
    for (final entry in _queue.toUnorderedList()) {
      if (entry.waitUntil != null &&
          entry.waitUntil!.isBefore(starvationThreshold)) {
        yield entry.shipSymbol;
      }
    }
  }
}
