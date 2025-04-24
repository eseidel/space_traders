import 'package:cli/accounting/income_statement.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final report = await computeIncomeStatement(db);

  String c(int credits) => creditsString(credits);

  logger
    ..info('Transactions: ${report.numberOfTransactions}')
    ..info('Between ${report.start} and ${report.end}')
    ..info('Revenues')
    ..info('  Sales: ${c(report.sales)}')
    ..info('  Contracts: ${c(report.contracts)}')
    ..info('Total Revenues: ${c(report.revenue)}')
    ..info('Cost of Goods Sold')
    ..info('  Goods: ${c(report.goods)}')
    ..info('  Fuel: ${c(report.fuel)}')
    ..info('Total Cost of Goods Sold: ${c(report.costOfGoodsSold)}')
    ..info('Gross Profit: ${c(report.grossProfit)}')
    ..info('Expenses')
    ..info('Total Expenses: ${c(report.expenses)}')
    ..info('Net Income: ${c(report.netIncome)}')
    ..info('Capital Expenditures: ${c(report.capEx)}');
}

void main(List<String> args) async {
  await runOffline(args, command);
}
