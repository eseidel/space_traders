import 'package:meta/meta.dart';
import 'package:types/types.dart';
import 'package:yaml/yaml.dart';

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

/// Object describing a Frame.
class FrameConfig {
  /// Create a new frame config.
  const FrameConfig({
    required this.frameSymbol,
    required this.name,
    required this.description,
    required this.requirements,
    required this.moduleSlots,
    required this.mountingPoints,
  });

  /// Create a new frame config from JSON.
  factory FrameConfig.fromJson(YamlMap json) {
    final frameSymbol = ShipFrameSymbolEnum.fromJson(json['frame'] as String)!;
    final name = json['name'] as String;
    final description = json['description'] as String;
    final requirements = ShipRequirements.fromJson(json['requirements'])!;
    final moduleSlots = json['moduleSlots'] as int;
    final mountingPoints = json['mountingPoints'] as int;
    return FrameConfig(
      frameSymbol: frameSymbol,
      name: name,
      description: description,
      requirements: requirements,
      moduleSlots: moduleSlots,
      mountingPoints: mountingPoints,
    );
  }

  /// Frame symbol.
  final ShipFrameSymbolEnum frameSymbol;

  /// Frame name.
  final String name;

  /// Frame description.
  final String description;

  /// Frame requirements.
  final ShipRequirements requirements;

  /// Number of module slots.
  final int moduleSlots;

  /// Number of mounting points.
  final int mountingPoints;
}

/// Template for making a new reactor of a given type.
class ReactorConfig {
  /// Create a new reactor config.
  const ReactorConfig({
    required this.reactorSymbol,
    required this.name,
    required this.description,
    required this.powerOutput,
    required this.requirements,
  });

  /// Create a new reactor config from JSON.
  factory ReactorConfig.fromJson(YamlMap json) {
    final reactorSymbol =
        ShipReactorSymbolEnum.fromJson(json['reactor'] as String)!;
    final name = json['name'] as String;
    final description = json['description'] as String;
    final powerOutput = json['powerOutput'] as int;
    final requirements = ShipRequirements.fromJson(json['requirements'])!;
    return ReactorConfig(
      reactorSymbol: reactorSymbol,
      name: name,
      description: description,
      powerOutput: powerOutput,
      requirements: requirements,
    );
  }

  /// Reactor symbol.
  final ShipReactorSymbolEnum reactorSymbol;

  /// Reactor name.
  final String name;

  /// Reactor description.
  final String description;

  /// Reactor power output.
  final int powerOutput;

  /// Reactor requirements.
  final ShipRequirements requirements;
}

/// Template for making a new engine of a given type.
class EngineConfig {
  /// Create a new engine config.
  const EngineConfig({
    required this.engineSymbol,
    required this.name,
    required this.description,
    required this.speed,
    required this.requirements,
  });

  /// Create a new engine config from JSON.
  factory EngineConfig.fromJson(YamlMap json) {
    final engineSymbol =
        ShipEngineSymbolEnum.fromJson(json['engine'] as String)!;
    final name = json['name'] as String;
    final description = json['description'] as String;
    final speed = json['speed'] as int;
    final requirements = ShipRequirements.fromJson(json['requirements'])!;
    return EngineConfig(
      engineSymbol: engineSymbol,
      name: name,
      description: description,
      speed: speed,
      requirements: requirements,
    );
  }

  /// Engine symbol.
  final ShipEngineSymbolEnum engineSymbol;

  /// Engine name.
  final String name;

  /// Engine description.
  final String description;

  /// Engine requirements.
  final int speed;

  /// Engine requirements.
  final ShipRequirements requirements;
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

