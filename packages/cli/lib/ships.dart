import 'package:cli/cache/static_cache.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:types/api.dart';

/// Map from ship type to ship frame symbol.
extension ShipTypeToFrame on ShipyardShipCache {
  /// Map from ship type to ship frame symbol.
  ShipType? shipTypeFromFrame(ShipFrameSymbolEnum frameSymbol) {
    ShipType? shipType;
    for (final ship in values) {
      if (ship.frame.symbol != frameSymbol) {
        continue;
      }
      if (shipType != null) {
        // Multiple frames map to the same ship type.
        return null;
      }
      shipType = ship.type;
    }
    return shipType;
  }

  /// Map from ship type to ship frame symbol.
  ShipFrameSymbolEnum? shipFrameFromType(ShipType type) {
    return this[type]?.frame.symbol;
  }

  /// Make a new ship of a given type.
  @visibleForTesting
  Ship? shipForTest(
    ShipType shipType, {
    ShipSymbol? shipSymbol,
    FactionSymbols? factionSymbol,
    SystemWaypoint? origin,
    DateTime? now,
  }) {
    final symbolString = shipSymbol?.symbol ?? 'S-1';
    final factionString = factionSymbol?.value ?? 'COSMIC';
    final waypoint = origin ??
        SystemWaypoint(
          symbol: 'A-B-C',
          type: WaypointType.PLANET,
          x: 0,
          y: 0,
        );
    final arrival = now ?? DateTime.utc(2021);

    final shipyardShip = this[shipType];
    if (shipyardShip == null) return null;

    final config = _shipConfigs.firstWhereOrNull((c) => c.type == shipType);
    if (config == null) return null;

    return Ship(
      symbol: symbolString,
      registration: ShipRegistration(
        factionSymbol: factionString,
        name: symbolString,
        role: config.role,
      ),
      cooldown: Cooldown(
        shipSymbol: symbolString,
        remainingSeconds: 0,
        totalSeconds: 0,
      ),
      nav: _makeShipNav(origin: waypoint, now: arrival),
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
}

/// Provides Ship data that ShipyardShip does not.
/// Right now that's only Role, but it could be more in the future.
@immutable
class _ShipConfig {
  /// Create a new ship config.
  const _ShipConfig({required this.type, required this.role});

  /// ShipType this config is for.
  final ShipType type;

  /// Role for this ship.
  final ShipRole role;
}

const _shipConfigs = [
  _ShipConfig(type: ShipType.PROBE, role: ShipRole.SATELLITE),
  _ShipConfig(type: ShipType.MINING_DRONE, role: ShipRole.EXCAVATOR),
  _ShipConfig(type: ShipType.INTERCEPTOR, role: ShipRole.INTERCEPTOR),
  _ShipConfig(type: ShipType.LIGHT_HAULER, role: ShipRole.HAULER),
  _ShipConfig(type: ShipType.COMMAND_FRIGATE, role: ShipRole.COMMAND),
  _ShipConfig(type: ShipType.EXPLORER, role: ShipRole.EXPLORER),
  _ShipConfig(type: ShipType.HEAVY_FREIGHTER, role: ShipRole.HAULER),
  _ShipConfig(type: ShipType.LIGHT_SHUTTLE, role: ShipRole.TRANSPORT),
  _ShipConfig(type: ShipType.ORE_HOUND, role: ShipRole.EXCAVATOR),
  _ShipConfig(type: ShipType.REFINING_FREIGHTER, role: ShipRole.REFINERY),
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
