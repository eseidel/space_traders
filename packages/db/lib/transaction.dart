import 'package:db/db.dart';
import 'package:db/query.dart';
import 'package:postgres/postgres.dart';
import 'package:types/types.dart';

/// Create the insertion query for a transaction.
Query insertTransactionQuery(Transaction record) {
  return Query(
    'INSERT INTO transaction_ (transaction_type, ship_symbol, waypoint_symbol, '
    'trade_symbol, ship_type, quantity, trade_type, per_unit_price, timestamp, '
    'agent_credits, accounting) VALUES (@transaction_type, @ship_symbol, '
    '@waypoint_symbol, @trade_symbol, @ship_type, @quantity, @trade_type, '
    '@per_unit_price, @timestamp, @agent_credits, @accounting)',
    substitutionValues: transactionToColumnMap(record),
  );
}

/// Convert the transaction to substitution values for insertion.
Map<String, dynamic> transactionToColumnMap(Transaction transaction) {
  return {
    'transaction_type': transaction.transactionType.name,
    'ship_symbol': transaction.shipSymbol.toJson(),
    'waypoint_symbol': transaction.waypointSymbol.toJson(),
    'trade_symbol': transaction.tradeSymbol?.toJson(),
    'ship_type': transaction.shipType?.toJson(),
    'quantity': transaction.quantity,
    'trade_type': transaction.tradeType.value,
    'per_unit_price': transaction.perUnitPrice,
    'timestamp': transaction.timestamp,
    'agent_credits': transaction.agentCredits,
    'accounting': transaction.accounting.name,
  };
}

/// Create a new transaction from a result row.
Transaction transactionFromResultRow(PostgreSQLResultRow row) {
  final values = row.toColumnMap();
  return Transaction(
    transactionType:
        TransactionType.fromName(values['transaction_type'] as String),
    shipSymbol: ShipSymbol.fromJson(values['ship_symbol'] as String),
    waypointSymbol:
        WaypointSymbol.fromJson(values['waypoint_symbol'] as String),
    tradeSymbol: TradeSymbol.fromJson(values['trade_symbol'] as String?),
    shipType: ShipType.fromJson(values['ship_type'] as String?),
    quantity: values['quantity'] as int,
    tradeType:
        MarketTransactionTypeEnum.fromJson(values['trade_type'] as String)!,
    perUnitPrice: values['per_unit_price'] as int,
    timestamp: values['timestamp'] as DateTime,
    agentCredits: values['agent_credits'] as int,
    accounting: AccountingType.fromName(values['accounting'] as String),
  );
}

/// Get unique ship symbols from the transaction table.
Future<Set<String>> uniqueShipSymbols(Database db) async {
  final result =
      await db.connection.query('SELECT DISTINCT shipSymbol FROM transaction_');
  return result.map((r) => r.first as String).toSet();
}

/// Get all transactions from the database.
Future<Iterable<Transaction>> allTransactions(Database db) async {
  final result = await db.connection.query('SELECT * FROM transaction_');
  return result.map(transactionFromResultRow);
}

/// Get transactions after a given timestamp.
Future<Iterable<Transaction>> transactionsAfter(
  Database db,
  DateTime timestamp,
) async {
  final result = await db.connection.query(
    'SELECT * FROM transaction_ WHERE timestamp > @timestamp',
    substitutionValues: {'timestamp': timestamp},
  );
  return result.map(transactionFromResultRow);
}
