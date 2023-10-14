import 'package:meta/meta.dart';
import 'package:types/api.dart';

ShipNav _makeShipNav({required SystemWaypoint origin, required DateTime now}) {
  final originSymbol = origin.waypointSymbol;
  final waypoint = ShipNavRouteWaypoint(
    symbol: originSymbol.waypoint,
    systemSymbol: originSymbol.system,
    type: origin.type,
    x: origin.x,
    y: origin.y,
  );

  return ShipNav(
    systemSymbol: originSymbol.system,
    waypointSymbol: originSymbol.waypoint,
    route: ShipNavRoute(
      destination: waypoint,
      origin: waypoint,
      departure: waypoint,
      arrival: now,
      departureTime: now,
    ),
    status: ShipNavStatus.DOCKED,
    flightMode: ShipNavFlightMode.CRUISE,
  );
}

/// Make a new ship of a given type.
@visibleForTesting
Ship? makeShipForTest({
  required ShipType type,
  required ShipSymbol shipSymbol,
  required FactionSymbols factionSymbol,
  required SystemWaypoint origin,
  required DateTime now,
}) {
  final config = shipConfigForType(type);
  if (config == null) return null;

  return Ship(
    symbol: shipSymbol.symbol,
    registration: ShipRegistration(
      factionSymbol: factionSymbol.value,
      name: shipSymbol.symbol,
      role: config.role,
    ),
    cooldown: Cooldown(
      shipSymbol: shipSymbol.symbol,
      remainingSeconds: 0,
      totalSeconds: 0,
    ),
    nav: _makeShipNav(origin: origin, now: now),
    crew: config.crew,
    frame: config.frame,
    reactor: config.reactor,
    engine: config.engine,
    cargo: ShipCargo(capacity: config.cargoCapacity, units: 0),
    fuel: ShipFuel(capacity: config.fuelCapacity, current: config.fuelCapacity),
  );
}

/// Make an example ShipMount for a given mount symbol.
ShipMount makeMount(ShipMountSymbolEnum mountSymbol) {
  return ShipMount(
    symbol: mountSymbol,
    name: mountSymbol.value,
    description: mountSymbol.value,
    requirements: ShipRequirements(crew: 0),
  );
}

/// Make an example ShipModule for a given module symbol.
ShipModule makeModule(ShipModuleSymbolEnum moduleSymbol) {
  return ShipModule(
    symbol: moduleSymbol,
    name: moduleSymbol.value,
    description: moduleSymbol.value,
    requirements: ShipRequirements(crew: 0),
  );
}

/// Make Ship for comparison with an existing ship.
/// Uses the volatile parts of the existing ship, and the template for the
/// ship type to avoid needless differences.
Ship? makeShipForComparison({
  required ShipType type,
  required ShipSymbol shipSymbol,
  required FactionSymbols factionSymbol,
  required ShipNav nav,
  required ShipFuel fuel,
  required ShipCargo cargo,
  required Cooldown cooldown,
  required List<ShipModuleSymbolEnum> moduleSymbols,
  required List<ShipMountSymbolEnum> mountSymbols,
}) {
  final config = shipConfigForType(type);
  if (config == null) return null;

  return Ship(
    symbol: shipSymbol.symbol,
    registration: ShipRegistration(
      factionSymbol: factionSymbol.value,
      name: shipSymbol.symbol,
      role: config.role,
    ),
    cooldown: cooldown,
    nav: nav,
    crew: config.crew,
    frame: config.frame,
    reactor: config.reactor,
    engine: config.engine,
    cargo: cargo,
    fuel: fuel,
    modules: moduleSymbols.map(makeModule).toList(),
    mounts: mountSymbols.map(makeMount).toList(),
  );
}
