import 'package:meta/meta.dart';
import 'package:types/api.dart';

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

class _FrameConfig {
  const _FrameConfig({
    required this.frameSymbol,
    required this.name,
    required this.description,
    required this.requirements,
    required this.moduleSlots,
    required this.mountingPoints,
  });
  final ShipFrameSymbolEnum frameSymbol;
  final String name;
  final String description;
  final ShipRequirements requirements;
  final int moduleSlots;
  final int mountingPoints;
}

final _frameConfigs = [
  _FrameConfig(
    frameSymbol: ShipFrameSymbolEnum.PROBE,
    name: 'Frame Probe',
    description:
        'A small, unmanned spacecraft used for exploration, reconnaissance, '
        'and scientific research.',
    requirements: ShipRequirements(crew: 0, power: 1),
    moduleSlots: 0,
    mountingPoints: 0,
  ),
  _FrameConfig(
    frameSymbol: ShipFrameSymbolEnum.FRIGATE,
    name: 'Frame Frigate',
    description:
        'A medium-sized, multi-purpose spacecraft, often used for combat, '
        'transport, or support operations.',
    requirements: ShipRequirements(crew: 25, power: 8),
    moduleSlots: 8,
    mountingPoints: 5,
  ),
];

_FrameConfig? _frameConfigForFrameSymbol(ShipFrameSymbolEnum frameSymbol) {
  for (final config in _frameConfigs) {
    if (config.frameSymbol == frameSymbol) return config;
  }
  return null;
}

class _ReactorConfig {
  const _ReactorConfig({
    required this.reactorSymbol,
    required this.name,
    required this.description,
    required this.powerOutput,
    required this.requirements,
  });
  final ShipReactorSymbolEnum reactorSymbol;
  final String name;
  final String description;
  final int powerOutput;
  final ShipRequirements requirements;
}

final _reactorConfigs = [
  _ReactorConfig(
    reactorSymbol: ShipReactorSymbolEnum.SOLAR_I,
    name: 'Solar Reactor I',
    description:
        'A basic solar power reactor, used to generate electricity from '
        'solar energy.',
    powerOutput: 3,
    requirements: ShipRequirements(crew: 0),
  ),
  _ReactorConfig(
    reactorSymbol: ShipReactorSymbolEnum.FISSION_I,
    name: 'Fission Reactor I',
    description:
        'A basic fission power reactor, used to generate electricity from '
        'nuclear fission reactions.',
    powerOutput: 31,
    requirements: ShipRequirements(crew: 8),
  ),
];

_ReactorConfig? _reactorConfigForReactorSymbol(
  ShipReactorSymbolEnum reactorSymbol,
) {
  for (final config in _reactorConfigs) {
    if (config.reactorSymbol == reactorSymbol) return config;
  }
  return null;
}

class _EngineConfig {
  const _EngineConfig({
    required this.engineSymbol,
    required this.name,
    required this.description,
    required this.speed,
    required this.requirements,
  });
  final ShipEngineSymbolEnum engineSymbol;
  final String name;
  final String description;
  final int speed;
  final ShipRequirements requirements;
}

final _engineConfigs = [
  _EngineConfig(
    engineSymbol: ShipEngineSymbolEnum.IMPULSE_DRIVE_I,
    name: 'Impulse Drive I',
    description:
        'A basic low-energy propulsion system that generates thrust for '
        'interplanetary travel.',
    speed: 2,
    requirements: ShipRequirements(crew: 0, power: 1),
  ),
  _EngineConfig(
    engineSymbol: ShipEngineSymbolEnum.ION_DRIVE_II,
    name: 'Ion Drive II',
    description: 'An advanced propulsion system that uses ionized particles to '
        'generate high-speed, low-thrust acceleration, with improved '
        'efficiency and performance.',
    speed: 30,
    requirements: ShipRequirements(crew: 8, power: 6),
  ),
];

_EngineConfig? _engineConfigForEngineSymbol(
  ShipEngineSymbolEnum engineSymbol,
) {
  for (final config in _engineConfigs) {
    if (config.engineSymbol == engineSymbol) return config;
  }
  return null;
}

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

