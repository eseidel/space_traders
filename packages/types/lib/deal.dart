import 'package:meta/meta.dart';
import 'package:types/types.dart';

/// Record of a possible arbitrage opportunity pairing a BuyOpp and SellOpp.
/// CostedDeal is a wrapper which includes the cost of travel.
@immutable
class Deal {
  /// Create a new Deal from a source and destination.
  Deal({required this.source, required this.destination})
      : assert(
          source.waypointSymbol != destination.waypointSymbol,
          'source and destination must be different',
        ),
        assert(
          source.tradeSymbol == destination.tradeSymbol,
          'source and destination must have the same tradeSymbol',
        );

  /// Create a test deal.
  @visibleForTesting
  factory Deal.test({
    required WaypointSymbol sourceSymbol,
    required WaypointSymbol destinationSymbol,
    required TradeSymbol tradeSymbol,
    required int purchasePrice,
    required int sellPrice,
  }) {
    return Deal(
      source: BuyOpp(
        MarketPrice(
          waypointSymbol: sourceSymbol,
          symbol: tradeSymbol,
          supply: SupplyLevel.ABUNDANT,
          purchasePrice: purchasePrice,
          sellPrice: purchasePrice + 1,
          tradeVolume: 100,
          // If these aren't UTC, they won't roundtrip through JSON correctly
          // because MarketPrice always converts to UTC in toJson.
          timestamp: DateTime(2021).toUtc(),
          activity: ActivityLevel.WEAK,
        ),
      ),
      destination: SellOpp.fromMarketPrice(
        MarketPrice(
          waypointSymbol: destinationSymbol,
          symbol: tradeSymbol,
          supply: SupplyLevel.ABUNDANT,
          purchasePrice: sellPrice - 1,
          sellPrice: sellPrice,
          tradeVolume: 100,
          timestamp: DateTime(2021).toUtc(),
          activity: ActivityLevel.WEAK,
        ),
      ),
    );
  }

  /// Create a deal from JSON.
  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      source: BuyOpp.fromJson(json['source'] as Map<String, dynamic>),
      destination:
          SellOpp.fromJson(json['destination'] as Map<String, dynamic>),
    );
  }

  /// The trade symbol that we're selling.
  TradeSymbol get tradeSymbol => source.tradeSymbol;

  /// Where we get the goods from.
  final BuyOpp source;

  /// Where we take the goods to.
  final SellOpp destination;

  /// The symbol of the market we're buying from.
  WaypointSymbol get sourceSymbol => source.waypointSymbol;

  /// The symbol of where this deal is going.
  WaypointSymbol get destinationSymbol => destination.waypointSymbol;

  /// The id of the contract this deal is a part of.
  String? get contractId => destination.contractId;

  /// The maximum number of units we can trade in this deal.
  /// This is only used for contract deliveries.  Null means unlimited.
  int? get maxUnits => destination.maxUnits;

  /// Whether this deal is a contract deal.
  /// Contract deals are very similar to arbitrage deals except:
  /// 1. The destination market is predetermined.
  /// 2. Trade volume is predetermined and coordinated across all ships.
  /// 3. Contract deals only pay out on completed contracts, not for individual
  ///    deliveries, thus they are only viable when we have enough capital
  ///    to expect to complete the contract.
  /// 4. Behavior at destinations is different ("fulfill" instead of "sell").
  /// 5. We treat the "sell" price as the total reward of contract divided by
  ///    the number of units of cargo we need to deliver.
  bool get isContractDeal => destination.isContractDelivery;

  /// Whether this deal is a construction deal.
  bool get isConstructionDelivery => destination.isConstructionDelivery;

  /// Whether this deal is a feeder deal allowed to go negative.
  bool get isFeeder => destination.isFeeder;

  /// Encode the deal as JSON.
  Map<String, dynamic> toJson() => {
        'source': source.toJson(),
        'destination': destination.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Deal &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          destination == other.destination;

  @override
  int get hashCode => Object.hash(
        source,
        destination,
      );
}

/// A deal between two markets which considers flight cost and time.
// This could be made immutable with a bit of work.
// Currently this contains Transactions, which should instead be held separately
// in the db.
class CostedDeal {
  /// Create a new CostedDeal.
  CostedDeal({
    required this.deal,
    required List<Transaction> transactions,
    required this.startTime,
    required this.route,
    required this.cargoSize,
    required this.costPerFuelUnit,
  })  : transactions = List.unmodifiable(transactions),
        assert(cargoSize > 0, 'cargoSize must be > 0');

  /// Create a CostedDeal from JSON.
  factory CostedDeal.fromJson(Map<String, dynamic> json) => CostedDeal(
        deal: Deal.fromJson(json['deal'] as Map<String, dynamic>),
        cargoSize: json['cargoSize'] as int? ?? json['tradeVolume'] as int,
        startTime: DateTime.parse(json['startTime'] as String),
        route: RoutePlan.fromJson(json['route'] as Map<String, dynamic>),
        transactions: (json['transactions'] as List<dynamic>)
            .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
            .toList(),
        costPerFuelUnit: json['costPerFuelUnit'] as int,
      );

  /// Create a CostedDeal from JSON or null.
  static CostedDeal? fromJsonOrNull(Map<String, dynamic>? json) =>
      json == null ? null : CostedDeal.fromJson(json);

  /// The id of the contract this deal is a part of.
  String? get contractId => deal.contractId;

  /// Whether this deal is a contract deal.
  bool get isContractDeal => deal.isContractDeal;

  /// Whether this deal is a construction deal.
  bool get isConstructionDeal => deal.isConstructionDelivery;

  /// Whether this deal is a feeder deal allowed to go negative.
  bool get isFeeder => deal.isFeeder;

  /// The deal being considered.
  final Deal deal;

  /// The number of units of cargo this deal was priced for.
  final int cargoSize;

  /// The cost per unit of fuel used for computing expected fuel costs.
  final int costPerFuelUnit;

  /// The units of fuel to travel along the route.
  int get expectedFuelUsed => route.fuelUsed;

  /// The cost of fuel to travel along the route.
  int get expectedFuelCost => (expectedFuelUsed / 100).ceil() * costPerFuelUnit;

  /// The time in seconds to travel between the two markets.
  Duration get expectedTime => route.duration;

  /// The time at which this deal was started.
  final DateTime startTime;

  /// The route taken to complete this deal.
  final RoutePlan route;

  /// The transactions made as a part of executing this deal.
  // It's possible these should be stored separately and composed in
  // to make a CompletedDeal?
  // That would also remove all the expected* prefixes from fields since
  // there would be no actual to compare against.
  final List<Transaction> transactions;

  /// The symbol of the trade good being traded.
  TradeSymbol get tradeSymbol => deal.tradeSymbol;

  /// Convert this CostedDeal to JSON.
  Map<String, dynamic> toJson() => {
        'deal': deal.toJson(),
        'expectedFuelCost': expectedFuelCost,
        'cargoSize': cargoSize,
        'contractId': contractId,
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'startTime': startTime.toUtc().toIso8601String(),
        'route': route.toJson(),
        'costPerFuelUnit': costPerFuelUnit,
      };

  /// Return a new CostedDeal with the given transactions added.
  CostedDeal byAddingTransactions(List<Transaction> transactions) {
    return CostedDeal(
      deal: deal,
      cargoSize: cargoSize,
      transactions: [...this.transactions, ...transactions],
      startTime: startTime,
      route: route,
      costPerFuelUnit: costPerFuelUnit,
    );
  }
}
