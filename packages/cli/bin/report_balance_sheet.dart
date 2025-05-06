import 'package:cli/accounting/balance_sheet.dart';
import 'package:cli/cli.dart';

Future<void> command(Database db, ArgResults argResults) async {
  final balance = await computeBalanceSheet(db);

  String c(int credits) => creditsString(credits);
  logger
    ..info('Balance Sheet:')
    ..info('  Assets:')
    ..info('    Cash: ${c(balance.cash)}')
    ..info('    Inventory: ${c(balance.inventory)}')
    ..info('    Ships: ${c(balance.ships)}')
    ..info('  Total Assets: ${c(balance.totalAssets)}')
    ..info('  Liabilities:')
    ..info('    Loans: ${c(balance.loans)}')
    ..info('  Total Liabilities: ${c(balance.totalLiabilities)}')
    ..info('  Total: ${c(balance.total)}');
}

void main(List<String> args) async {
  await runOffline(args, command);
}
