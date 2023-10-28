import 'package:meta/meta.dart';
import 'package:types/types.dart';

/// A delivery for a contract.
@immutable
class ContractDelivery {
  /// Create a new ContractDelivery.
  const ContractDelivery({
    required this.contractId,
    required this.destination,
    required this.tradeSymbol,
    required this.rewardPerUnit,
    required this.maxUnits,
  });

  /// Create a ContractDelivery from a SellOpp.
  factory ContractDelivery.fromSellOpp(SellOpp sellOpp) {
    return ContractDelivery(
      tradeSymbol: sellOpp.tradeSymbol,
      contractId: sellOpp.contractId!,
      destination: sellOpp.marketSymbol,
      rewardPerUnit: sellOpp.price,
      maxUnits: sellOpp.maxUnits!,
    );
  }

  /// Create a ContractDelivery from JSON.
  factory ContractDelivery.fromJson(Map<String, dynamic> json) {
    return ContractDelivery(
      contractId: json['contractId'] as String,
      destination: WaypointSymbol.fromJson(json['destination'] as String),
      tradeSymbol: TradeSymbol.fromJson(json['tradeSymbol'] as String)!,
      rewardPerUnit: json['rewardPerUnit'] as int,
      maxUnits: json['maxUnits'] as int,
    );
  }

  /// Which contract this delivery is a part of.
  final String contractId;

  /// The destination of this delivery.
  final WaypointSymbol destination;

  /// The trade symbol of the cargo to deliver.
  final TradeSymbol tradeSymbol;

  /// The maximum number of units of cargo to deliver.
  final int maxUnits;

  /// The reward per unit of cargo delivered.
  final int rewardPerUnit;

  /// Encode this ContractDelivery as JSON.
  Map<String, dynamic> toJson() => {
        'contractId': contractId,
        'destination': destination.toJson(),
        'tradeSymbol': tradeSymbol.toJson(),
        'rewardPerUnit': rewardPerUnit,
        'maxUnits': maxUnits,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContractDelivery &&
          runtimeType == other.runtimeType &&
          contractId == other.contractId &&
          destination == other.destination &&
          tradeSymbol == other.tradeSymbol &&
          rewardPerUnit == other.rewardPerUnit &&
          maxUnits == other.maxUnits;

  @override
  int get hashCode => Object.hash(
        contractId,
        destination,
        tradeSymbol,
        rewardPerUnit,
        maxUnits,
      );
}

/// Record of a possible arbitrage opportunity.
// This should also include expected cost of fuel and cost of time.
@immutable
class Deal {
  /// Create a new deal for a contract delivery.
  Deal.fromContractDelivery({
    required this.sourcePrice,
    required ContractDelivery this.contractDelivery,
  })  : destinationPrice = null,
        assert(
          sourcePrice.tradeSymbol == contractDelivery.tradeSymbol,
          'sourcePrice and contractDelivery must be for the same tradeSymbol',
        );

  /// Create a new deal for an arbitrage opportunity.
  Deal.fromMarketPrices({
    required this.sourcePrice,
    required MarketPrice this.destinationPrice,
  })  : contractDelivery = null,
        assert(
          sourcePrice.waypointSymbol != destinationPrice.waypointSymbol,
          'sourcePrice and destinationPrice must be for different markets',
        ),
        assert(
          sourcePrice.tradeSymbol == destinationPrice.tradeSymbol,
          'sourcePrice and destinationPrice must be for the same tradeSymbol',
        );

  /// Create a new deal from a BuyOpp and SellOpp.
  factory Deal.fromOpps(BuyOpp buyOpp, SellOpp sellOpp) {
    if (sellOpp.contractId != null) {
      return Deal.fromContractDelivery(
        sourcePrice: buyOpp.marketPrice,
        contractDelivery: ContractDelivery.fromSellOpp(sellOpp),
      );
    }
    return Deal.fromMarketPrices(
      sourcePrice: buyOpp.marketPrice,
      destinationPrice: sellOpp.marketPrice!,
    );
  }

