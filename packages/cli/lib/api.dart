import 'dart:math';

import 'package:cli/net/rate_limit.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:openapi/api.dart';

export 'package:openapi/api.dart';

/// The default http get function.
const defaultHttpGet = http.get;

/// The default implementation of getNow for production.
/// Used for tests for overriding the current time.
DateTime defaultGetNow() => DateTime.timestamp();

/// Api is a wrapper around the generated api clients.
/// It provides a single place to inject the api client.
/// This allows for easier mocking.
class Api {
  /// Construct an Api with the given ApiClient.
  Api(this.apiClient)
      : systems = SystemsApi(apiClient),
        defaultApi = DefaultApi(apiClient),
        contracts = ContractsApi(apiClient),
        agents = AgentsApi(apiClient),
        fleet = FleetApi(apiClient),
        factions = FactionsApi(apiClient);

  /// The shared ApiClient.
  final RateLimitedApiClient apiClient;

  /// DefaultApi generated client.
  final DefaultApi defaultApi;

  /// SystemApi generated client.
  final SystemsApi systems;

  /// ContractsApi generated client.
  final ContractsApi contracts;

  /// AgentsApi generated client.
  final AgentsApi agents;

  /// FleetApi generated client.
  final FleetApi fleet;

  /// FactionsApi generated client.
  final FactionsApi factions;
}

/// Asserts that the given system symbol is valid.
void assertIsSystemSymbol(String systemSymbol) {
  assert(
    systemSymbol.split('-').length == 2,
    '$systemSymbol is not a valid system symbol',
  );
}

/// Asserts that the given waypoint symbol is valid.
void assertIsWaypointSymbol(String waypointSymbol) {
  assert(
    waypointSymbol.split('-').length == 3,
    '$waypointSymbol is not a valid waypoint symbol',
  );
}

/// parseWaypointString parses a waypoint string into its component parts.
({String sector, String system, String waypoint}) parseWaypointString(
  String waypointSymbol,
) {
  final parts = waypointSymbol.split('-');
  return (
    sector: parts[0],
    system: '${parts[0]}-${parts[1]}',
    waypoint: '${parts[0]}-${parts[1]}-${parts[2]}',
  );
}

/// A position within an unspecified coordinate space.
@immutable
class Position {
  const Position._(this.x, this.y);

  /// The x coordinate.
  final int x;

  /// The y coordinate.
  final int y;
}

/// An x, y position within the System coordinate space.
@immutable
class SystemPosition extends Position {
  /// Construct a SystemPosition with the given x and y.
  const SystemPosition(super.x, super.y) : super._();

  /// Returns the distance between this position and the given position.
  int distanceTo(SystemPosition other) {
    // Use euclidean distance.
    final dx = other.x - x;
    final dy = other.y - y;
    return sqrt(dx * dx + dy * dy).round();
  }
}

/// An x, y position within the Waypoint coordinate space.
@immutable
class WaypointPosition extends Position {
  /// Construct a WaypointPosition with the given x and y.
  const WaypointPosition(super.x, super.y, this.system) : super._();

  /// The system symbol of the waypoint.
  final String system;

  /// Returns the distance between this position and the given position.
  int distanceTo(WaypointPosition other) {
    if (system != other.system) {
      throw ArgumentError(
        'Waypoints must be in the same system: $this, $other',
      );
    }
    // Use euclidean distance.
    final dx = other.x - x;
    final dy = other.y - y;
    return sqrt(dx * dx + dy * dy).round();
  }
}

/// Parsed ShipSymbol which can be compared/sorted.
@immutable
class ShipSymbol implements Comparable<ShipSymbol> {
  /// Create a ShipSymbol from name and number part.
  /// The number part is given in decimal, but will be represented in hex.
  const ShipSymbol(this.name, this.number);

  /// Create a ShipSymbol from a string.
  ShipSymbol.fromString(String symbol)
      : name = symbol.split('-')[0],
        number = int.parse(symbol.split('-')[1], radix: 16);

  /// The name part of the ship symbol.
  final String name;

  /// The number part of the ship symbol.
  final int number;

  /// The number part in hex.
  String get hexNumber => number.toRadixString(16).toUpperCase();

  /// The full ship symbol.
  String get symbol => '$name-$hexNumber';

  @override
  int compareTo(ShipSymbol other) {
    final nameCompare = name.compareTo(other.name);
    if (nameCompare != 0) {
      return nameCompare;
    }
    return number.compareTo(other.number);
  }

  @override
  String toString() => symbol;
}

/// Extensions onto System to make it easier to work with.
extension SystemUtils on System {
  /// Returns true if the system has a jump gate.
  bool get hasJumpGate =>
      waypoints.any((w) => w.type == WaypointType.JUMP_GATE);

  /// Returns the the SystemWaypoint for the jump gate if it has one.
  SystemWaypoint? get jumpGateWaypoint => waypoints.firstWhereOrNull(
        (w) => w.type == WaypointType.JUMP_GATE,
      );

  /// Returns the SystemPosition of the system.
  SystemPosition get position => SystemPosition(x, y);

