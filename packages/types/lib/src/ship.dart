import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:openapi/api.dart' as openapi;
import 'package:types/types.dart';

/// Our alternative to ShipRole, since ShipRole does not always correspond
/// to how we think about planning for a given ship configuration.
/// e.g. a SIPHON_DRONE and MINER_DRONE are both ShipRole.EXTRACTOR
/// but we want to treat them differently. Similarly ShipType.ORE_HOUND
/// might end up fitted with mounts to make it a FleetRole.surveyor or
/// FleetRole.miner or FleetRole.siphoner.
enum FleetRole {
  /// General purpose command ship.
  command,

  /// A ship set up to trade.
  trader,

  /// A ship set up to mine.
  miner,

  /// A ship set up to survey.
  surveyor,

  /// A ship set up to siphon.
  siphoner,

  /// A ship set up to explore.
  explorer,

  /// A ship set up to explore.
  probe,

  /// A ship with an unknown role.
  unknown,
}

/// Class to hold common ship traits needed for route planning.
class ShipSpec {
  /// Construct a ShipSpec.
  const ShipSpec({
    required this.cargoCapacity,
    required this.fuelCapacity,
    required this.speed,
    required this.canWarp,
  });

  /// Create a ShipSpec from a JSON map.
  ShipSpec.fromJson(Map<String, dynamic> json)
    : this(
        cargoCapacity: json['cargoCapacity'] as int,
        fuelCapacity: json['fuelCapacity'] as int,
        speed: json['speed'] as int,
        canWarp: json['canWarp'] as bool,
      );

  /// Fallback value for mocking.
  @visibleForTesting
  ShipSpec.fallbackValue()
    : this(cargoCapacity: 0, fuelCapacity: 100, speed: 10, canWarp: false);

  /// The fuel capacity of the ship.
  final int fuelCapacity;

  /// The cargo capacity of the ship.
  final int cargoCapacity;

  /// The speed of the ship.
  final int speed;

  /// Can the ship warp.
  final bool canWarp;

  /// Convert this ShipSpec to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'cargoCapacity': cargoCapacity,
    'fuelCapacity': fuelCapacity,
    'speed': speed,
    'canWarp': canWarp,
  };
}

// TODO(eseidel): Integrate into Ship after fixing tests which expect this to
// be an extension.
/// Extensions to make Ship easier to work with.
/// Extensions onto Ship to make it easier to work with.
extension ShipUtils on Ship {
  /// Returns the current SystemSymbol of the ship.
  SystemSymbol get systemSymbol => nav.systemSymbolObject;

  /// Returns the current WaypointSymbol of the ship.
  WaypointSymbol get waypointSymbol => nav.waypointSymbolObject;

  /// Returns the emoji name of the ship.
  String get emojiName {
    // Ships are all AGENT_SYMBOL-1, AGENT_SYMBOL-2, etc.
    return '🛸#${symbol.hexNumber}';
  }

  /// Returns the ShipSpec for the ship.
  ShipSpec get shipSpec => ShipSpec(
    cargoCapacity: cargo.capacity,
    fuelCapacity: fuel.capacity,
    speed: engine.speed,
    canWarp: modules.any((m) => m.symbol == ShipModuleSymbol.WARP_DRIVE_I),
  );

  /// Returns the amount of the given trade good the ship has.
  int countUnits(TradeSymbol tradeSymbol) => cargo.countUnits(tradeSymbol);

  /// Returns the largest cargo in the ship.
  ShipCargoItem? largestCargo({bool Function(ShipCargoItem)? where}) {
    if (cargo.isEmpty) {
      return null;
    }
    final filter = where ?? (i) => true;
    return cargo.inventory
        .sortedBy<num>((i) => i.units)
        .lastWhereOrNull(filter);
  }

  /// Returns true if the ship is out of fuel.  Nothing to do at this point.
  bool get isOutOfFuel => usesFuel && fuel.current == 0;

  /// Returns true if the ship is at full fuel capacity.
  bool get isFuelFull => fuel.current == fuel.capacity;

  /// Returns the number of units of fuel needed to top up the ship.
  /// This is in ship fuel units, not market fuel units.
  /// 1 unit of market fuel = 100 units of ship fuel.
  int get fuelUnitsNeeded => fuel.capacity - fuel.current;

