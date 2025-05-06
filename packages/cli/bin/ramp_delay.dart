import 'package:cli/cli.dart';

void printRampDelay(Iterable<Transaction> transactions) {
  // Walk through all transactions until we find a ship purchase.  When we do
  // walk backwards until we find the point at which time we had enough to
  // buy the ship.  The difference between those times is the ramp delay.

  const lastShipPurchaseIndex = -1;
  final transactionsToExamine =
      transactions.skip(lastShipPurchaseIndex + 1).toList();
  final shipPurchaseIndex = transactionsToExamine.indexWhere(
    (Transaction t) => t.transactionType == TransactionType.shipyard,
  );
  if (shipPurchaseIndex == -1) {
    logger.info('No ship purchases found.');
    return;
  }
  final shipPurchase = transactionsToExamine[shipPurchaseIndex];
  final shipPurchaseAmount = shipPurchase.perUnitPrice;
  for (var i = shipPurchaseIndex - 1; i > lastShipPurchaseIndex; i--) {
    final transaction = transactionsToExamine[i];
    if (transaction.agentCredits > shipPurchaseAmount) {
      final rampDelay = shipPurchase.timestamp.difference(
        transaction.timestamp,
      );
      logger.info('Ramp delay: $rampDelay');
      break;
    }
  }
}

Future<void> command(Database db, ArgResults argResults) async {
  final transactions = await db.allTransactions();
  printRampDelay(transactions);
}

void main(List<String> args) async {
  await runOffline(args, command);
}