  /// Create a new ship config from JSON.
  factory ShipConfig.fromJson(YamlMap json) {
    final type = ShipType.fromJson(json['type'] as String)!;
    final frameSymbol = ShipFrameSymbolEnum.fromJson(json['frame'] as String)!;
    final role = ShipRole.fromJson(json['role'] as String)!;
    final reactorSymbol =
        ShipReactorSymbolEnum.fromJson(json['reactor'] as String)!;
    final engineSymbol =
        ShipEngineSymbolEnum.fromJson(json['engine'] as String)!;
    final cargoCapacity = json['cargoCapacity'] as int;
    final fuelCapacity = json['fuelCapacity'] as int;
    return ShipConfig(
      type: type,
      frameSymbol: frameSymbol,
      role: role,
      reactorSymbol: reactorSymbol,
      engineSymbol: engineSymbol,
      cargoCapacity: cargoCapacity,
      fuelCapacity: fuelCapacity,
    );
  }

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
  ShipFrame buildFrame(ShipConfigs configs) {
    final frameConfig = configs.frameConfigBySymbol(frameSymbol);
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
  ShipReactor buildReactor(ShipConfigs configs) {
    final reactorConfig = configs.reactorConfigBySymbol(reactorSymbol);
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
  ShipCrew buildCrew(ShipConfigs configs) {
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
  ShipEngine buildEngine(ShipConfigs configs) {
    final engineConfig = configs.engineConfigBySymbol(engineSymbol);
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

/// Template for making a new mount of a given type.
class MountConfig {
  /// Create a new mount config.
  MountConfig();

  /// Create a new mount config from JSON.
  factory MountConfig.fromJson(YamlMap json) {
    assert(json.isEmpty, 'Mounts are not yet supported');
    return MountConfig();
  }
}

/// Template for making a new module of a given type.
class ModuleConfig {
  /// Create a new module config.
  ModuleConfig();

  /// Create a new module config from JSON.
  factory ModuleConfig.fromJson(YamlMap json) {
    assert(json.isEmpty, 'Modules are not yet supported');
    return ModuleConfig();
  }
}

/// Cache of ship templates.
class ShipConfigs {
  /// Creates a new ship template cache.
  ShipConfigs({
    required this.ships,
    required this.frames,
    required this.engines,
    required this.reactors,
    required this.mounts,
    required this.modules,
  });

  /// Creates a new ship template cache from JSON.
  factory ShipConfigs.fromJson(YamlMap json) {
    final ships = (json['ships'] as YamlList)
        .map((s) => ShipConfig.fromJson(s as YamlMap))
        .toList();
    final frames = (json['frames'] as YamlList)
        .map((s) => FrameConfig.fromJson(s as YamlMap))
        .toList();
    final engines = (json['engines'] as YamlList)
        .map((s) => EngineConfig.fromJson(s as YamlMap))
        .toList();
    final reactors = (json['reactors'] as YamlList)
        .map((s) => ReactorConfig.fromJson(s as YamlMap))
        .toList();
    final mounts = (json['mounts'] as YamlList)
        .map((s) => MountConfig.fromJson(s as YamlMap))
        .toList();
    final modules = (json['modules'] as YamlList)
        .map((s) => ModuleConfig.fromJson(s as YamlMap))
        .toList();
    return ShipConfigs(
      ships: ships,
      frames: frames,
      engines: engines,
      reactors: reactors,
      mounts: mounts,
      modules: modules,
    );
  }

  /// Ship templates.
  final List<ShipConfig> ships;

  /// Frame templates.
  final List<FrameConfig> frames;

  /// Engine templates.
  final List<EngineConfig> engines;

  /// Reactor templates.
  final List<ReactorConfig> reactors;

  /// Mount templates.
  final List<MountConfig> mounts;

  /// Module templates.
  final List<ModuleConfig> modules;

  /// Get the ship template for a given ship type.
  ShipConfig? shipConfigForType(ShipType shipType) {
    for (final template in ships) {
      if (template.type == shipType) return template;
    }
    return null;
  }

  /// Get the frame template for a given frame symbol.
  FrameConfig? frameConfigBySymbol(ShipFrameSymbolEnum frameSymbol) {
    for (final template in frames) {
      if (template.frameSymbol == frameSymbol) return template;
    }
    return null;
  }

  /// Get the reactor template for a given reactor symbol.
  ReactorConfig? reactorConfigBySymbol(ShipReactorSymbolEnum reactorSymbol) {
    for (final template in reactors) {
      if (template.reactorSymbol == reactorSymbol) return template;
    }
    return null;
  }

  /// Get the engine template for a given engine symbol.
  EngineConfig? engineConfigBySymbol(ShipEngineSymbolEnum engineSymbol) {
    for (final template in engines) {
      if (template.engineSymbol == engineSymbol) return template;
    }
    return null;
  }
}
