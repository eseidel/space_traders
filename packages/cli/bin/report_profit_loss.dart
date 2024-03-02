import 'package:cli/cli.dart';
import 'package:cli/printing.dart';

class ProfitLoss {
  ProfitLoss({
    required this.start,
    required this.end,
    required this.sales,
    required this.contracts,
    required this.goods,
    required this.fuel,
    required this.constructionMaterials,
    required this.subsidies,
    required this.categorizationPending,
  });

  final DateTime start;
  final DateTime end;

  final int sales;
  final int contracts;
  final int goods;
  final int fuel;
  final int constructionMaterials;
  final int subsidies;
  final int categorizationPending;

  int get totalIncome => sales + contracts;
  int get totalCostOfGoodsSold => goods + fuel;
  int get grossProfit => totalIncome - totalCostOfGoodsSold;
  int get totalExpenses =>
      constructionMaterials + subsidies + categorizationPending;
  int get netIncome => grossProfit - totalExpenses;
}

class ReportBuilder {
  ReportBuilder(this.fs, this.db);

  final FileSystem fs;
  final Database db;

  int sales = 0;
  int contracts = 0;

  int goods = 0;
  int fuel = 0;
  int constructionMaterials = 0;

  int subsidies = 0;
  int categorizationPending = 0;

  int transactionCount = 0;

  void _fail(String message) {
    throw Exception(message);
  }

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
            goods += transaction.creditsChange;
          case MarketTransactionTypeEnum.SELL:
            sales += transaction.creditsChange;
          case null:
            _fail('Unknown market transaction type: null');
        }
      case AccountingType.fuel:
        _expect(transaction.isPurchase, 'Fuel is not a purchase');
        fuel += transaction.creditsChange;
      case AccountingType.capital:
      // CapEx doesn't show up on P&L.
    }
  }

  void _processShipyardTransaction(Transaction transaction) {
    _expect(
      transaction.accounting == AccountingType.capital,
      'Shipyard transaction is not capital',
    );
    _expect(transaction.isPurchase, 'Ship is not a purchase');
    _expect(
      transaction.creditsChange < 0,
      'Ship cost is not negative',
    );
    // CapEx doesn't show up in P&L.
  }

  void _processShipModificationTransaction(Transaction transaction) {
    _expect(
      transaction.accounting == AccountingType.capital,
      'Shipyard modification transaction is not capital',
    );
    _expect(
      transaction.isPurchase,
      'Ship modification is not a purchase',
    );
    _expect(
      transaction.creditsChange < 0,
      'Ship modification cost is not negative',
    );
    // CapEx doesn't show up in P&L.
  }

  void _processContractTransaction(Transaction transaction) {
    switch (transaction.contractAction) {
      case ContractAction.accept:
        contracts += transaction.creditsChange;
      case ContractAction.fulfillment:
        contracts += transaction.creditsChange;
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

  Future<ProfitLoss> buildProfitLoss() async {
    final transactions = await db.allTransactions();
    transactionCount = transactions.length;

    for (final transaction in transactions) {
      switch (transaction.transactionType) {
        case TransactionType.market:
          _processMarketTransaction(transaction);
        case TransactionType.shipyard:
          _processShipyardTransaction(transaction);
        case TransactionType.shipModification:
          _processShipModificationTransaction(transaction);
        case TransactionType.contract:
          _processContractTransaction(transaction);
        case TransactionType.construction:
          _processConstructionTransaction(transaction);
      }
    }

    return ProfitLoss(
      start: transactions.first.timestamp,
      end: transactions.last.timestamp,
      sales: sales,
      contracts: contracts,
      goods: -goods,
      fuel: -fuel,
      constructionMaterials: constructionMaterials,
      subsidies: subsidies,
      categorizationPending: categorizationPending,
    );
  }
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final rb = ReportBuilder(fs, db);
  final report = await rb.buildProfitLoss();

  String c(int credits) => creditsString(credits);

  logger
    ..info('Transactions: ${rb.transactionCount}')
    ..info('Between ${report.start} and ${report.end}')
    ..info('Income')
    ..info('  Sales: ${c(report.sales)}')
    ..info('  Contracts: ${c(report.contracts)}')
    ..info('Total Income: ${c(report.totalIncome)}')
    ..info('Cost of Goods Sold')
    ..info('  Goods: ${c(report.goods)}')
    ..info('  Fuel: ${c(report.fuel)}')
    ..info('Total Cost of Goods Sold: ${c(report.totalCostOfGoodsSold)}')
    ..info('Gross Profit: ${c(report.grossProfit)}')
    ..info('Expenses')
    // ..info('  Construction Materials: ${c(profitLoss.constructionMaterials)}')
    // ..info('  Subsidies: ${c(profitLoss.subsidies)}')
    // ..info('  Categorization Pending: ${c(profitLoss.categorizationPending)}')
    ..info('Total Expenses: ${c(report.totalExpenses)}')
    ..info('Net Income: ${c(report.netIncome)}');
}

void main(List<String> args) async {
  await runOffline(args, command);
}