  /// Returns the amount of space available on the ship.
  int get availableSpace => cargo.availableSpace;

  /// Returns true if the ship is a command ship.
  bool get isCommand => registration.role == ShipRole.COMMAND;

  /// Returns true if the ship is a miner frame.
  bool get isMiner => frame.symbol == ShipFrameSymbol.MINER;

  /// Returns true if the ship is a probe.
  bool get isProbe => frame.symbol == ShipFrameSymbol.PROBE;

  /// Returns true if the ship is an explorer.
  bool get isExplorer => frame.symbol == ShipFrameSymbol.EXPLORER;

  /// Returns true if the ship is a hauler.
  bool get isHauler =>
      frame.symbol == ShipFrameSymbol.LIGHT_FREIGHTER ||
      frame.symbol == ShipFrameSymbol.HEAVY_FREIGHTER ||
      frame.symbol == ShipFrameSymbol.EXPLORER ||
      frame.symbol == ShipFrameSymbol.SHUTTLE;

  /// Returns true if the ship has a mining mount.
  bool get hasMiningLaser => mountedMiningLasers.isNotEmpty;

  /// Returns true if the ship has a mining mount.
  Iterable<ShipMount> get mountedMiningLasers =>
      mounts.where((m) => kLaserMountSymbols.contains(m.symbol));

  /// Returns true if the ship has a survey mount.
  bool get hasSurveyor =>
      mounts.any((m) => kSurveyMountSymbols.contains(m.symbol));

  /// Returns true if the ship has a siphon mount.
  bool get hasSiphon =>
      mounts.any((m) => kSiphonMountSymbols.contains(m.symbol));

  /// Returns true if the ship has a refinery mount.
  bool get hasOreRefinery =>
      modules.any((m) => m.symbol == ShipModuleSymbol.ORE_REFINERY_I);

  /// Returns true if the ship is in transit.
  bool get isInTransit => nav.status == ShipNavStatus.IN_TRANSIT;

  /// Returns true if the ship is docked.
  bool get isDocked => nav.status == ShipNavStatus.DOCKED;

  /// Returns true if the ship is in orbit.
  bool get isOrbiting => nav.status == ShipNavStatus.IN_ORBIT;

  /// Returns true if the ship uses fuel.
  bool get usesFuel => fuel.capacity > 0;

  /// Returns percentage of fuel remaining.
  /// Returns 1 if the ship doesn't use fuel.
  /// Returns 0 if the ship is out of fuel.
  /// Otherwise returns a value between 0 and 1.
  double get fuelPercentage {
    if (!usesFuel) {
      return 1;
    }
    return fuel.current / fuel.capacity;
  }

  /// Returns the Duration until the ship is ready to use its reactor again.
  /// Will never return a negative duration, will instead return null.
  /// Use this instead of cooldown.remainingSeconds since that can be stale
  /// and does not reflect the current time.
  Duration? remainingCooldown(DateTime now) {
    final expiration = cooldown.expiration;
    if (expiration == null) {
      return null;
    }
    final duration = expiration.difference(now);
    if (duration.isNegative) {
      return null;
    }
    return duration;
  }

  /// Returns a copy of this ship with the same properties.
  Ship deepCopy() {
    // Ship.toJson doesn't recurse (openapi gen bug), so use jsonEncode.
    return Ship.fromJson(
      jsonDecode(jsonEncode(toJson())) as Map<String, dynamic>,
    );
  }
}

/// A ship.
// TODO(eseidel): Should this be immutable?
class Ship {
  /// Creates a new ship.
  Ship({
    required this.symbol,
    required this.registration,
    required this.nav,
    required this.crew,
    required this.frame,
    required this.reactor,
    required this.engine,
    required this.cooldown,
    required this.cargo,
    required this.fuel,
    this.modules = const [],
    this.mounts = const [],
  });

  /// Fallback value for mocking.
  @visibleForTesting
  factory Ship.fallbackValue() {
    return Ship.test(const ShipSymbol.fallbackValue());
  }

  /// Creates a new ship from a JSON map.
  Ship.fromJson(Map<String, dynamic> json)
    : this.fromOpenApi(openapi.Ship.fromJson(json));

