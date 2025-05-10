import 'package:db/db.dart';
import 'package:types/types.dart';

/// Records ShipyardShips and their components into the caches.
void recordShipyardShips(Database db, List<ShipyardShip> ships) {
  db.shipyardShips.addAll(ships);
  for (final ship in ships) {
    db.shipMounts.addAll(ship.mounts);
    db.shipModules.addAll(ship.modules);
    db.shipEngines.add(ship.engine);
    db.shipReactors.add(ship.reactor);
  }
}

/// Records a Ship's components into the caches.
void recordShip(Database db, Ship ship) {
  db.shipMounts.addAll(ship.mounts);
  db.shipModules.addAll(ship.modules);
  db.shipEngines.add(ship.engine);
  db.shipReactors.add(ship.reactor);
}

/// Log the adverse events in the given [events].
void recordEvents(Database db, Ship ship, List<ShipConditionEvent> events) {
  if (events.isEmpty) {
    return;
  }
  // TODO(eseidel): Queue the ship for update if it had events.
  // Responses containing events don't return the ship parts effected, so
  // we'd need to queue a full update of the ship to get the condition changes.
  db.events.addAll(events);
}
