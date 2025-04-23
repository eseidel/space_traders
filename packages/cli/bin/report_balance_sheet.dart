import 'package:cli/accounting/balance_sheet.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final balance = await computeBalanceSheet(fs, db);

  String c(int credits) => creditsString(credits);
  logger
    ..info('ASSETS')
    ..info('  Cash: ${c(balance.cash)}')
    ..info('  Inventory: ${c(balance.inventory)}')
    ..info('  Ships: ${c(balance.ships)}')
    ..info('Total: ${c(balance.total)}');
}

void main(List<String> args) async {
  await runOffline(args, command);
}
