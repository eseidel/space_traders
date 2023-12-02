import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:types/types.dart';

/// A potential pickup opportunity.
@immutable
class BuyOpp extends Equatable {
  /// Create a new BuyOpp.
  const BuyOpp(this.marketPrice);

  /// Create a new BuyOpp from JSON.
  factory BuyOpp.fromJson(Map<String, dynamic> json) {
    return BuyOpp(
      MarketPrice.fromJson(json['marketPrice'] as Map<String, dynamic>),
    );
  }

  /// State of the market where this buy opportunity was found.
  final MarketPrice marketPrice;

  @override
  List<Object> get props => [marketPrice];

  /// The symbol of the market where the good can be purchased.
  WaypointSymbol get waypointSymbol => marketPrice.waypointSymbol;

  /// The symbol of the good offered for purchase.
  TradeSymbol get tradeSymbol => marketPrice.tradeSymbol;

  /// The price of the good.
  int get price => marketPrice.purchasePrice;

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'marketPrice': marketPrice.toJson(),
    };
  }
}

/// A potential delivery opportunity.
@immutable
class SellOpp extends Equatable {
  /// Create a new SellOpp from a MarketPrice.
  SellOpp.fromMarketPrice(
    MarketPrice this.marketPrice, {
    this.isFeeder = false,
  })  : waypointSymbol = marketPrice.waypointSymbol,
        tradeSymbol = marketPrice.tradeSymbol,
        price = marketPrice.sellPrice,
        contractId = null,
        maxUnits = null;

  /// Create a new SellOpp from a contract.
  const SellOpp.fromContract({
    required this.waypointSymbol,
    required this.tradeSymbol,
    required this.price,
    required this.contractId,
    required this.maxUnits,
  })  : marketPrice = null,
        isFeeder = false;

  /// Create a new SellOpp from a construction.
  const SellOpp.fromConstruction({
    required this.waypointSymbol,
    required this.tradeSymbol,
    required this.price,
    required this.maxUnits,
  })  : marketPrice = null,
        contractId = null,
        isFeeder = false;

  /// Create a new SellOpp from JSON.
  SellOpp.fromJson(Map<String, dynamic> json)
      : marketPrice = MarketPrice.fromJsonOrNull(
          json['marketPrice'] as Map<String, dynamic>?,
        ),
        waypointSymbol = WaypointSymbol.fromJson(
          json['waypointSymbol'] as String,
        ),
        tradeSymbol = TradeSymbol.fromJson(json['tradeSymbol'] as String)!,
        price = json['price'] as int,
        contractId = json['contractId'] as String?,
        maxUnits = json['maxUnits'] as int?,
        isFeeder = json['isFeeder'] as bool? ?? false;

  /// State of the market where this sell opportunity was found.
  final MarketPrice? marketPrice;

  /// The symbol of the good can be delivered.
  final WaypointSymbol waypointSymbol;

  /// The symbol of the good offered for sold.
  final TradeSymbol tradeSymbol;

  /// This is really "reward per unit" or "initial reward per unit".
  final int price;

  /// Set to the contractId for contract deliveries.
  final String? contractId;

  /// True if this is a market feeding job (allowed to go negative).
  final bool isFeeder;

  /// The maximum number of units we can sell/deliver.
  /// This is only used for contract or construction deliveries when the
  /// delivery is nearly complete.
  final int? maxUnits;

  @override
  List<Object?> get props => [
        marketPrice,
        waypointSymbol,
        tradeSymbol,
        price,
        contractId,
        maxUnits,
        isFeeder,
      ];

  /// True if this is a contract delivery.
  bool get isContractDelivery => contractId != null;

  /// True if this is a construction delivery.
  // This is kinda hacky, might need a better way to distinguish between
  // contract deliveries and construction deliveries.
  bool get isConstructionDelivery {
    return contractId == null && marketPrice == null;
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'marketPrice': marketPrice?.toJson(),
      'waypointSymbol': waypointSymbol.toJson(),
      'tradeSymbol': tradeSymbol.toJson(),
      'price': price,
      'contractId': contractId,
      'maxUnits': maxUnits,
    };
  }
}
