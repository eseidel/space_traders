import 'package:cli/cache/transactions.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';
import 'package:file/file.dart';

DateTime snapToHour(DateTime time) {
  return DateTime.utc(time.year, time.month, time.day, time.hour);
}

int hoursAgo(DateTime time) {
  return DateTime.now().difference(time).inHours;
}

Future<void> command(FileSystem fs, List<String> args) async {
  // Credits per hour.
  final transactions = TransactionLog.load(fs);

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
      final prettyDiff = creditsString(diff);
      final diffString = diff > 0 ? '+$prettyDiff' : prettyDiff;
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

void main(List<String> args) async {
  await runOffline(args, command);
}
