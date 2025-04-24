import 'package:chalkdart/chalk.dart';
import 'package:cli/accounting/income_statement.dart';
import 'package:cli/cli.dart';
import 'package:cli_table/cli_table.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final report = await computeIncomeStatement(db);

  String c(int credits) => creditsString(credits);

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
    ['  Asset Sale', c(report.assetSale)],
    ['  Goods', c(report.goodsPurchase)],
    ['  Fuel', c(report.fuelPurchase)],
    ['Total Cost of Goods Sold', c(report.costOfGoodsSold)],
    ['Gross Profit', c(report.grossProfit)],
    [subhead('Expenses')],
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
