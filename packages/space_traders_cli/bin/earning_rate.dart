import 'package:file/local.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/transactions.dart';

DateTime snapToHour(DateTime time) {
  return DateTime(time.year, time.month, time.day, time.hour);
}

int hoursAgo(DateTime time) {
  return DateTime.now().difference(time).inHours;
}

void main() async {
  // Credits per hour.
  const fs = LocalFileSystem();
  final transactions = await TransactionLog.load(fs);

  final oldest = transactions.entries.first;
  final firstTransactionHour = snapToHour(oldest.timestamp);
  final oneDayAgoAsHour =
      snapToHour(DateTime.now().subtract(const Duration(hours: 24)));

  const timeWidth = 5;
  const creditsWidth = 15;

  // print credit data on the hour.
  var nextPrintDate = firstTransactionHour.isBefore(oneDayAgoAsHour)
      ? oneDayAgoAsHour
      : firstTransactionHour;
  var latestCredits = 0;
  var lastPeriodCredits = 0;
  for (final transaction in transactions.entries) {
    latestCredits = transaction.agentCredits;
    if (transaction.timestamp.isAfter(nextPrintDate)) {
      final diff = latestCredits - lastPeriodCredits;
      final diffString = diff > 0 ? '+$diff' : diff.toString();
      final agoString = hoursAgo(nextPrintDate) == 0
          ? 'now'
          : '-${hoursAgo(nextPrintDate)}h'.padRight(timeWidth);
      final credits = creditsString(latestCredits).padRight(creditsWidth);
      logger.info('$agoString $credits $diffString');
      lastPeriodCredits = latestCredits;
      nextPrintDate = nextPrintDate.add(const Duration(hours: 1));
    }
  }
  final last = transactions.entries.lastOrNull;
  if (last != null) {
    final sinceLast =
        approximateDuration(DateTime.now().difference(last.timestamp))
            .padRight(timeWidth);
    final credits = creditsString(last.agentCredits).padLeft(creditsWidth);
    logger.info('-$sinceLast $credits');
  }
  // Print per-ship data.
}