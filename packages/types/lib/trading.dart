import 'package:meta/meta.dart';
import 'package:types/types.dart';

/// A potential purchase opportunity.
@immutable
class BuyOpp {
  /// Create a new BuyOpp.
  const BuyOpp(this.marketPrice);

  /// State of the market where this buy opportunity was found.
  final MarketPrice marketPrice;

  /// The symbol of the market where the good can be purchased.
  WaypointSymbol get marketSymbol => marketPrice.waypointSymbol;

  /// The symbol of the good offered for purchase.
  TradeSymbol get tradeSymbol => marketPrice.tradeSymbol;

  /// The price of the good.
  int get price => marketPrice.purchasePrice;
}

/// A potential sale opportunity.  Only public for testing.
@immutable
class SellOpp {
  /// Create a new SellOpp from a MarketPrice.
  SellOpp.fromMarketPrice(MarketPrice this.marketPrice)
      : marketSymbol = marketPrice.waypointSymbol,
        tradeSymbol = marketPrice.tradeSymbol,
        price = marketPrice.sellPrice,
        contractId = null,
        maxUnits = null;

  /// Create a new SellOpp from a contract.
  const SellOpp.fromContract({
    required this.marketSymbol,
    required this.tradeSymbol,
    required this.price,
    required this.contractId,
    required this.maxUnits,
  }) : marketPrice = null;

  const SellOpp.fromConstruction({
    required this.marketSymbol,
    required this.tradeSymbol,
    required this.price,
    required this.maxUnits,
  })  : marketPrice = null,
        contractId = null;

  /// State of the market where this sell opportunity was found.
  final MarketPrice? marketPrice;

  /// The symbol of the good can be delivered.
  final WaypointSymbol marketSymbol;

  /// The symbol of the good offered for sold.
  final TradeSymbol tradeSymbol;

  /// The price of the good.
  final int price;

  /// Set to the contractId for contract deliveries.
  final String? contractId;

  /// The maximum number of units we can sell.
  /// This is only used for contract deliveries towards the very end of
  /// a contract.
  final int? maxUnits;
}
