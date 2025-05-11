import 'package:collection/collection.dart';
import 'package:types/types.dart';

export 'package:openapi/api.dart'
    hide Agent, Contract, JumpGate, Ship, System, SystemWaypoint, Waypoint;

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
    canWarp: modules.any((m) => m.symbol == ShipModuleSymbolEnum.WARP_DRIVE_I),
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
  TradeSymbol get tradeSymbol => symbol;
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
      imports.followedBy(exports).followedBy(exchange);

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

/// Extensions onto ScrapTransaction to make it easier to work with.
extension ScrapTransactionUtils on ScrapTransaction {
  /// Returns the ShipSymbol for the given transaction.
  ShipSymbol get shipSymbolObject => ShipSymbol.fromString(shipSymbol);

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
      WaypointSymbol.fromString(headquarters!);

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