  /// Create a test deal.
  @visibleForTesting
  factory Deal.test({
    required WaypointSymbol sourceSymbol,
    required WaypointSymbol destinationSymbol,
    required TradeSymbol tradeSymbol,
    required int purchasePrice,
    required int sellPrice,
  }) {
    return Deal.fromMarketPrices(
      sourcePrice: MarketPrice(
        waypointSymbol: sourceSymbol,
        symbol: tradeSymbol,
        supply: SupplyLevel.ABUNDANT,
        purchasePrice: purchasePrice,
        sellPrice: purchasePrice + 1,
        tradeVolume: 100,
        // If these aren't UTC, they won't roundtrip through JSON correctly
        // because MarketPrice always converts to UTC in toJson.
        timestamp: DateTime(2021).toUtc(),
      ),
      destinationPrice: MarketPrice(
        waypointSymbol: destinationSymbol,
        symbol: tradeSymbol,
        supply: SupplyLevel.ABUNDANT,
        purchasePrice: sellPrice - 1,
        sellPrice: sellPrice,
        tradeVolume: 100,
        timestamp: DateTime(2021).toUtc(),
      ),
    );
  }

  const Deal._({
    required this.sourcePrice,
    required this.destinationPrice,
    required this.contractDelivery,
  });

  /// Create a deal from JSON.
  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal._(
      sourcePrice: MarketPrice.fromJson(
        json['sourcePrice'] as Map<String, dynamic>,
      ),
      destinationPrice: json['destinationPrice'] == null
          ? null
          : MarketPrice.fromJson(
              json['destinationPrice'] as Map<String, dynamic>,
            ),
      contractDelivery: json['contractDelivery'] == null
          ? null
          : ContractDelivery.fromJson(
              json['contractDelivery'] as Map<String, dynamic>,
            ),
    );
  }

  /// The trade symbol that we're selling.
  TradeSymbol get tradeSymbol => sourcePrice.tradeSymbol;

  /// Market state at the source.
  final MarketPrice sourcePrice;

  /// Market state at the destination.
  final MarketPrice? destinationPrice;

  /// The contract this deal is a part of.
  /// Contract deals are very similar to arbitrage deals except:
  /// 1. The destination market is predetermined.
  /// 2. Trade volume is predetermined and coordinated across all ships.
  /// 3. Contract deals only pay out on completed contracts, not for individual
  ///    deliveries, thus they are only viable when we have enough capital
  ///    to expect to complete the contract.
  /// 4. Behavior at destinations is different ("fulfill" instead of "sell").
  /// 5. We treat the "sell" price as the total reward of contract divided by
  ///    the number of units of cargo we need to deliver.
  final ContractDelivery? contractDelivery;

  /// The symbol of the market we're buying from.
  WaypointSymbol get sourceSymbol => sourcePrice.waypointSymbol;

  /// The symbol of the market we're selling to.
  WaypointSymbol get destinationSymbol {
    final contract = contractDelivery;
    if (contract != null) {
      return contract.destination;
    }
    return destinationPrice!.waypointSymbol;
  }

  /// The id of the contract this deal is a part of.
  String? get contractId => contractDelivery?.contractId;

  /// The maximum number of units we can trade in this deal.
  /// This is only used for contract deliveries.  Null means unlimited.
  int? get maxUnits => contractDelivery?.maxUnits;

  /// Encode the deal as JSON.
  Map<String, dynamic> toJson() => {
        'sourcePrice': sourcePrice.toJson(),
        'destinationPrice': destinationPrice?.toJson(),
        'contractDelivery': contractDelivery?.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Deal &&
          runtimeType == other.runtimeType &&
          sourcePrice == other.sourcePrice &&
          destinationPrice == other.destinationPrice &&
          contractDelivery == other.contractDelivery;

  @override
  int get hashCode => Object.hash(
        sourcePrice,
        destinationPrice,
        contractDelivery,
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

  /// The id of the contract this deal is a part of.
  String? get contractId => deal.contractId;

  /// Whether this deal is a contract deal.
  bool get isContractDeal => deal.contractId != null;

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
