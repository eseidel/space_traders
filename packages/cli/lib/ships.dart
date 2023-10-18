import 'package:cli/cache/static_cache.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:types/api.dart';

// TODO(eseidel): Move to using StaticCaches.shipyardShips instead.
const _typeFramePairs = [
  (ShipType.PROBE, ShipFrameSymbolEnum.PROBE),
  (ShipType.MINING_DRONE, ShipFrameSymbolEnum.DRONE),
  (ShipType.INTERCEPTOR, ShipFrameSymbolEnum.INTERCEPTOR),
  (ShipType.LIGHT_HAULER, ShipFrameSymbolEnum.LIGHT_FREIGHTER),
  (ShipType.COMMAND_FRIGATE, ShipFrameSymbolEnum.FRIGATE),
  (ShipType.EXPLORER, ShipFrameSymbolEnum.EXPLORER),
  (ShipType.HEAVY_FREIGHTER, ShipFrameSymbolEnum.HEAVY_FREIGHTER),
  (ShipType.LIGHT_SHUTTLE, ShipFrameSymbolEnum.SHUTTLE),
  (ShipType.ORE_HOUND, ShipFrameSymbolEnum.MINER),
  (ShipType.REFINING_FREIGHTER, ShipFrameSymbolEnum.HEAVY_FREIGHTER),
];

/// Map from ship type to ship frame symbol.
ShipType? shipTypeFromFrame(ShipFrameSymbolEnum frameSymbol) {
  ShipType? shipType;
  for (final pair in _typeFramePairs) {
    if (pair.$2 != frameSymbol) {
      continue;
    }
    if (shipType != null) {
      // Multiple frames map to the same ship type.
      return null;
    }
    shipType = pair.$1;
  }
  return shipType;
}

/// Map from ship type to ship frame symbol.
ShipFrameSymbolEnum? shipFrameFromType(ShipType type) {
  for (final pair in _typeFramePairs) {
    if (pair.$1 == type) return pair.$2;
  }
  return null;
}

/// Provides Ship data that ShipyardShip does not.
/// Right now that's only Role, but it could be more in the future.
@immutable
class ShipConfig {
  /// Create a new ship config.
  const ShipConfig({required this.type, required this.role});

  /// ShipType this config is for.
  final ShipType type;

  /// Role for this ship.
  final ShipRole role;
}

const _shipConfigs = [
  ShipConfig(type: ShipType.PROBE, role: ShipRole.SATELLITE),
  ShipConfig(type: ShipType.COMMAND_FRIGATE, role: ShipRole.COMMAND),
];

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

ShipCrew _crewFromShipyardShip(ShipyardShip ship) {
  var current = 0;
  current += ship.frame.requirements.crew ?? 0;
  current += ship.reactor.requirements.crew ?? 0;
  current += ship.engine.requirements.crew ?? 0;
  current += ship.mounts.map((m) => m.requirements.crew ?? 0).sum;
  current += ship.modules.map((m) => m.requirements.crew ?? 0).sum;

  return ShipCrew(
    current: current,
    required_: ship.crew.required_,
    capacity: ship.crew.capacity,
    morale: 100,
    wages: 0,
  );
}

ShipCargo _cargoFromShipyardShip(ShipyardShip ship) {
  // There is only one cargo module for now.
  final cargoModules = [ShipModuleSymbolEnum.CARGO_HOLD_I];
  // Sum up the cargo from modules.
  final cargoCapacity = ship.modules
      .where((m) => cargoModules.contains(m.symbol))
      .map((m) => m.capacity!)
      .sum;

  return ShipCargo(
    capacity: cargoCapacity,
    units: 0,
  );
}

ShipFuel _fuelFromShipyardShip(ShipyardShip ship) {
  return ShipFuel(
    current: ship.frame.fuelCapacity,
    capacity: ship.frame.fuelCapacity,
  );
}

/// Make a new ship of a given type.
@visibleForTesting
Ship? makeShipForTest({
  required StaticCaches caches,
  required ShipType type,
  required ShipSymbol shipSymbol,
  required FactionSymbols factionSymbol,
  required SystemWaypoint origin,
  required DateTime now,
}) {
  final shipyardShip = caches.shipyardShips[type];
  if (shipyardShip == null) return null;

  final config = _shipConfigs.firstWhereOrNull((c) => c.type == type);
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
    crew: _crewFromShipyardShip(shipyardShip),
    frame: shipyardShip.frame,
    reactor: shipyardShip.reactor,
    engine: shipyardShip.engine,
    cargo: _cargoFromShipyardShip(shipyardShip),
    fuel: _fuelFromShipyardShip(shipyardShip),
    modules: shipyardShip.modules,
    mounts: shipyardShip.mounts,
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
