import 'package:db/db.dart';
import 'package:db/query.dart';
import 'package:meta/meta.dart';
import 'package:postgres/postgres.dart';

/// Create the insertion query for a transaction.
Query insertTransactionQuery(TransactionRecord record) {
  return Query(
    'INSERT INTO transaction_ (transaction_type, ship_symbol, waypoint_symbol, '
    'trade_symbol, ship_type, quantity, trade_type, per_unit_price, timestamp, '
    'agent_credits, accounting) VALUES (@transaction_type, @ship_symbol, '
    '@waypoint_symbol, @trade_symbol, @ship_type, @quantity, @trade_type, '
    '@per_unit_price, @timestamp, @agent_credits, @accounting)',
    substitutionValues: toSubstitutionValues(record),
  );
}

/// Convert the transaction to substitution values for insertion.
Map<String, dynamic> toSubstitutionValues(TransactionRecord record) {
  return {
    'transaction_type': record.transactionType,
    'ship_symbol': record.shipSymbol,
    'waypoint_symbol': record.waypointSymbol,
    'trade_symbol': record.tradeSymbol,
    'ship_type': record.shipType,
    'quantity': record.quantity,
    'trade_type': record.tradeType,
    'per_unit_price': record.perUnitPrice,
    'timestamp': record.timestamp,
    'agent_credits': record.agentCredits,
    'accounting': record.accounting,
  };
}

/// Create a new transaction from a result row.
TransactionRecord transactionFromResultRow(PostgreSQLResultRow row) {
  final values = row.toColumnMap();
  return TransactionRecord(
    transactionType: values['transaction_type'] as String,
    shipSymbol: values['ship_symbol'] as String,
    waypointSymbol: values['waypoint_symbol'] as String,
    tradeSymbol: values['trade_symbol'] as String?,
    shipType: values['ship_type'] as String?,
    quantity: values['quantity'] as int,
    tradeType: values['trade_type'] as String,
    perUnitPrice: values['per_unit_price'] as int,
    timestamp: values['timestamp'] as DateTime,
    agentCredits: values['agent_credits'] as int,
    accounting: values['accounting'] as String,
  );
}

/// Get unique ship symbols from the transaction table.
Future<Set<String>> uniqueShipSymbols(Database db) async {
  final result =
      await db.connection.query('SELECT DISTINCT shipSymbol FROM transaction_');
  return result.map((r) => r.first as String).toSet();
}

/// Get all transactions from the database.
Future<Iterable<TransactionRecord>> allTransactions(Database db) async {
  final result = await db.connection.query('SELECT * FROM transaction_');
  return result.map(transactionFromResultRow);
}

/// Get transactions after a given timestamp.
Future<Iterable<TransactionRecord>> transactionsAfter(
  Database db,
  DateTime timestamp,
) async {
  final result = await db.connection.query(
    'SELECT * FROM transaction_ WHERE timestamp > @timestamp',
    substitutionValues: {'timestamp': timestamp},
  );
  return result.map(transactionFromResultRow);
}

/// A class to hold transaction data from a ship.
@immutable
class TransactionRecord {
  /// Create a new transaction.
  const TransactionRecord({
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

  /// Create a new transaction record for tests.
  @visibleForTesting
  factory TransactionRecord.test() {
    return TransactionRecord(
      transactionType: 'MARKET',
      shipSymbol: 'ESEIDEL-1',
      waypointSymbol: 'S-E-P',
      tradeSymbol: 'FUEL',
      shipType: 'Mule',
      quantity: 1,
      tradeType: 'PURCHASE',
      perUnitPrice: 2,
      timestamp: DateTime.utc(1969, 7, 20, 20, 18, 04),
      agentCredits: 3,
      accounting: 'CAPITAL',
    );
  }

  /// What type of market transaction created this transaction.
  final String transactionType;

  /// Ship symbol which made the transaction.
  final String shipSymbol;

  /// Waypoint symbol where the transaction was made.
  final String waypointSymbol;

  /// Trade symbol of the transaction.
  final String? tradeSymbol;

  /// Only used for Shipyard transactions.
  final String? shipType;

  /// Quantity of units transacted.
  final int quantity;

  /// Market transaction type (e.g. PURCHASE, SELL)
  final String tradeType;

  /// Per-unit price of the transaction.
  final int perUnitPrice;

  /// Timestamp of the transaction.
  final DateTime timestamp;

  /// Credits of the agent after the transaction.
  final int agentCredits;

  /// The accounting classification of the transaction.
  final String accounting;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionRecord &&
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
