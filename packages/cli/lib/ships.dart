import 'package:cli/cache/static_cache.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:types/types.dart';

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

  /// Map from ship type to cargo capacity.
  int? capacityForShipType(ShipType shipType) => this[shipType]?.cargoCapacity;

  /// Make a new ship of a given type.
  Ship? shipForTest(
    ShipType shipType, {
    ShipSymbol? shipSymbol,
    FactionSymbol? factionSymbol,
    SystemWaypoint? origin,
    DateTime? now,
  }) {
    final symbolString = shipSymbol?.symbol ?? 'S-1';
    final factionString = factionSymbol?.value ?? 'COSMIC';
    final waypointSymbol = origin?.symbol ?? WaypointSymbol.fromString('A-B-C');
    final waypoint = origin ??
        SystemWaypoint(
          symbol: waypointSymbol,
          type: WaypointType.PLANET,
          position: WaypointPosition(0, 0, waypointSymbol.system),
        );
    final arrival = now ?? DateTime.utc(2021);

    final shipyardShip = this[shipType];
    if (shipyardShip == null) return null;

    final config = _shipConfigs.firstWhereOrNull((c) => c.type == shipType);
    if (config == null) return null;

    // Use deepCopy to ensure callers don't accidentally modify static data.
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
      crew: ShipCrew(
        current: shipyardShip.currentCrew,
        required_: shipyardShip.crew.required_,
        capacity: shipyardShip.crew.capacity,
        morale: 100,
        wages: 0,
      ),
      frame: shipyardShip.frame,
      reactor: shipyardShip.reactor,
      engine: shipyardShip.engine,
      cargo: ShipCargo(capacity: shipyardShip.cargoCapacity, units: 0),
      fuel: ShipFuel(
        current: shipyardShip.frame.fuelCapacity,
        capacity: shipyardShip.frame.fuelCapacity,
      ),
      modules: shipyardShip.modules,
      mounts: shipyardShip.mounts,
    ).deepCopy();
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
  final originSymbol = origin.symbol;
  final waypoint = ShipNavRouteWaypoint(
    symbol: originSymbol.waypoint,
    systemSymbol: originSymbol.systemString,
    type: origin.type,
    x: origin.position.x,
    y: origin.position.y,
  );

  return ShipNav(
    systemSymbol: originSymbol.systemString,
    waypointSymbol: originSymbol.waypoint,
    route: ShipNavRoute(
      destination: waypoint,
      origin: waypoint,
      arrival: now,
      departureTime: now,
    ),
    status: ShipNavStatus.DOCKED,
    flightMode: ShipNavFlightMode.CRUISE,
  );
}