  /// Creates a new ship from an OpenAPI ship.
  Ship.fromOpenApi(openapi.Ship ship)
    : symbol = ShipSymbol.fromJson(ship.symbol),
      registration = ship.registration,
      nav = ship.nav,
      crew = ship.crew,
      frame = ship.frame,
      reactor = ship.reactor,
      engine = ship.engine,
      cooldown = ship.cooldown,
      modules = ship.modules,
      mounts = ship.mounts,
      cargo = ship.cargo,
      fuel = ship.fuel;

  /// Create a test ship.
  @visibleForTesting
  factory Ship.test(ShipSymbol symbol) {
    final waypoint = const WaypointSymbol.fallbackValue().waypoint;
    final system = const SystemSymbol.fallbackValue().system;
    final navRouteWaypoint = ShipNavRouteWaypoint(
      symbol: waypoint,
      type: openapi.WaypointType.PLANET,
      systemSymbol: system,
      x: 0,
      y: 0,
    );
    return Ship(
      symbol: symbol,
      registration: openapi.ShipRegistration(
        name: '',
        role: ShipRole.CARRIER,
        factionSymbol: FactionSymbol.AEGIS.value,
      ),
      nav: openapi.ShipNav(
        systemSymbol: system,
        waypointSymbol: waypoint,
        status: ShipNavStatus.DOCKED,
        route: openapi.ShipNavRoute(
          origin: navRouteWaypoint,
          arrival: DateTime(2021),
          departureTime: DateTime(2021),
          destination: navRouteWaypoint,
        ),
      ),
      crew: openapi.ShipCrew(
        current: 0,
        required_: 0,
        capacity: 0,
        morale: 0,
        wages: 0,
      ),
      frame: ShipFrame(
        symbol: ShipFrameSymbol.SHUTTLE,
        name: '',
        description: '',
        moduleSlots: 0,
        mountingPoints: 0,
        fuelCapacity: 0,
        requirements: ShipRequirements(),
        condition: 1,
        integrity: 1,
        quality: 1,
      ),
      reactor: ShipReactor(
        symbol: ShipReactorSymbol.SOLAR_I,
        name: '',
        description: '',
        powerOutput: 0,
        requirements: ShipRequirements(),
        condition: 1,
        integrity: 1,
        quality: 1,
      ),
      engine: ShipEngine(
        symbol: ShipEngineSymbol.HYPER_DRIVE_I,
        name: '',
        description: '',
        speed: 0,
        requirements: ShipRequirements(),
        condition: 1,
        integrity: 1,
        quality: 1,
      ),
      cooldown: Cooldown(
        shipSymbol: 'A',
        totalSeconds: 0,
        remainingSeconds: 0,
        expiration: DateTime(2021),
      ),
      cargo: openapi.ShipCargo(capacity: 0, units: 0, inventory: []),
      fuel: openapi.ShipFuel(current: 0, capacity: 0),
    );
  }

  /// Converts this ship to an OpenAPI ship.
  openapi.Ship toOpenApi() => openapi.Ship(
    symbol: symbol.symbol,
    registration: registration,
    nav: nav,
    crew: crew,
    frame: frame,
    reactor: reactor,
    engine: engine,
    cooldown: cooldown,
    modules: modules,
    mounts: mounts,
    cargo: cargo,
    fuel: fuel,
  );

  /// Compute the fleet role for a given ship.
  FleetRole get fleetRole {
    if (isCommand) {
      return FleetRole.command;
    } else if (isExplorer) {
      return FleetRole.explorer;
    } else if (hasMiningLaser) {
      return FleetRole.miner;
    } else if (hasSurveyor) {
      return FleetRole.surveyor;
    } else if (hasSiphon) {
      return FleetRole.siphoner;
    } else if (isHauler) {
      return FleetRole.trader;
    } else if (isProbe) {
      return FleetRole.probe;
    }
    return FleetRole.unknown;
  }

  /// Converts this ship to a JSON map.
  Map<String, dynamic> toJson() => toOpenApi().toJson();

  /// The symbol of this ship.
  final ShipSymbol symbol;

  /// The registration of this ship.
  final openapi.ShipRegistration registration;

  /// The navigation status of this ship.
  openapi.ShipNav nav;