  /// Returns the distance to the given system.
  int distanceTo(System other) => position.distanceTo(other.position);
}

/// Extensions onto SystemWaypoint to make it easier to work with.
extension SystemWaypointUtils on SystemWaypoint {
  /// Returns true if the waypoint has the given type.
  bool isType(WaypointType type) => this.type == type;

  /// Returns true if the waypoint is a jump gate.
  bool get isJumpGate => isType(WaypointType.JUMP_GATE);

  /// Returns true if the waypoint is an asteroid field.
  bool get isAsteroidField => isType(WaypointType.ASTEROID_FIELD);

  /// Returns true if the waypoint can be mined.
  bool get canBeMined => isAsteroidField;

  /// The system symbol of the waypoint.
  String get systemSymbol => parseWaypointString(symbol).system;

  /// Returns the WaypointPosition of the waypoint.
  WaypointPosition get position => WaypointPosition(x, y, systemSymbol);

  /// Returns the distance to the given waypoint.
  int distanceTo(SystemWaypoint other) => position.distanceTo(other.position);
}

/// Extensions onto Waypoint to make it easier to work with.
extension WaypointUtils on Waypoint {
  /// Converts the waypoint to a SystemWaypoint.
  SystemWaypoint toSystemWaypoint() {
    return SystemWaypoint(
      symbol: symbol,
      type: type,
      x: x,
      y: y,
    );
  }

  /// Returns true if the waypoint has the given trait.
  bool hasTrait(WaypointTraitSymbolEnum trait) {
    return traits.any((t) => t.symbol == trait);
  }

  /// Returns true if the waypoint has the given type.
  bool isType(WaypointType type) => this.type == type;

  /// Returns true if the waypoint is an asteroid field.
  bool get isAsteroidField => isType(WaypointType.ASTEROID_FIELD);

  /// Returns true if the waypoint has the stripped trait.
  bool get isStripped => hasTrait(WaypointTraitSymbolEnum.STRIPPED);

  /// Returns true if the waypoint can be mined.
  // Unclear if isStripped is needed, hq's system has a stripped asteroid field
  // but it can't be mined, hit a 500 on another:
  // https://github.com/SpaceTradersAPI/api-docs/issues/51
  bool get canBeMined => isAsteroidField; // && !isStripped;

  /// Returns true if the waypoint is a jump gate.
  bool get isJumpGate => isType(WaypointType.JUMP_GATE);

  /// Returns true if the waypoint has a shipyard.
  bool get hasShipyard => hasTrait(WaypointTraitSymbolEnum.SHIPYARD);

  /// Returns true if the waypoint has a marketplace.
  bool get hasMarketplace => hasTrait(WaypointTraitSymbolEnum.MARKETPLACE);

  /// Returns the WaypointPosition of the waypoint.
  WaypointPosition get position => WaypointPosition(x, y, systemSymbol);

  /// Returns the distance to the given waypoint.
  int distanceTo(Waypoint other) => position.distanceTo(other.position);
}

/// Extensions onto ShipCargo to make it easier to work with.
extension CargoUtils on ShipCargo {
  /// Returns the amount of cargo space available on the ship.
  int get availableSpace => capacity - units;

  /// Returns true if the cargo is empty.
  bool get isEmpty => units == 0;

  /// Returns true if the cargo is not empty.
  bool get isNotEmpty => !isEmpty;

  /// Returns the amount of the given trade good the cargo has.
  int countUnits(String tradeSymbol) {
    final maybeCargo = inventory.firstWhereOrNull(
      (i) => i.symbol == tradeSymbol,
    );
    return maybeCargo?.units ?? 0;
  }
}

/// Extensions onto Ship to make it easier to work with.
extension ShipUtils on Ship {
  /// Returns the emoji name of the ship.
  String get emojiName {
    // Ships are all AGENT_SYMBOL-1, AGENT_SYMBOL-2, etc.
    final number = symbol.split('-').last;
    return '🛸#$number';
  }

  /// Returns the amount of the given trade good the ship has.
  int countUnits(String tradeSymbol) {
    return cargo.countUnits(tradeSymbol);
  }

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

  /// Returns true if the ship if full on fuel.
  bool get isFuelFull => fuel.current >= fuel.capacity;

  /// Returns true if the ship is out of fuel.  Nothing to do at this point.
  bool get isOutOfFuel => usesFuel && fuel.current == 0;

  /// Returns true if the ship should refuel.
  // One fuel bought from the market is 100 units of fuel in the ship.
  // For repeated short trips, avoiding buying fuel when we're close to full.
  bool get shouldRefuel => fuel.current < (fuel.capacity - 100);

  /// Returns the amount of space available on the ship.
  int get availableSpace => cargo.availableSpace;

  /// Returns true if the ship is an excavator.
  bool get isExcavator => registration.role == ShipRole.EXCAVATOR;

  /// Returns true if the ship is a probe.
  bool get isProbe => frame.symbol == ShipFrameSymbolEnum.PROBE;

