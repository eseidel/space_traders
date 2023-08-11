import 'package:cli/api.dart';
import 'package:db/transaction.dart';
import 'package:meta/meta.dart';

/// The accounting type of a transaction.
enum AccountingType {
  /// Capital transaction (e.g. ships, mounts).
  capital,

  /// Fuel transaction (e.g. fuel for transport, not for sale).
  fuel,

  /// Goods transaction (e.g. buying/selling trade goods).
  goods;

  /// Lookup an accounting type by name.
  static AccountingType fromName(String name) {
    return AccountingType.values.firstWhere((e) => e.name == name);
  }
}

/// The type of transaction which created this transaction.
enum TransactionType {
  /// A market transaction.
  market,

  /// A shipyard transaction.
  shipyard,

  /// A ship modification transaction.
  shipModification;

  /// Lookup a transaction type by index.
  static TransactionType fromName(String name) {
    return TransactionType.values.firstWhere((e) => e.name == name);
  }
}

/// A class to hold transaction data from a ship.
@immutable
class Transaction {
  /// Create a new transaction.
  const Transaction({
    required this.transactionType,
    required this.shipSymbol,
    required this.waypointSymbol,
    required this.tradeSymbol,
    required this.shipType,
    required this.tradeType,
    required this.quantity,
    required this.perUnitPrice,
    required this.timestamp,
    required this.agentCredits,
    required this.accounting,
  });

