import 'package:file/file.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/json_log.dart';

/// A class to hold transaction data from a ship.
class Transaction {
  /// Create a new transaction.
  Transaction({
    required this.shipSymbol,
    required this.waypointSymbol,
    required this.tradeSymbol,
    required this.quantity,
    required this.tradeType,
    required this.perUnitPrice,
    required this.timestamp,
    required this.agentCredits,
  });

  /// Ship symbol which made the transaction.
  final String shipSymbol;

  /// Waypoint symbol where the transaction was made.
  final String waypointSymbol;

  /// Trade symbol of the transaction.
  final String tradeSymbol;

  /// Quantity of the transaction.
  final int quantity;

  /// Type of transaction.
  MarketTransactionTypeEnum tradeType;

  /// Per-unit price of the transaction.
  final int perUnitPrice;

  /// Timestamp of the transaction.
  final DateTime timestamp;

  /// Credits of the agent after the transaction.
  final int agentCredits;
}

/// A class to manage a transaction log file.
class TransactionLog extends JsonLog<Transaction> {
  /// Create a new transaction log.
  TransactionLog(
    super.entries, {
    required super.fs,
    required super.path,
  });

  /// Load the transaction log from the file system.
  static Future<TransactionLog> load(FileSystem fs, [String? path]) async {
    final filePath = path ?? 'transactions.json';
    final entries = await JsonLog.load<Transaction>(fs, filePath);
    return TransactionLog(entries, fs: fs, path: filePath);
  }
}