  /// Returns true if the ship is a hauler.
  bool get isHauler => frame.symbol == ShipFrameSymbolEnum.LIGHT_FREIGHTER;

  /// Returns true if the ship can mine.
  bool get canMine {
    const minerMounts = [
      ShipMountSymbolEnum.MINING_LASER_I,
      ShipMountSymbolEnum.MINING_LASER_II,
      ShipMountSymbolEnum.MINING_LASER_III,
    ];
    return mounts.any((m) => minerMounts.contains(m.symbol));
  }

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

  /// Returns true if the ship has a surveyor module.
  bool get hasSurveyor {
    const surveyerMounts = [
      ShipMountSymbolEnum.SURVEYOR_I,
      ShipMountSymbolEnum.SURVEYOR_II,
      ShipMountSymbolEnum.SURVEYOR_III,
    ];
    return mounts.any((m) => surveyerMounts.contains(m.symbol));
  }

  /// Returns the average condition of the ship with 100 being perfect and 0
  /// being destroyed. This is the average of the engine, frame, and reactor
  /// conditions.
  int get averageCondition {
    var total = 0;
    total += engine.condition ?? 100;
    total += frame.condition ?? 100;
    total += reactor.condition ?? 100;
    return total ~/ 3;
  }

  /// Returns a string representing the current navigation status of the ship.
  String get navStatusString {
    switch (nav.status) {
      case ShipNavStatus.DOCKED:
        return 'Docked at ${nav.waypointSymbol}';
      case ShipNavStatus.IN_ORBIT:
        return 'Orbiting ${nav.waypointSymbol}';
      case ShipNavStatus.IN_TRANSIT:
        return 'In transit to ${nav.waypointSymbol}';
    }
    return 'Unknown';
  }
}

/// Extensions onto Contract to make it easier to work with.
extension ContractUtils on Contract {
  // bool needsItem(String tradeSymbol) => goodNeeded(tradeSymbol) != null;

  /// Returns the ContractDeliverGood for the given trade good symbol or null if
  /// the contract doesn't need that good.
  ContractDeliverGood? goodNeeded(String tradeSymbol) {
    return terms.deliver
        .firstWhereOrNull((item) => item.tradeSymbol == tradeSymbol);
  }

  /// Returns the duration until the contract deadline.
  Duration get timeUntilDeadline => terms.deadline.difference(DateTime.now());

  /// Returns true if the contract has expired.
  bool get isExpired => timeUntilDeadline.isNegative;
}

/// Extensions onto ContractDeliverGood to make it easier to work with.
extension ContractDeliverGoodUtils on ContractDeliverGood {
  /// Returns the amount of the given trade good the contract needs.
  int get amountNeeded => unitsRequired - unitsFulfilled;
}

/// Enum representing the type of trades available for a good at a market.
enum ExchangeType {
  /// Market imports this good. (Likely to be sold at a higher price.)
  imports,

  /// Market exports this good. (Likely to be bought at a lower price.)
  exports,

  /// Market allows agents to exchange this good.
  exchange,
}

/// Extensions onto Market to make it easier to work with.
extension MarketUtils on Market {
  /// Returns the TradeType for the given trade symbol or null if the market
  /// doesn't trade that good.
  ExchangeType? exchangeType(String tradeSymbol) {
    if (imports.any((g) => g.symbol.value == tradeSymbol)) {
      return ExchangeType.imports;
    }
    if (exports.any((g) => g.symbol.value == tradeSymbol)) {
      return ExchangeType.exports;
    }
    if (exchange.any((g) => g.symbol.value == tradeSymbol)) {
      return ExchangeType.exchange;
    }
    return null;
  }

  /// Returns true if the market allows trading of the given trade symbol.
  bool allowsTradeOf(String tradeSymbol) => exchangeType(tradeSymbol) != null;

  /// Returns [MarketTradeGood] for the given trade symbol or null if the market
  /// doesn't trade that good.
  MarketTradeGood? marketTradeGood(String tradeSymbol) =>
      tradeGoods.firstWhereOrNull((g) => g.symbol == tradeSymbol);

  /// Returns all TradeSymbols that the market trades.
  Set<TradeSymbol> get allTradeSymbols {
    final symbols = <TradeSymbol>{
      ...imports.map((g) => g.symbol),
      ...exports.map((g) => g.symbol),
      ...exchange.map((g) => g.symbol)
    };
    return symbols;
  }
}

/// Extensions onto Shipyard to make it easier to work with.
extension ShipyardUtils on Shipyard {
  /// Returns true if the Shipyard has the given ship type.
  bool hasShipType(ShipType shipType) {
    return shipTypes.any((s) => s.type == shipType);
  }
}

/// Returns the duration until the given date time.
Duration durationUntil(DateTime dateTime) =>
    dateTime.difference(DateTime.now());

/// Creates a ConnectedSystem from a System and a distance.
ConnectedSystem connectedSystemFromSystem(System system, int distance) {
  return ConnectedSystem(
    distance: distance,
    symbol: system.symbol,
    sectorSymbol: system.sectorSymbol,
    type: system.type,
    x: system.x,
    y: system.y,
  );
}
