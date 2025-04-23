import 'package:db/db.dart';
import 'package:types/types.dart';

class _IncomeStatementBuilder {
  _IncomeStatementBuilder(this.transactions);

  final Iterable<Transaction> transactions;

  int _sales = 0;
  int _contracts = 0;

  int _goods = 0;
  int _fuel = 0;

  int _capEx = 0;

  void _fail(String message) => throw Exception(message);

  // Intended to function like assert.
  // ignore: avoid_positional_boolean_parameters
  void _expect(bool condition, String message) {
    if (!condition) {
      _fail(message);
    }
  }

  void _processMarketTransaction(Transaction transaction) {
    switch (transaction.accounting) {
      case AccountingType.goods:
        switch (transaction.tradeType) {
          case MarketTransactionTypeEnum.PURCHASE:
            _goods += transaction.creditsChange;
          case MarketTransactionTypeEnum.SELL:
            _sales += transaction.creditsChange;
          case null:
            _fail('Unknown market transaction type: null');
        }
      case AccountingType.fuel:
        _expect(transaction.isPurchase, 'Fuel is not a purchase');
        _fuel += transaction.creditsChange;
      case AccountingType.capital:
        _capEx += transaction.creditsChange;
    }
  }

  void _processShipyardTransaction(Transaction transaction) {
    _expect(
      transaction.accounting == AccountingType.capital,
      'Shipyard transaction is not capital',
    );
    _expect(transaction.isPurchase, 'Ship is not a purchase');
    _expect(transaction.creditsChange < 0, 'Ship cost is not negative');
    _capEx += transaction.creditsChange;
  }

  void _processScrapShipTransaction(Transaction transaction) {
    _expect(
      transaction.accounting == AccountingType.capital,
      'Shipyard transaction is not capital',
    );
    _expect(transaction.isSale, 'Ship is not a purchase');
    _expect(transaction.creditsChange >= 0, 'Ship value is not positive');
    _capEx += transaction.creditsChange;
  }

  void _processShipModificationTransaction(Transaction transaction) {
    _expect(
      transaction.accounting == AccountingType.capital,
      'Shipyard modification transaction is not capital',
    );
    _expect(transaction.isPurchase, 'Ship modification is not a purchase');
    _expect(
      transaction.creditsChange < 0,
      'Ship modification cost is not negative',
    );
    _capEx += transaction.creditsChange;
  }

  void _processContractTransaction(Transaction transaction) {
    switch (transaction.contractAction) {
      case ContractAction.accept:
        _contracts += transaction.creditsChange;
      case ContractAction.fulfillment:
        _contracts += transaction.creditsChange;
      case ContractAction.delivery:
        _expect(transaction.creditsChange == 0, 'Delivery is not zero');
      case null:
        _fail('Contract transaction has no action');
    }
  }

  void _processConstructionTransaction(Transaction transaction) {
    // Construction deliveries are not a P&L item.
    _expect(transaction.creditsChange == 0, 'Delivery is not zero');
  }

  Future<IncomeStatement> build() async {
    final transactionCount = transactions.length;

    for (final transaction in transactions) {
      switch (transaction.transactionType) {
        case TransactionType.market:
          _processMarketTransaction(transaction);
        case TransactionType.shipyard:
          _processShipyardTransaction(transaction);
        case TransactionType.scrapShip:
          _processScrapShipTransaction(transaction);
        case TransactionType.shipModification:
          _processShipModificationTransaction(transaction);
        case TransactionType.contract:
          _processContractTransaction(transaction);
        case TransactionType.construction:
          _processConstructionTransaction(transaction);
      }
    }

    return IncomeStatement(
      start: transactions.first.timestamp,
      end: transactions.last.timestamp,
      sales: _sales,
      contracts: _contracts,
      goods: -_goods,
      fuel: -_fuel,
      numberOfTransactions: transactionCount,
      capEx: -_capEx,
    );
  }
}

/// A function to compute the income statement.
Future<IncomeStatement> computeIncomeStatement(Database db) async {
  final transactions = await db.allTransactions();
  return await _IncomeStatementBuilder(transactions).build();
}
