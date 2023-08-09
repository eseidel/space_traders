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
  final ApiClient apiClient;

  /// soon to be removed.
  /// The shared ApiClient.
  RateLimitedApiClient get rateLimitedApiClient =>
      apiClient as RateLimitedApiClient;

  /// Counts of requests sent through this api.
  RequestCounts get requestCounts => rateLimitedApiClient.requestCounts;

  /// The number of requests per second allowed by the api.
  int get maxRequestsPerSecond => 3;

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
  final SystemSymbol system;

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

/// Type-safe representation of a Waypoint Symbol
@immutable
class WaypointSymbol {
  const WaypointSymbol._(this.waypoint);

  /// Create a WaypointSymbol from a json string.
  factory WaypointSymbol.fromJson(String json) =>
      WaypointSymbol.fromString(json);

  /// Create a WaypointSymbol from a string.
  factory WaypointSymbol.fromString(String symbol) {
    if (symbol.split('-').length != 3) {
      throw ArgumentError('Invalid waypoint symbol: $symbol');
    }
    return WaypointSymbol._(symbol);
  }

  /// The sector symbol of the waypoint.
  String get sector => system.split('-')[0];

  /// The system symbol of the waypoint.
  String get system {
    final parts = waypoint.split('-');
    return '${parts[0]}-${parts[1]}';
  }

  /// The SystemSymbol of the waypoint.
  SystemSymbol get systemSymbol => SystemSymbol.fromString(system);

  /// The full waypoint symbol.
  final String waypoint;

  @override
  String toString() => waypoint;

  /// Returns the json representation of the waypoint.
  String toJson() => waypoint;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaypointSymbol &&
          runtimeType == other.runtimeType &&
          waypoint == other.waypoint;

  @override
  int get hashCode => waypoint.hashCode;
}

/// Type-safe representation of a System Symbol
@immutable
class SystemSymbol {
  const SystemSymbol._(this.system);

  /// Create a SystemSymbol from a string.
  factory SystemSymbol.fromString(String symbol) {
    if (symbol.split('-').length != 2) {
      throw ArgumentError('Invalid system symbol: $symbol');
    }
    return SystemSymbol._(symbol);
  }

  /// The sector symbol of the system.
  String get sector => system.split('-')[0];

  /// The full system symbol.
  final String system;

  @override
  String toString() => system;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SystemSymbol &&
          runtimeType == other.runtimeType &&
          system == other.system;

  @override
  int get hashCode => system.hashCode;
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

  /// Create a ShipSymbol from a json string.
  factory ShipSymbol.fromJson(String json) => ShipSymbol.fromString(json);

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

  /// Returns the json representation of the ship symbol.
  String toJson() => symbol;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipSymbol &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          number == other.number;

  @override
  int get hashCode => name.hashCode ^ number.hashCode;
}

/// Extensions onto System to make it easier to work with.
extension SystemUtils on System {
  /// Returns the SystemSymbol of the system.
  SystemSymbol get systemSymbol => SystemSymbol.fromString(symbol);

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

/// Extensions onto ConnectedSystem to make it easier to work with.
extension ConnectedSystemUtils on ConnectedSystem {
  /// Returns the SystemSymbol of the system.
  SystemSymbol get systemSymbol => SystemSymbol.fromString(symbol);

  /// Returns the SystemPosition of the system.
  SystemPosition get position => SystemPosition(x, y);

  /// Returns the distance to the given system.
  int distanceTo(ConnectedSystem other) => position.distanceTo(other.position);
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

  /// symbol as a WaypointSymbol.
  WaypointSymbol get waypointSymbol => WaypointSymbol.fromString(symbol);

  /// The system symbol of the waypoint.
  SystemSymbol get systemSymbol => waypointSymbol.systemSymbol;

  /// Returns the WaypointPosition of the waypoint.
  WaypointPosition get position => WaypointPosition(x, y, systemSymbol);

  /// Returns the distance to the given waypoint.
  int distanceTo(SystemWaypoint other) => position.distanceTo(other.position);
}

/// Extensions onto Waypoint to make it easier to work with.
extension WaypointUtils on Waypoint {
  /// Returns the WaypointSymbol of the waypoint.
  WaypointSymbol get waypointSymbol => WaypointSymbol.fromString(symbol);

  /// The system symbol of the waypoint.
  SystemSymbol get systemSymbolObject => waypointSymbol.systemSymbol;

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
  bool hasTrait(WaypointTraitSymbolEnum trait) =>
      traits.any((t) => t.symbol == trait);

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
  WaypointPosition get position => WaypointPosition(x, y, systemSymbolObject);

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
  int countUnits(TradeSymbol tradeSymbol) {
    return cargoItem(tradeSymbol)?.units ?? 0;
  }