  /// Create a new transaction from json.
  /// This only exists to support CostedDeal.fromJson and should be removed.
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transactionType: TransactionType.values
          .firstWhere((e) => e.index == json['transactionType'] as int),
      shipSymbol: ShipSymbol.fromJson(json['shipSymbol'] as String),
      waypointSymbol: WaypointSymbol.fromJson(json['waypointSymbol'] as String),
      tradeSymbol: TradeSymbol.fromJson(json['tradeSymbol'] as String?),
      shipType: ShipType.fromJson(json['shipType'] as String?),
      quantity: json['quantity'] as int,
      tradeType: MarketTransactionTypeEnum.values
          .firstWhere((e) => e.value == json['tradeType'] as String),
      perUnitPrice: json['perUnitPrice'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      agentCredits: json['agentCredits'] as int,
      accounting: AccountingType.values
          .firstWhere((e) => e.name == json['accounting'] as String),
    );
  }

  /// Create a new transaction from json.
  factory Transaction.fromRecord(TransactionRecord record) {
    return Transaction(
      transactionType: TransactionType.fromName(record.transactionType),
      shipSymbol: ShipSymbol.fromJson(record.shipSymbol),
      waypointSymbol: WaypointSymbol.fromJson(record.waypointSymbol),
      tradeSymbol: TradeSymbol.fromJson(record.tradeSymbol),
      shipType: ShipType.fromJson(record.shipType),
      quantity: record.quantity,
      tradeType: MarketTransactionTypeEnum.fromJson(record.tradeType)!,
      perUnitPrice: record.perUnitPrice,
      timestamp: record.timestamp,
      agentCredits: record.agentCredits,
      accounting: AccountingType.fromName(record.accounting),
    );
  }

  /// Create a new transaction from a market transaction.
  factory Transaction.fromMarketTransaction(
    MarketTransaction transaction,
    int agentCredits,
    AccountingType accounting,
  ) {
    // Using a local to force non-null.
    final tradeSymbol = TradeSymbol.fromJson(transaction.tradeSymbol)!;
    return Transaction(
      transactionType: TransactionType.market,
      shipSymbol: transaction.shipSymbolObject,
      waypointSymbol: transaction.waypointSymbolObject,
      tradeSymbol: tradeSymbol,
      shipType: null,
      quantity: transaction.units,
      tradeType: transaction.type,
      perUnitPrice: transaction.pricePerUnit,
      timestamp: transaction.timestamp,
      agentCredits: agentCredits,
      accounting: accounting,
    );
  }

  /// Create a new transaction from a shipyard transaction.
  factory Transaction.fromShipyardTransaction(
    ShipyardTransaction transaction,
    int agentCredits,
    ShipSymbol purchaser,
  ) {
    // shipSymbol is the trade symbol for the shipyard transaction, not
    // the new ship's id.
    // Using a local to force non-null.
    final shipType = ShipType.fromJson(transaction.shipSymbol)!;
    return Transaction(
      transactionType: TransactionType.shipyard,
      // .shipSymbol is the new ship type, not a ShipSymbol involved
      // in the transaction.
      // https://github.com/SpaceTradersAPI/api-docs/issues/68
      shipSymbol: purchaser,
      waypointSymbol: transaction.waypointSymbolObject,
      shipType: shipType,
      tradeSymbol: null,
      quantity: 1,
      tradeType: MarketTransactionTypeEnum.PURCHASE,
      perUnitPrice: transaction.price,
      timestamp: transaction.timestamp,
      agentCredits: agentCredits,
      accounting: AccountingType.capital,
    );
  }

  /// Create a new transaction from a ship modification transaction.
  factory Transaction.fromShipModificationTransaction(
    ShipModificationTransaction transaction,
    int agentCredits,
  ) {
    // TODO(eseidel): Is this a ShipMountSymbol?
    // Using a local to force non-null.
    final tradeSymbol = TradeSymbol.fromJson(transaction.tradeSymbol)!;
    return Transaction(
      transactionType: TransactionType.shipModification,
      // shipSymbol is the new ship, not the ship that made the transaction.
      shipSymbol: transaction.shipSymbolObject,
      waypointSymbol: transaction.waypointSymbolObject,
      tradeSymbol: tradeSymbol,
      shipType: null,
      quantity: 1,
      // This is more a service than a purchase.
      tradeType: MarketTransactionTypeEnum.PURCHASE,
      perUnitPrice: transaction.totalPrice,
      timestamp: transaction.timestamp,
      agentCredits: agentCredits,
      accounting: AccountingType.capital,
    );
  }

  /// What type of market transaction created this transaction.
  final TransactionType transactionType;

  /// Ship symbol which made the transaction.
  final ShipSymbol shipSymbol;

  /// Waypoint symbol where the transaction was made.
  final WaypointSymbol waypointSymbol;

  /// Trade symbol of the transaction.
  final TradeSymbol? tradeSymbol;

  /// Only used for Shipyard transactions.
  final ShipType? shipType;

  /// Quantity of units transacted.
  final int quantity;

  /// Market transaction type (e.g. PURCHASE, SELL)
  final MarketTransactionTypeEnum tradeType;

  /// Per-unit price of the transaction.
  final int perUnitPrice;

  /// Timestamp of the transaction.
  final DateTime timestamp;

  /// Credits of the agent after the transaction.
  final int agentCredits;

  /// The accounting classification of the transaction.
  final AccountingType accounting;

  /// The change in credits from this transaction.
  int get creditChange {
    if (tradeType == MarketTransactionTypeEnum.PURCHASE) {
      return -perUnitPrice * quantity;
    } else {
      return perUnitPrice * quantity;
    }
  }

  /// Convert the transaction to json.
  /// This only exists to support CostedDeal.toJson and should be removed.
  Map<String, dynamic> toJson() {
    return {
      'transactionType': transactionType.index,
      'shipSymbol': shipSymbol.toJson(),
      'waypointSymbol': waypointSymbol.toJson(),
      'tradeSymbol': tradeSymbol?.toJson(),
      'shipType': shipType?.toJson(),
      'quantity': quantity,
      'tradeType': tradeType.value,
      'perUnitPrice': perUnitPrice,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'agentCredits': agentCredits,
      'accounting': accounting.name,
    };
  }

  /// Convert the transaction to a record.
  TransactionRecord toRecord() {
    return TransactionRecord(
      transactionType: transactionType.name,
      shipSymbol: shipSymbol.toJson(),
      waypointSymbol: waypointSymbol.toJson(),
      tradeSymbol: tradeSymbol?.toJson(),
      shipType: shipType?.toJson(),
      quantity: quantity,
      tradeType: tradeType.value,
      perUnitPrice: perUnitPrice,
      timestamp: timestamp,
      agentCredits: agentCredits,
      accounting: accounting.name,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          runtimeType == other.runtimeType &&
          transactionType == other.transactionType &&
          shipSymbol == other.shipSymbol &&
          waypointSymbol == other.waypointSymbol &&
          tradeSymbol == other.tradeSymbol &&
          shipType == other.shipType &&
          quantity == other.quantity &&
          tradeType == other.tradeType &&
          perUnitPrice == other.perUnitPrice &&
          timestamp == other.timestamp &&
          agentCredits == other.agentCredits &&
          accounting == other.accounting;

  @override
  int get hashCode =>
      transactionType.hashCode ^
      shipSymbol.hashCode ^
      waypointSymbol.hashCode ^
      tradeSymbol.hashCode ^
      shipType.hashCode ^
      quantity.hashCode ^
      tradeType.hashCode ^
      perUnitPrice.hashCode ^
      timestamp.hashCode ^
      agentCredits.hashCode ^
      accounting.hashCode;
}
