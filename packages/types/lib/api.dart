import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:openapi/api.dart'
    hide Agent, Contract, JumpGate, System, SystemWaypoint, Waypoint;
import 'package:types/src/mount.dart';
import 'package:types/src/position.dart';
import 'package:types/src/symbol.dart';

export 'package:openapi/api.dart'
    hide Agent, Contract, JumpGate, System, SystemWaypoint, Waypoint;

/// The default implementation of getNow for production.
/// Used for tests for overriding the current time.
DateTime defaultGetNow() => DateTime.timestamp();

/// Returns true if the given trait is minable.
bool isMinableTrait(WaypointTraitSymbol trait) {
  return trait.value.endsWith('DEPOSITS');
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
  int countUnits(TradeSymbol tradeSymbol) => cargoItem(tradeSymbol)?.units ?? 0;

  /// Returns the ShipCargoItem for the given trade good or null if the cargo
  /// doesn't have that good.
  ShipCargoItem? cargoItem(TradeSymbol tradeSymbol) {
    return inventory.firstWhereOrNull((i) => i.symbol == tradeSymbol);
  }
}

/// Class to hold common ship traits needed for route planning.
class ShipSpec {
  /// Construct a ShipSpec.
  const ShipSpec({
    required this.cargoCapacity,
    required this.fuelCapacity,
    required this.speed,
    this.canWarp = false,
  });

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
}

/// Extensions onto Ship to make it easier to work with.
extension ShipUtils on Ship {
  /// Returns the ShipSymbol of the ship.
  ShipSymbol get shipSymbol => ShipSymbol.fromString(symbol);

  /// Returns the current SystemSymbol of the ship.
  SystemSymbol get systemSymbol => nav.systemSymbolObject;

  /// Returns the current WaypointSymbol of the ship.
  WaypointSymbol get waypointSymbol => nav.waypointSymbolObject;

  /// Returns the emoji name of the ship.
  String get emojiName {
    // Ships are all AGENT_SYMBOL-1, AGENT_SYMBOL-2, etc.
    final number = symbol.split('-').last;
    return '🛸#$number';
  }

  /// Returns the ShipSpec for the ship.
  ShipSpec get shipSpec => ShipSpec(
        cargoCapacity: cargo.capacity,
        fuelCapacity: fuel.capacity,
        speed: engine.speed,
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

  /// Attempt to munge ths ship's cache to reflect the added cargo.
  void updateCacheWithAddedCargo({
    required TradeSymbol tradeSymbol,
    required int units,
    required String name,
    required String description,
  }) {
    if (cargo.availableSpace < units) {
      throw ArgumentError(
        'Not enough space for $units units of $tradeSymbol in $cargo',
      );
    }
    final item = cargo.cargoItem(tradeSymbol);
    if (item == null) {
      final inventory = cargo.inventory.toList()
        ..add(
          ShipCargoItem(
            symbol: tradeSymbol,
            name: name,
            description: description,
            // Add intially with zero, we're about to add units below.
            units: 0,
          ),
        );
      // We may have to replace the list because it defaults to const [] which
      // is immutable.
      cargo.inventory = inventory;
    }
    cargo.cargoItem(tradeSymbol)!.units += units;
    cargo.units += units;
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
  bool get isMiner => frame.symbol == ShipFrameSymbolEnum.MINER;

  /// Returns true if the ship is a probe.
  bool get isProbe => frame.symbol == ShipFrameSymbolEnum.PROBE;

  /// Returns true if the ship is an explorer.
  bool get isExplorer => frame.symbol == ShipFrameSymbolEnum.EXPLORER;

  /// Returns true if the ship is a hauler.
  bool get isHauler =>
      frame.symbol == ShipFrameSymbolEnum.LIGHT_FREIGHTER ||
      frame.symbol == ShipFrameSymbolEnum.HEAVY_FREIGHTER ||
      frame.symbol == ShipFrameSymbolEnum.EXPLORER ||
      frame.symbol == ShipFrameSymbolEnum.SHUTTLE;

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
      modules.any((m) => m.symbol == ShipModuleSymbolEnum.ORE_REFINERY_I);

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
    return Ship.fromJson(jsonDecode(jsonEncode(toJson())))!;
  }
}

/// Extensions onto ShipyardShip to make it easier to work with.
extension ShipyardShipUtils on ShipyardShip {
  /// Compute the cargo capacity of the ship.
  int get cargoCapacity {
    return modules
        .where((m) => kCargoModules.contains(m.symbol))
        .map((m) => m.capacity!)
        .sum;
  }

  /// Returns the ShipSpec for the ship.
  ShipSpec get shipSpec => ShipSpec(
        cargoCapacity: cargoCapacity,
        fuelCapacity: frame.fuelCapacity,
        speed: engine.speed,
        canWarp:
            modules.any((m) => m.symbol == ShipModuleSymbolEnum.WARP_DRIVE_I),
      );

