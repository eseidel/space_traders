import 'package:chalkdart/chalk.dart';
import 'package:cli/accounting/income_statement.dart';
import 'package:cli/cli.dart';
import 'package:cli_table/cli_table.dart';

void printIncomeStatement(IncomeStatement report) {
  Map<String, Object> c(num credits) => {
    'content': creditsString(credits),
    'hAlign': HorizontalAlign.right,
  };

  Map<String, Object> percent(double percent) => {
    'content': '${(percent * 100).toStringAsFixed(1)}%',
    'hAlign': HorizontalAlign.right,
  };

  Map<String, Object> subhead(String text) => {
    'colSpan': 2,
    'content': chalk.underline(text),
  };

  final table = Table(
    header: ['Description', 'Amount'],
    style: const TableStyle(compact: true),
  )..addAll([
    [subhead('Revenue')],
    ['  Sales', c(report.goodsRevenue)],
    ['  Contracts', c(report.contractsRevenue)],
    ['  Asset Sales', c(report.assetSale)],
    ['  Charting', c(report.chartingRevenue)],
    ['Total Revenues', c(report.revenue)],
    [subhead('Cost of Goods Sold')],
    ['  Goods', c(report.goodsPurchase)],
    ['  Fuel', c(report.fuelPurchase)],
    ['Total Cost of Goods Sold', c(report.costOfGoodsSold)],
    ['COGS Ratio', percent(report.cogsRatio)],
    ['Gross Profit', c(report.grossProfit)],
    [subhead('Expenses')],
    ['  Construction', c(report.constructionMaterials)],
    ['Total Expenses', c(report.expenses)],
    ['Net Income', c(report.netIncome)],
    ['Net Income per second', c(report.netIncomePerSecond)],
    ['Capital Expenditures', c(report.capEx)],
  ]);

  logger
    ..info('Transactions: ${report.numberOfTransactions}')
    ..info(
      'Between ${report.start} and ${report.end} '
      '${approximateDuration(report.duration)}',
    )
    ..info(table.toString());
}

Future<void> command(Database db, ArgResults argResults) async {
  final transactions = await db.transactions.all();
  final report = await computeIncomeStatement(transactions);
  printIncomeStatement(report);
}

void main(List<String> args) async {
  await runOffline(args, command);
}