  /// Returns the ShipCargoItem for the given trade good or null if the cargo
  /// doesn't have that good.
  ShipCargoItem? cargoItem(TradeSymbol tradeSymbol) {
    return inventory.firstWhereOrNull((i) => i.symbol == tradeSymbol.value);
  }
}

/// Extensions onto Ship to make it easier to work with.
extension ShipUtils on Ship {
  /// Returns the ShipSymbol of the ship.
  ShipSymbol get shipSymbol => ShipSymbol.fromString(symbol);

  /// Returns the current SystemSymbol of the ship.
  SystemSymbol get systemSymbol => SystemSymbol.fromString(nav.systemSymbol);

  /// Returns the current WaypointSymbol of the ship.
  WaypointSymbol get waypointSymbol =>
      WaypointSymbol.fromString(nav.waypointSymbol);

  /// Returns the emoji name of the ship.
  String get emojiName {
    // Ships are all AGENT_SYMBOL-1, AGENT_SYMBOL-2, etc.
    final number = symbol.split('-').last;
    return '🛸#$number';
  }

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

  /// Attempt to munge ths ship's cache to reflect the added cargo.
  void updateCacheWithAddedCargo(TradeSymbol tradeSymbol, int units) {
    final item = cargo.cargoItem(tradeSymbol);
    if (item == null) {
      final inventory = cargo.inventory.toList()
        ..add(
          ShipCargoItem(
            symbol: tradeSymbol.value,
            name: tradeSymbol.value,
            description: tradeSymbol.value,
            units: 0,
          ),
        );
      // We may have to replace the list because it defaults to const [] which
      // is immutable.
      cargo.inventory = inventory;
    }
    cargo.cargoItem(tradeSymbol)!.units += units;
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

  /// Returns true if the ship is a command ship.
  bool get isCommand => registration.role == ShipRole.COMMAND;

  /// Returns true if the ship is an excavator.
  bool get isExcavator => registration.role == ShipRole.EXCAVATOR;

  /// Returns true if the ship is a probe.
  bool get isProbe => frame.symbol == ShipFrameSymbolEnum.PROBE;

  /// Returns true if the ship is a hauler.
  bool get isHauler =>
      frame.symbol == ShipFrameSymbolEnum.LIGHT_FREIGHTER ||
      frame.symbol == ShipFrameSymbolEnum.HEAVY_FREIGHTER;

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
    const surveyerMounts = {
      ShipMountSymbolEnum.SURVEYOR_I,
      ShipMountSymbolEnum.SURVEYOR_II,
      ShipMountSymbolEnum.SURVEYOR_III,
    };
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

/// Extensions onto ShipNav to make it easier to work with.
extension ShipNavUtils on ShipNav {
  /// Returns the current SystemSymbol of the ship.
  SystemSymbol get systemSymbolObject => SystemSymbol.fromString(systemSymbol);

  /// Returns the current WaypointSymbol of the ship.
  WaypointSymbol get waypointSymbolObject =>
      WaypointSymbol.fromString(waypointSymbol);
}

/// Extensions onto Contract to make it easier to work with.
extension ContractUtils on Contract {
  // bool needsItem(String tradeSymbol) => goodNeeded(tradeSymbol) != null;

  /// Returns the ContractDeliverGood for the given trade good symbol or null if
  /// the contract doesn't need that good.
  ContractDeliverGood? goodNeeded(TradeSymbol tradeSymbol) {
    return terms.deliver
        .firstWhereOrNull((item) => item.tradeSymbol == tradeSymbol.value);
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

  /// Destination as a WaypointSymbol.
  WaypointSymbol get destination =>
      WaypointSymbol.fromString(destinationSymbol);

  /// Returns tradeSymbol as a TradeSymbol object.
  TradeSymbol get tradeSymbolObject => TradeSymbol.fromJson(tradeSymbol)!;
}

/// Extensions onto SurveyDeposit to make it easier to work with.
extension SurveyDepositUtils on SurveyDeposit {
  /// Returns symbol as a TradeSymbol object.
  TradeSymbol get tradeSymbol => TradeSymbol.fromJson(symbol)!;
}

/// Extensions onto ShipCargoItem to make it easier to work with.
extension ShipCargoItemUtils on ShipCargoItem {
  /// Returns symbol as a TradeSymbol object.
  TradeSymbol get tradeSymbol => TradeSymbol.fromJson(symbol)!;
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
  /// Returns the WaypointSymbol of the market.
  WaypointSymbol get waypointSymbol => WaypointSymbol.fromString(symbol);

  /// Returns the SystemSymbol of the market.
  SystemSymbol get systemSymbol => waypointSymbol.systemSymbol;

  /// Returns the TradeType for the given trade symbol or null if the market
  /// doesn't trade that good.
  ExchangeType? exchangeType(TradeSymbol tradeSymbol) {
    if (imports.any((g) => g.symbol == tradeSymbol)) {
      return ExchangeType.imports;
    }
    if (exports.any((g) => g.symbol == tradeSymbol)) {
      return ExchangeType.exports;
    }
    if (exchange.any((g) => g.symbol == tradeSymbol)) {
      return ExchangeType.exchange;
    }
    return null;
  }

  /// Returns true if the market allows trading of the given trade symbol.
  bool allowsTradeOf(TradeSymbol tradeSymbol) =>
      exchangeType(tradeSymbol) != null;

  /// Returns [MarketTradeGood] for the given trade symbol or null if the market
  /// doesn't trade that good.
  MarketTradeGood? marketTradeGood(TradeSymbol tradeSymbol) =>
      tradeGoods.firstWhereOrNull((g) => g.symbol == tradeSymbol.value);

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

/// Extensions onto MarketTradeGood to make it easier to work with.
extension MarketTradeGoodUtils on MarketTradeGood {
  /// Returns symbol as a TradeSymbol object.
  TradeSymbol get tradeSymbol => TradeSymbol.fromJson(symbol)!;
}

/// Extensions onto Shipyard to make it easier to work with.
extension ShipyardUtils on Shipyard {
  /// Returns the WaypointSymbol for the shipyard.
  WaypointSymbol get waypointSymbol => WaypointSymbol.fromString(symbol);

  /// Returns true if the Shipyard has the given ship type.
  bool hasShipType(ShipType shipType) =>
      shipTypes.any((s) => s.type == shipType);
}

/// Extensions onto MarketTransaction to make it easier to work with.
extension MarketTransactionUtils on MarketTransaction {
  /// Returns the TradeSymbol for the given transaction.
  TradeSymbol get tradeSymbolObject => TradeSymbol.fromJson(tradeSymbol)!;

  /// Returns the ShipSymbol for the given transaction.
  ShipSymbol get shipSymbolObject => ShipSymbol.fromString(shipSymbol);

  /// Returns the WaypointSymbol for the given transaction.
  WaypointSymbol get waypointSymbolObject =>
      WaypointSymbol.fromString(waypointSymbol);
}

/// Extensions onto ShipyardTransaction to make it easier to work with.
extension ShipyardTransactionUtils on ShipyardTransaction {
  // Note: shipSymbol on the transaction is actually shipType.
  /// Returns the ShipType purchased in the transaction.
  ShipType get shipType => ShipType.fromJson(shipSymbol)!;

  /// Returns the WaypointSymbol for the given transaction.
  WaypointSymbol get waypointSymbolObject =>
      WaypointSymbol.fromString(waypointSymbol);
}

/// Extensions onto ShipModificationTransaction to make it easier to work with.
extension ShipModificationTransactionUtils on ShipModificationTransaction {
  /// Returns the ShipSymbol for the given transaction.
  ShipSymbol get shipSymbolObject => ShipSymbol.fromString(shipSymbol);

  /// Returns the WaypointSymbol for the given transaction.
  WaypointSymbol get waypointSymbolObject =>
      WaypointSymbol.fromString(waypointSymbol);
}

/// Extensions onto Faction to make it easier to work with.
extension FactionUtils on Faction {
  /// Returns the WaypointSymbol for the faction headquarters.
  WaypointSymbol get headquartersSymbol =>
      WaypointSymbol.fromString(headquarters);
}

/// Extensions onto Agent to make it easier to work with.
extension AgentUtils on Agent {
  /// Returns the WaypointSymbol for the agent headquarters.
  WaypointSymbol get headquartersSymbol =>
      WaypointSymbol.fromString(headquarters);
}

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

/// Compute the trade symbol for the given mount symbol.
/// TradeSymbols are a superset of ShipMountSymbols so this should never fail.
TradeSymbol tradeSymbolForMountSymbol(ShipMountSymbolEnum mountSymbol) {
  return TradeSymbol.fromJson(mountSymbol.value)!;
}

/// Compute the mount symbol for the given trade symbol.
/// This will return null if the trade symbol is not a mount symbol.
ShipMountSymbolEnum? mountSymbolForTradeSymbol(TradeSymbol tradeSymbol) {
  return ShipMountSymbolEnum.fromJson(tradeSymbol.value);
}