  /// Compute the current crew of the ship.
  int get currentCrew {
    var current = 0;
    current += frame.requirements.crew ?? 0;
    current += reactor.requirements.crew ?? 0;
    current += engine.requirements.crew ?? 0;
    current += mounts.map((m) => m.requirements.crew ?? 0).sum;
    current += modules.map((m) => m.requirements.crew ?? 0).sum;
    return current;
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

/// Extensions onto ShipNavRoute to make it easier to work with.
extension ShipNavRouteUtils on ShipNavRoute {
  /// Returns the WaypointSymbol of the origin of the route.
  WaypointSymbol get originSymbol => WaypointSymbol.fromString(origin.symbol);

  /// Returns the WaypointSymbol of the destination of the route.
  WaypointSymbol get destinationSymbol =>
      WaypointSymbol.fromString(destination.symbol);

  /// Returns the distance between the origin and destination.
  /// Only makes sense for nav routes, not warp routes.
  double get distance => origin.distanceTo(destination);

  /// Returns the duration of the route.
  Duration get duration => arrival.difference(departureTime);

  /// Returns the duration until the ship arrives at the destination or
  /// Duration.zero if the ship has already arrived.
  Duration timeUntilArrival({DateTime Function() getNow = defaultGetNow}) {
    final now = getNow();
    if (now.isAfter(arrival)) {
      return Duration.zero;
    }
    return arrival.difference(now);
  }
}

/// Extensions onto ShipNavRouteWaypointUtils to make it easier to work with.
extension ShipNavRouteWaypointUtils on ShipNavRouteWaypoint {
  /// Returns the WaypointSymbol of the waypoint.
  WaypointSymbol get waypointSymbol => WaypointSymbol.fromString(symbol);

  /// Returns the SystemSymbol of the waypoint.
  SystemSymbol get systemSymbolObject => SystemSymbol.fromString(systemSymbol);

  /// Returns the WaypointPosition of the waypoint.
  WaypointPosition get position => WaypointPosition(x, y, systemSymbolObject);

  /// Returns the distance to the given waypoint.
  double distanceTo(ShipNavRouteWaypoint other) =>
      position.distanceTo(other.position);
}

/// Extensions onto ContractDeliverGood to make it easier to work with.
extension ContractDeliverGoodUtils on ContractDeliverGood {
  /// Returns the amount of the given trade good the contract needs.
  int get remainingNeeded => unitsRequired - unitsFulfilled;

  /// Destination as a WaypointSymbol.
  WaypointSymbol get destination =>
      WaypointSymbol.fromString(destinationSymbol);

  /// Returns tradeSymbol as a TradeSymbol object.
  TradeSymbol get tradeSymbolObject => TradeSymbol.fromJson(tradeSymbol)!;
}

/// Extensions onto Survey to make it easier to work with.
extension SurveyUtils on Survey {
  /// Returns the WaypointSymbol of the survey.
  WaypointSymbol get waypointSymbol => WaypointSymbol.fromString(symbol);

  /// Returns tradeSymbols for all deposits.
  Set<TradeSymbol> get tradeSymbols =>
      Set.from(deposits.map((d) => d.tradeSymbol));
}

/// Extensions onto SurveyDeposit to make it easier to work with.
extension SurveyDepositUtils on SurveyDeposit {
  /// Returns symbol as a TradeSymbol object.
  TradeSymbol get tradeSymbol => TradeSymbol.fromJson(symbol)!;
}

/// Extensions onto ShipCargoItem to make it easier to work with.
extension ShipCargoItemUtils on ShipCargoItem {
  /// Returns symbol as a TradeSymbol object.
  TradeSymbol get tradeSymbol => symbol;
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
  SystemSymbol get systemSymbol => waypointSymbol.system;

  /// Returns the all trade goods for the market.
  /// Unknown if there can be duplicates or not.
  Iterable<TradeGood> get listedTradeGoods =>
      imports.followedBy(exports).followedBy(
            exchange,
          );

  /// Returns [MarketTradeGood] for the given trade symbol or null if the market
  /// doesn't trade that good.
  MarketTradeGood? marketTradeGood(TradeSymbol tradeSymbol) =>
      tradeGoods.firstWhereOrNull((g) => g.symbol == tradeSymbol);
}

/// Extensions onto MarketTradeGood to make it easier to work with.
extension MarketTradeGoodUtils on MarketTradeGood {
  /// Returns symbol as a TradeSymbol object.
  TradeSymbol get tradeSymbol => symbol;
}

/// Extensions onto Shipyard to make it easier to work with.
extension ShipyardUtils on Shipyard {
  /// Returns the WaypointSymbol for the shipyard.
  WaypointSymbol get waypointSymbol => WaypointSymbol.fromString(symbol);
}

/// Extensions onto Construction to make it easier to work with.
extension ConstructionUtils on Construction {
  /// Returns the WaypointSymbol for the construction.
  WaypointSymbol get waypointSymbol => WaypointSymbol.fromString(symbol);

  /// Returns the SystemSymbol for the construction.
  SystemSymbol get systemSymbol => waypointSymbol.system;

  /// Returns the amount of the given trade good the construction needs.
  ConstructionMaterial? materialNeeded(TradeSymbol tradeSymbol) {
    return materials.firstWhereOrNull((m) => m.tradeSymbol == tradeSymbol);
  }
}

/// Extensions onto ConstructionMaterial to make it easier to work with.
extension ConstructionMaterialUtils on ConstructionMaterial {
  /// Returns the amount of the given trade good the construction still needs.
  int get remainingNeeded => required_ - fulfilled;

  /// Returns true if this construction material has been fulfilled.
  bool get isFulfilled => remainingNeeded == 0;
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
  /// Returns the ShipType purchased in the transaction.
  ShipType get shipTypeObject => ShipType.fromJson(shipType)!;

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

  /// Returns the SystemSymbol for the faction headquarters.
  SystemSymbol get headquartersSystemSymbol => headquartersSymbol.system;
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

/// Extensions onto SupplyLevel to make it easier to work with.
extension SupplyLevelUtils on SupplyLevel {
  /// Returns the index of the supply level.
  int get index => SupplyLevel.values.indexOf(this);

  /// Returns true if the supply level is at least the given level.
  bool isAtLeast(SupplyLevel level) => index >= level.index;
}
