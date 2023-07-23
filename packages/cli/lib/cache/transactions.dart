import 'package:cli/api.dart';
import 'package:cli/cache/json_log.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';

/// The type of a transaction.
enum AccountingType {
  /// Capital transaction (e.g. ships, mounts).
  capital,

  /// Fuel transaction (e.g. fuel for transport, not for sale).
  fuel,

  /// Goods transaction (e.g. buying/selling trade goods).
  goods,
}

// enum BehaviorSource {
//   miner,
//   trader,
//   centralCommand,
// }

/// A class to hold transaction data from a ship.
@immutable
class Transaction {
  /// Create a new transaction.
  const Transaction({
    required this.shipSymbol,
    required this.waypointSymbol,
    required this.tradeSymbol,
    required this.tradeType,
    required this.quantity,
    required this.perUnitPrice,
    required this.timestamp,
    required this.agentCredits,
    required this.accounting,
  });

  /// Create a new transaction from json.
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      shipSymbol: ShipSymbol.fromJson(json['shipSymbol'] as String),
      waypointSymbol: WaypointSymbol.fromJson(json['waypointSymbol'] as String),
      tradeSymbol: json['tradeSymbol'] as String,
      quantity: json['quantity'] as int,
      tradeType: MarketTransactionTypeEnum.values
          .firstWhere((e) => e.value == json['tradeType'] as String),
      perUnitPrice: json['perUnitPrice'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      agentCredits: json['agentCredits'] as int,
      accounting: json['accounting'] == null
          ? null
          : AccountingType.values
              .firstWhere((e) => e.name == json['accounting'] as String),
    );
  }

  /// Create a new transaction from a market transaction.
  factory Transaction.fromMarketTransaction(
    MarketTransaction transaction,
    int agentCredits,
    AccountingType accounting,
  ) {
    return Transaction(
      shipSymbol: transaction.shipSymbolObject,
      waypointSymbol: transaction.waypointSymbolObject,
      tradeSymbol: transaction.tradeSymbol,
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
    ShipType shipType,
    int agentCredits,
  ) {
    return Transaction(
      // shipSymbol is the new ship, not the ship that made the transaction.
      shipSymbol: transaction.shipSymbolObject,
      waypointSymbol: transaction.waypointSymbolObject,
      tradeSymbol: shipType.value,
      quantity: 1,
      tradeType: MarketTransactionTypeEnum.PURCHASE,
      perUnitPrice: transaction.price,
      timestamp: transaction.timestamp,
      agentCredits: agentCredits,
      accounting: AccountingType.capital,
    );
  }

  /// Ship symbol which made the transaction.
  final ShipSymbol shipSymbol;

  /// Waypoint symbol where the transaction was made.
  final WaypointSymbol waypointSymbol;

  /// Trade symbol of the transaction.
  // TODO(eseidel): This isn't actually a trade symbol since it includes ships!
  final String tradeSymbol;

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
  final AccountingType? accounting;

  // /// The behavior that caused this transaction.
  // final BehaviorSource? behavior;

  /// The change in credits from this transaction.
  int get creditChange {
    if (tradeType == MarketTransactionTypeEnum.PURCHASE) {
      return -perUnitPrice * quantity;
    } else {
      return perUnitPrice * quantity;
    }
  }

  /// Convert the transaction to json.
  Map<String, dynamic> toJson() {
    return {
      'shipSymbol': shipSymbol.toJson(),
      'waypointSymbol': waypointSymbol.toJson(),
      'tradeSymbol': tradeSymbol,
      'quantity': quantity,
      'tradeType': tradeType.value,
      'perUnitPrice': perUnitPrice,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'agentCredits': agentCredits,
      'accounting': accounting?.name,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          runtimeType == other.runtimeType &&
          shipSymbol == other.shipSymbol &&
          waypointSymbol == other.waypointSymbol &&
          tradeSymbol == other.tradeSymbol &&
          quantity == other.quantity &&
          tradeType == other.tradeType &&
          perUnitPrice == other.perUnitPrice &&
          timestamp == other.timestamp &&
          agentCredits == other.agentCredits;

  @override
  int get hashCode =>
      shipSymbol.hashCode ^
      waypointSymbol.hashCode ^
      tradeSymbol.hashCode ^
      quantity.hashCode ^
      tradeType.hashCode ^
      perUnitPrice.hashCode ^
      timestamp.hashCode ^
      agentCredits.hashCode;
}

/// A class to manage a transaction log file.
class TransactionLog extends JsonLog<Transaction> {
  /// Create a new transaction log.
  TransactionLog(
    super.entries, {
    required super.fs,
    required super.path,
  }) : super(recordToJson: (record) => record.toJson());

  /// The default path to the transaction log.
  static const String defaultPath = 'data/transactions.json';

  /// Load the transaction log from the file system.
  // ignore: prefer_constructors_over_static_methods
  static TransactionLog load(
    FileSystem fs, {
    String path = defaultPath,
  }) {
    final entries = JsonLog.load<Transaction>(fs, path, Transaction.fromJson);
    return TransactionLog(entries, fs: fs, path: path);
  }

  /// Return transactions with the given filter applied.
  List<Transaction> where(bool Function(Transaction t) filter) {
    return entries.where(filter).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Return all the ship symbols in the transaction log.
  Set<ShipSymbol> get shipSymbols {
    return entries.map((e) => e.shipSymbol).toSet();
  }
}
