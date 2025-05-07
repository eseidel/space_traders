import 'dart:math';

import 'package:cli/logger.dart';
import 'package:types/types.dart';

class _IncomeStatementBuilderResults {
  int goodsSale = 0;
  int assetSale = 0;
  int contracts = 0;

  int goodsPurchase = 0;
  int constructionPurchase = 0;
  int fuelPurchase = 0;

  int capEx = 0;
}

/// Class to represent a bad transaction.
class BadTransaction implements Exception {
  /// Construct a bad transaction.
  const BadTransaction(this.message, this.transaction);

  /// The message to display.
  final String message;

  /// The transaction that caused the error.
  final Transaction transaction;

  @override
  String toString() {
    return 'Bad transaction: $message\n'
        'Transaction: ${transaction.toJson()}';
  }
}

class _IncomeStatementBuilder {
  _IncomeStatementBuilder();

  final results = _IncomeStatementBuilderResults();

  // This is a hack because purchase transactions do not include an intent
  // as to if they will be used for construction or or sales.
  // We have the same problem with fuel, but no easy hack to recover that
  // information without recording fuel usage.
  final Map<TradeSymbol, int> _outstandingConstructionDeliveries = {};

  void _fail(Transaction transaction, String message) =>
      throw BadTransaction(message, transaction);

  // Intended to function like assert.
  // ignore: avoid_positional_boolean_parameters
  void _expect(Transaction transaction, bool condition, String message) {
    if (!condition) {
      _fail(transaction, message);
    }
  }

  void _expectAccounting(
    Transaction transaction,
    AccountingType type,
    String name,
  ) {
    _expect(transaction, transaction.accounting == type, '$name is not $type');
  }

  int _positive(Transaction transaction, String name) {
    final credits = transaction.creditsChange;
    _expect(transaction, credits > 0, '$name is not positive');
    return credits;
  }

  int _negative(Transaction transaction, String name) {
    final credits = transaction.creditsChange;
    _expect(transaction, credits < 0, '$name is not negative');
    return credits;
  }

  void _zero(Transaction transaction, String name) {
    final credits = transaction.creditsChange;
    _expect(transaction, credits == 0, '$name is not zero');
  }

  void _sale(Transaction transaction) {
    results.goodsSale += _positive(transaction, 'Sale');
  }

  int? _outstandingConstructionDelivery(TradeSymbol symbol) {
    final outstanding = _outstandingConstructionDeliveries[symbol];
    if (outstanding == null || outstanding == 0) {
      return null;
    }
    return outstanding;
  }

  ({int goods, int construction}) _dividePurchaseValue(Transaction t) {
    // Hack to count goods purchases as construction purchases even though
    // we did not record that information at purchase time.
    final symbol = t.tradeSymbol!;
    final outstanding = _outstandingConstructionDelivery(symbol);
    if (outstanding == null) {
      return (goods: t.creditsChange, construction: 0);
    }
    final quantity = t.quantity;
    final usedForConstruction = min(quantity, outstanding);
    final usedForSale = quantity - usedForConstruction;
    final remainingForConstruction = outstanding - usedForConstruction;
    if (remainingForConstruction > 0) {
      _outstandingConstructionDeliveries[symbol] = remainingForConstruction;
    } else {
      _outstandingConstructionDeliveries.remove(symbol);
    }
    return (
      goods: usedForSale * t.perUnitPrice,
      construction: usedForConstruction * t.perUnitPrice,
    );
  }

  void _purchase(Transaction transaction) {
    _negative(transaction, 'Purchase');
    final record = _dividePurchaseValue(transaction);
    results.goodsPurchase += record.goods;
    results.constructionPurchase += record.construction;
  }

  void _fuel(Transaction transaction) {
    results.fuelPurchase += _negative(transaction, 'Fuel');
  }

  void _contractAccept(Transaction transaction) {
    // All accepts should include a (possibly small) initial payment.
    results.contracts += _positive(transaction, 'Contract');
  }

  void _contractFulfillment(Transaction transaction) {
    // Fulfillments should include the full final payment.
    results.contracts += _positive(transaction, 'Contract');
  }

  void _capEx(Transaction transaction) {
    results.capEx += _negative(transaction, 'CapEx');
  }

  void _assetSale(Transaction transaction) {
    results.assetSale += _positive(transaction, 'Asset sale');
  }

  void _processMarketTransaction(Transaction t) {
    switch (t.accounting) {
      case AccountingType.goods:
        switch (t.tradeType) {
          case MarketTransactionTypeEnum.PURCHASE:
            _purchase(t);
          case MarketTransactionTypeEnum.SELL:
            _sale(t);
          case null:
            _fail(t, 'Unknown market transaction type: null');
        }
      case AccountingType.fuel:
        _expect(t, t.isPurchase, 'Fuel is not a purchase');
        // Need to record fuel usage and differentiate between goods and usage.
        _fuel(t);
      case AccountingType.capital:
        _capEx(t);
    }
  }

  void _processShipyardTransaction(Transaction t) {
    _expectAccounting(t, AccountingType.capital, 'Shipyard transaction');
    _expect(t, t.isPurchase, 'Ship is not a purchase');
    _capEx(t);
  }

  void _processScrapShipTransaction(Transaction t) {
    _expectAccounting(t, AccountingType.capital, 'Shipyard transaction');
    _expect(t, t.isSale, 'Ship is not a purchase');
    _assetSale(t);
  }

  void _processShipModificationTransaction(Transaction t) {
    _expectAccounting(t, AccountingType.capital, 'Shipyard transaction');
    _expect(t, t.isPurchase, 'Ship modification is not a purchase');
    _capEx(t);
  }

  void _processContractTransaction(Transaction t) {
    switch (t.contractAction) {
      case ContractAction.accept:
        _contractAccept(t);
      case ContractAction.fulfillment:
        _contractFulfillment(t);
      case ContractAction.delivery:
        _zero(t, 'Contract delivery');
      case null:
        _fail(t, 'Contract transaction has no action');
    }
  }

  void _processConstructionTransaction(Transaction transaction) {
    // Construction deliveries are not a P&L item.
    _zero(transaction, 'Construction delivery');
    _outstandingConstructionDeliveries.update(
      transaction.tradeSymbol!,
      (v) => v + transaction.quantity,
      ifAbsent: () => transaction.quantity,
    );
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
    final badTransactions = <BadTransaction>[];
    for (final transaction in sorted) {
      try {
        builder.processTransaction(transaction);
      } on BadTransaction catch (e) {
        badTransactions.add(e);
      }
    }
    if (badTransactions.isNotEmpty) {
      logger.err('Bad transactions:');
      for (final t in badTransactions) {
        logger.err(t.toString());
      }
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
      constructionMaterials: -r.constructionPurchase,
      capEx: -r.capEx,
    );
  }
}

/// A function to compute the income statement from a list of transactions.
Future<IncomeStatement> computeIncomeStatement(
  Iterable<Transaction> transactions,
) async {
  return _IncomeStatementBuilder.build(transactions);
}
