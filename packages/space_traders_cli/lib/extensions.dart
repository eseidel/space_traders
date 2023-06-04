import 'package:collection/collection.dart';
import 'package:space_traders_api/api.dart';

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

/// Extensions onto System to make it easier to work with.
extension SystemUtils on System {
  /// Returns true if the system has a jump gate.
  bool get hasJumpGate =>
      waypoints.any((w) => w.type == WaypointType.JUMP_GATE);
}

/// Extensions onto Waypoint to make it easier to work with.
extension WaypointUtils on Waypoint {
  /// Returns true if the waypoint has the given trait.
  bool hasTrait(WaypointTraitSymbolEnum trait) {
    return traits.any((t) => t.symbol == trait);
  }

  /// Returns true if the waypoint has the given type.
  bool isType(WaypointType type) {
    return this.type == type;
  }

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
}

/// Extensions onto ShipCargo to make it easier to work with.
extension CargoUtils on ShipCargo {
  /// Returns the amount of cargo space available on the ship.
  int get availableSpace => capacity - units;
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
    final maybeCargo = cargo.inventory.firstWhereOrNull(
      (i) => i.symbol == tradeSymbol,
    );
    return maybeCargo?.units ?? 0;
  }

  /// Returns true if the ship if full on fuel.
  bool get isFuelFull => fuel.current >= fuel.capacity;

  /// Returns true if the ship should refuel.
  // One fuel bought from the market is 100 units of fuel in the ship.
  // For repeated short trips, avoiding buying fuel when we're close to full.
  bool get shouldRefuel => fuel.current < (fuel.capacity - 100);

  /// Returns the amount of space available on the ship.
  int get availableSpace => cargo.availableSpace;

  /// Returns true if the ship is an excavator.
  bool get isExcavator => registration.role == ShipRole.EXCAVATOR;

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
