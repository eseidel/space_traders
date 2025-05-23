import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Create the insertion query for a transaction.
Query insertTransactionQuery(Transaction record) {
  return Query(parameters: transactionToColumnMap(record), '''
    INSERT INTO transaction_ (
      transaction_type,
      ship_symbol,
      waypoint_symbol,
      trade_symbol,
      ship_type,
      quantity,
      trade_type,
      per_unit_price,
      timestamp,
      agent_credits,
      accounting,
      contract_action,
      contract_id
    )
    VALUES (
      @transaction_type,
      @ship_symbol,
      @waypoint_symbol,
      @trade_symbol,
      @ship_type,
      @quantity,
      @trade_type,
      @per_unit_price,
      @timestamp,
      @agent_credits,
      @accounting,
      @contract_action,
      @contract_id
    )
    ''');
}

/// Convert the transaction to substitution values for insertion.
Map<String, dynamic> transactionToColumnMap(Transaction transaction) {
  return {
    'transaction_type': transaction.transactionType.toJson(),
    'ship_symbol': transaction.shipSymbol.toJson(),
    'waypoint_symbol': transaction.waypointSymbol.toJson(),
    'trade_symbol': transaction.tradeSymbol?.toJson(),
    'ship_type': transaction.shipType?.toJson(),
    'quantity': transaction.quantity,
    'trade_type': transaction.tradeType?.value,
    'per_unit_price': transaction.perUnitPrice,
    'timestamp': transaction.timestamp,
    'agent_credits': transaction.agentCredits,
    'accounting': transaction.accounting.toJson(),
    'contract_action': transaction.contractAction?.name,
    'contract_id': transaction.contractId,
  };
}

/// Create a new transaction from a result row.
Transaction transactionFromColumnMap(Map<String, dynamic> values) {
  return Transaction(
    transactionType: TransactionType.fromJson(
      values['transaction_type'] as String,
    ),
    shipSymbol: ShipSymbol.fromJson(values['ship_symbol'] as String),
    waypointSymbol: WaypointSymbol.fromJson(
      values['waypoint_symbol'] as String,
    ),
    tradeSymbol: TradeSymbol.fromJson(values['trade_symbol'] as String?),
    shipType: ShipType.fromJson(values['ship_type'] as String?),
    quantity: values['quantity'] as int,
    tradeType: MarketTransactionType.fromJson(values['trade_type'] as String?),
    perUnitPrice: values['per_unit_price'] as int,
    timestamp: values['timestamp'] as DateTime,
    agentCredits: values['agent_credits'] as int,
    accounting: AccountingType.fromJson(values['accounting'] as String),
    contractAction: ContractAction.fromJsonOrNull(
      values['contract_action'] as String?,
    ),
    contractId: values['contract_id'] as String?,
  );
}
