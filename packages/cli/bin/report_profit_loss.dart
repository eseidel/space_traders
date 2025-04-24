import 'package:chalkdart/chalk.dart';
import 'package:cli/accounting/income_statement.dart';
import 'package:cli/cli.dart';
import 'package:cli_table/cli_table.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final report = await computeIncomeStatement(db);

  Map<String, Object> c(int credits) => {
    'content': creditsString(credits),
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
    ['Total Revenues', c(report.revenue)],
    [subhead('Cost of Goods Sold')],
    ['  Goods', c(report.goodsPurchase)],
    ['  Fuel', c(report.fuelPurchase)],
    ['Total Cost of Goods Sold', c(report.costOfGoodsSold)],
    ['Gross Profit', c(report.grossProfit)],
    [subhead('Expenses')],
    ['  Construction', c(report.constructionMaterials)],
    ['Total Expenses', c(report.expenses)],
    ['Net Income', c(report.netIncome)],
    ['Capital Expenditures', c(report.capEx)],
  ]);

  logger
    ..info('Transactions: ${report.numberOfTransactions}')
    ..info('Between ${report.start} and ${report.end}')
    ..info(table.toString());
}

void main(List<String> args) async {
  await runOffline(args, command);
}
