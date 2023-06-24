import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/cache/json_log.dart';

/// A class to hold transaction data from a ship.
@immutable
class Transaction {
  /// Create a new transaction.
  const Transaction({
    required this.shipSymbol,
    required this.waypointSymbol,
    required this.tradeSymbol,
    required this.quantity,
    required this.tradeType,
    required this.perUnitPrice,
    required this.timestamp,
    required this.agentCredits,
  });

  /// Create a new transaction from json.
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      shipSymbol: json['shipSymbol'] as String,
      waypointSymbol: json['waypointSymbol'] as String,
      tradeSymbol: json['tradeSymbol'] as String,
      quantity: json['quantity'] as int,
      tradeType: MarketTransactionTypeEnum.values
          .firstWhere((e) => e.value == json['tradeType'] as String),
      perUnitPrice: json['perUnitPrice'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      agentCredits: json['agentCredits'] as int,
    );
  }

  /// Create a new transaction from a market transaction.
  factory Transaction.fromMarketTransaction(
    MarketTransaction transaction,
    int agentCredits,
  ) {
    return Transaction(
      shipSymbol: transaction.shipSymbol,
      waypointSymbol: transaction.waypointSymbol,
      tradeSymbol: transaction.tradeSymbol,
      quantity: transaction.units,
      tradeType: transaction.type,
      perUnitPrice: transaction.pricePerUnit,
      timestamp: transaction.timestamp,
      agentCredits: agentCredits,
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
      shipSymbol: transaction.shipSymbol,
      waypointSymbol: transaction.waypointSymbol,
      tradeSymbol: shipType.value,
      quantity: 1,
      tradeType: MarketTransactionTypeEnum.PURCHASE,
      perUnitPrice: transaction.price,
      timestamp: transaction.timestamp,
      agentCredits: agentCredits,
    );
  }

  /// Ship symbol which made the transaction.
  final String shipSymbol;

  /// Waypoint symbol where the transaction was made.
  final String waypointSymbol;

  /// Trade symbol of the transaction.
  final String tradeSymbol;

  /// Quantity of the transaction.
  final int quantity;

  /// Type of transaction.
  final MarketTransactionTypeEnum tradeType;

  /// Per-unit price of the transaction.
  final int perUnitPrice;

  /// Timestamp of the transaction.
  final DateTime timestamp;

  /// Credits of the agent after the transaction.
  final int agentCredits;

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
      'shipSymbol': shipSymbol,
      'waypointSymbol': waypointSymbol,
      'tradeSymbol': tradeSymbol,
      'quantity': quantity,
      'tradeType': tradeType.value,
      'perUnitPrice': perUnitPrice,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'agentCredits': agentCredits,
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

  /// Load the transaction log from the file system.
  static Future<TransactionLog> load(FileSystem fs, [String? path]) async {
    final filePath = path ?? 'transactions.json';
    final entries =
        await JsonLog.load<Transaction>(fs, filePath, Transaction.fromJson);
    return TransactionLog(entries, fs: fs, path: filePath);
  }

  /// Return all the ship symbols in the transaction log.
  Set<String> get shipSymbols {
    return entries.map((e) => e.shipSymbol).toSet();
  }
}