  /// The crew of this ship.
  final openapi.ShipCrew crew;

  /// The frame of this ship.
  final openapi.ShipFrame frame;

  /// The reactor of this ship.
  final openapi.ShipReactor reactor;

  /// The engine of this ship.
  final openapi.ShipEngine engine;

  /// The cooldown of this ship.
  openapi.Cooldown cooldown;

  /// Modules installed in this ship.
  final List<openapi.ShipModule> modules;

  /// Mounts installed in this ship.
  List<openapi.ShipMount> mounts;

  /// Cargo carried by this ship.
  openapi.ShipCargo cargo;

  /// Fuel carried by this ship.
  openapi.ShipFuel fuel;
}

/// Create a test ShipFrame.
@visibleForTesting
ShipFrame testShipFrame() {
  return ShipFrame(
    symbol: ShipFrameSymbol.PROBE,
    name: 'name',
    description: 'description',
    condition: 100,
    integrity: 100,
    quality: 100,
    requirements: ShipRequirements(power: 100, crew: 100, slots: 100),
    moduleSlots: 100,
    mountingPoints: 100,
    fuelCapacity: 100,
  );
}

/// Create a test ShipReactor.
@visibleForTesting
ShipReactor testShipReactor() {
  return ShipReactor(
    symbol: ShipReactorSymbol.SOLAR_I,
    name: 'name',
    description: 'description',
    condition: 100,
    integrity: 100,
    powerOutput: 100,
    requirements: ShipRequirements(power: 100, crew: 100, slots: 100),
    quality: 100,
  );
}

/// Create a test ShipEngine.
@visibleForTesting
ShipEngine testShipEngine() {
  return ShipEngine(
    symbol: ShipEngineSymbol.ION_DRIVE_I,
    name: 'name',
    description: 'description',
    condition: 100,
    integrity: 100,
    speed: 100,
    requirements: ShipRequirements(power: 100, crew: 100, slots: 100),
    quality: 100,
  );
}

/// Create a test ShipModule.
@visibleForTesting
ShipModule testShipModule() {
  return ShipModule(
    symbol: ShipModuleSymbol.MINERAL_PROCESSOR_I,
    name: 'name',
    description: 'description',
    requirements: ShipRequirements(power: 100, crew: 100, slots: 100),
  );
}

/// Create a test ShipMount.
@visibleForTesting
ShipMount testShipMount() {
  return ShipMount(
    symbol: ShipMountSymbol.GAS_SIPHON_I,
    name: 'name',
    description: 'description',
    strength: 100,
    requirements: ShipRequirements(power: 100, crew: 100, slots: 100),
  );
}

/// Create a test ShipyardShip.
@visibleForTesting
ShipyardShip testShipyardShip() {
  return ShipyardShip(
    type: ShipType.PROBE,
    purchasePrice: 100,
    name: 'name',
    description: 'description',
    supply: SupplyLevel.MODERATE,
    frame: testShipFrame(),
    reactor: testShipReactor(),
    engine: testShipEngine(),
    modules: [testShipModule()],
    mounts: [testShipMount()],
    crew: ShipyardShipCrew(required_: 100, capacity: 100),
  );
}

/// Create a test ShipConditionEvent.
@visibleForTesting
ShipConditionEvent testShipConditionEvent() {
  return ShipConditionEvent(
    symbol: ShipConditionEventSymbol.REACTOR_OVERLOAD,
    name: 'name',
    description: 'description',
    component: ShipConditionEventComponent.REACTOR,
  );
}

/// Create a test WaypointTrait.
@visibleForTesting
WaypointTrait testWaypointTrait() {
  return WaypointTrait(
    symbol: WaypointTraitSymbol.UNDER_CONSTRUCTION,
    name: 'name',
    description: 'description',
  );
}

/// Create a test TradeGood.
@visibleForTesting
TradeGood testTradeGood() {
  return TradeGood(
    symbol: TradeSymbol.IRON,
    name: 'name',
    description: 'description',
  );
}

/// Create a test TradeExport.
@visibleForTesting
TradeExport testTradeExport() {
  return const TradeExport(
    export: TradeSymbol.IRON,
    imports: [TradeSymbol.IRON_ORE],
  );
}
