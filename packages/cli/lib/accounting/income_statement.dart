import 'package:db/db.dart';
import 'package:types/types.dart';

class _IncomeStatementBuilderResults {
  int goodsSale = 0;
  int assetSale = 0;
  int contracts = 0;

  int goodsPurchase = 0;
  int fuelPurchase = 0;

  int capEx = 0;
}

class _IncomeStatementBuilder {
  _IncomeStatementBuilder();

  final results = _IncomeStatementBuilderResults();

  void _fail(String message) => throw Exception(message);

  // Intended to function like assert.
  // ignore: avoid_positional_boolean_parameters
  void _expect(bool condition, String message) {
    if (!condition) {
      _fail(message);
    }
  }

  void _sale(Transaction transaction) {
    final credits = transaction.creditsChange;
    _expect(credits > 0, 'Sale is not positive');
    results.goodsSale += credits;
  }

  void _purchase(Transaction transaction) {
    final credits = transaction.creditsChange;
    _expect(credits < 0, 'Purchase is not negative');
    results.goodsPurchase += credits;
  }

  void _fuel(Transaction transaction) {
    final credits = transaction.creditsChange;
    _expect(credits < 0, 'Fuel is not negative');
    results.fuelPurchase += credits;
  }

  void _contractAccept(Transaction transaction) {
    final credits = transaction.creditsChange;
    // Some contracts give no initial credits.
    _expect(credits >= 0, 'Contract is not positive');
    results.contracts += credits;
  }

  void _contractFulfillment(Transaction transaction) {
    final credits = transaction.creditsChange;
    _expect(credits > 0, 'Contract is not positive');
    results.contracts += credits;
  }

  void _capEx(Transaction transaction) {
    final credits = transaction.creditsChange;
    _expect(credits < 0, 'Capital expenditure is negative');
    results.capEx += credits;
  }

  void _assetSale(Transaction transaction) {
    final credits = transaction.creditsChange;
    _expect(credits > 0, 'Asset sale is not positive');
    results.assetSale += credits;
  }

  void _processMarketTransaction(Transaction transaction) {
    switch (transaction.accounting) {
      case AccountingType.goods:
        switch (transaction.tradeType) {
          case MarketTransactionTypeEnum.PURCHASE:
            _purchase(transaction);
          case MarketTransactionTypeEnum.SELL:
            _sale(transaction);
          case null:
            _fail('Unknown market transaction type: null');
        }
      case AccountingType.fuel:
        _expect(transaction.isPurchase, 'Fuel is not a purchase');
        // Need to record fuel usage and differentiate between goods and usage.
        _fuel(transaction);
      case AccountingType.capital:
        _capEx(transaction);
    }
  }

  void _processShipyardTransaction(Transaction transaction) {
    _expect(
      transaction.accounting == AccountingType.capital,
      'Shipyard transaction is not capital',
    );
    _expect(transaction.isPurchase, 'Ship is not a purchase');
    _expect(transaction.creditsChange < 0, 'Ship cost is not negative');
    _capEx(transaction);
  }

  void _processScrapShipTransaction(Transaction transaction) {
    _expect(
      transaction.accounting == AccountingType.capital,
      'Shipyard transaction is not capital',
    );
    _expect(transaction.isSale, 'Ship is not a purchase');
    _expect(transaction.creditsChange >= 0, 'Ship value is not positive');
    _assetSale(transaction);
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
    _capEx(transaction);
  }

  void _processContractTransaction(Transaction transaction) {
    switch (transaction.contractAction) {
      case ContractAction.accept:
        _contractAccept(transaction);
      case ContractAction.fulfillment:
        _contractFulfillment(transaction);
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

  void processTransaction(Transaction transaction) {
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

  static IncomeStatement build(Iterable<Transaction> transactions) {
    // Sort into reverse chronological order.
    final sorted =
        transactions.toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final builder = _IncomeStatementBuilder();
    for (final transaction in sorted) {
      builder.processTransaction(transaction);
    }
    final r = builder.results;
    return IncomeStatement(
      start: sorted.last.timestamp,
      end: sorted.first.timestamp,
      numberOfTransactions: transactions.length,
      goodsRevenue: r.goodsSale,
      contractsRevenue: r.contracts,
      assetSale: r.assetSale,
      goodsPurchase: -r.goodsPurchase,
      fuelPurchase: -r.fuelPurchase,
      capEx: -r.capEx,
    );
  }
}

/// A function to compute the income statement.
Future<IncomeStatement> computeIncomeStatement(Database db) async {
  return _IncomeStatementBuilder.build(await db.allTransactions());
}
