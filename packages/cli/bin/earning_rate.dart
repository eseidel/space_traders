import 'package:cli/accounting/income_statement.dart';
import 'package:cli/cli.dart';

import './report_profit_loss.dart';

DateTime snapToHour(DateTime time) {
  return DateTime.utc(time.year, time.month, time.day, time.hour);
}

int hoursAgo(DateTime time) {
  return DateTime.timestamp().difference(time).inHours;
}

Future<void> command(Database db, ArgResults argResults) async {
  // Credits per hour.
  final oneDayAgoAsHour = snapToHour(
    DateTime.timestamp().subtract(const Duration(hours: 24)),
  );
  final transactions = await db.transactionsAfter(oneDayAgoAsHour);
  final firstTransactionHour = snapToHour(transactions.first.timestamp);

  const timeWidth = 5;
  const creditsWidth = 15;

  // print credit data on the hour.
  var nextPrintDate =
      firstTransactionHour.isBefore(oneDayAgoAsHour)
          ? oneDayAgoAsHour
          : firstTransactionHour;
  var latestCredits = 0;
  var lastPeriodCredits = 0;
  for (final transaction in transactions) {
    latestCredits = transaction.agentCredits;
    if (transaction.timestamp.isAfter(nextPrintDate)) {
      final diff = latestCredits - lastPeriodCredits;
      final diffString = creditsChangeString(diff);
      final agoString =
          hoursAgo(nextPrintDate) == 0
              ? 'now'
              : '-${hoursAgo(nextPrintDate)}h'.padRight(timeWidth);
      final credits = creditsString(latestCredits).padRight(creditsWidth);
      logger.info('$agoString $credits $diffString');
      lastPeriodCredits = latestCredits;
      nextPrintDate = nextPrintDate.add(const Duration(hours: 1));
    }
  }
  final last = transactions.lastOrNull;
  if (last != null) {
    final sinceLast = approximateDuration(
      DateTime.timestamp().difference(last.timestamp),
    ).padRight(timeWidth);
    final credits = creditsString(last.agentCredits).padLeft(creditsWidth);
    logger.info('-$sinceLast $credits');
  }

  final incomeStatement = await computeIncomeStatement(transactions);
  printIncomeStatement(incomeStatement);
}

void main(List<String> args) async {
  await runOffline(args, command);
}