/// Template for making a new ship of a given type.
@immutable
class ShipConfig {
  /// Create a new ship config.
  const ShipConfig({
    required this.type,
    required this.frameSymbol,
    required this.role,
    required this.reactorSymbol,
    required this.engineSymbol,
    required this.cargoCapacity,
    required this.fuelCapacity,
  });

  /// ShipType this config is for.
  final ShipType type;

  /// Frame this ship uses.
  final ShipFrameSymbolEnum frameSymbol;

  /// Role for this ship.
  final ShipRole role;

  /// Reactor this ship uses.
  final ShipReactorSymbolEnum reactorSymbol;

  /// Engine this ship uses.
  final ShipEngineSymbolEnum engineSymbol;

  /// Cargo capacity of this ship.
  final int cargoCapacity;

  /// Fuel capacity of this ship.
  final int fuelCapacity;

  /// Get the ship frame for this config.
  ShipFrame get frame {
    final frameConfig = _frameConfigForFrameSymbol(frameSymbol);
    final name = frameConfig?.name ?? frameSymbol.value;
    final description = frameConfig?.description ?? frameSymbol.value;
    return ShipFrame(
      symbol: frameSymbol,
      name: name,
      description: description,
      condition: 100,
      requirements: frameConfig?.requirements ?? ShipRequirements(crew: 0),
      moduleSlots: frameConfig?.moduleSlots ?? 0,
      mountingPoints: frameConfig?.mountingPoints ?? 0,
      fuelCapacity: fuelCapacity,
    );
  }

  /// Get the ship reactor for this config.
  ShipReactor get reactor {
    final reactorConfig = _reactorConfigForReactorSymbol(reactorSymbol);
    final name = reactorConfig?.name ?? reactorSymbol.value;
    final description = reactorConfig?.description ?? reactorSymbol.value;
    final powerOutput = reactorConfig?.powerOutput ?? 0;
    return ShipReactor(
      symbol: reactorSymbol,
      name: name,
      description: description,
      condition: 100,
      powerOutput: powerOutput,
      requirements: reactorConfig?.requirements ?? ShipRequirements(crew: 0),
    );
  }

  /// Get the initial ship crew for this config.
  ShipCrew get crew {
    if (shipTypeFromFrame(frameSymbol) == ShipType.PROBE) {
      return ShipCrew(
        current: 0,
        required_: 0,
        capacity: 0,
        morale: 100,
        wages: 0,
      );
    }
    // Hack until we can compute this from modules/mounts.
    return ShipCrew(
      current: 59,
      required_: 59,
      capacity: 80,
      morale: 100,
      wages: 0,
    );
  }

  /// Get the ship engine for this config.
  ShipEngine get engine {
    final engineConfig = _engineConfigForEngineSymbol(engineSymbol);
    final name = engineConfig?.name ?? engineSymbol.value;
    final description = engineConfig?.description ?? engineSymbol.value;
    final speed = engineConfig?.speed ?? 0;
    return ShipEngine(
      symbol: engineSymbol,
      name: name,
      description: description,
      condition: 100,
      speed: speed,
      requirements: engineConfig?.requirements ?? ShipRequirements(crew: 0),
    );
  }
}

const _shipConfigs = [
  ShipConfig(
    type: ShipType.PROBE,
    role: ShipRole.SATELLITE,
    frameSymbol: ShipFrameSymbolEnum.PROBE,
    reactorSymbol: ShipReactorSymbolEnum.SOLAR_I,
    engineSymbol: ShipEngineSymbolEnum.IMPULSE_DRIVE_I,
    cargoCapacity: 0,
    fuelCapacity: 0,
  ),
  ShipConfig(
    type: ShipType.COMMAND_FRIGATE,
    frameSymbol: ShipFrameSymbolEnum.FRIGATE,
    role: ShipRole.COMMAND,
    reactorSymbol: ShipReactorSymbolEnum.FISSION_I,
    engineSymbol: ShipEngineSymbolEnum.ION_DRIVE_II,
    cargoCapacity: 60,
    fuelCapacity: 1200,
  ),
];

/// Get the ship template for a given ship type.
ShipConfig? shipConfigForType(ShipType shipType) {
  for (final template in _shipConfigs) {
    if (template.type == shipType) return template;
  }
  return null;
}

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
