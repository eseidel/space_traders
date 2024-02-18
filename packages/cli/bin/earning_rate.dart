import 'package:cli/cli.dart';
import 'package:cli/printing.dart';

DateTime snapToHour(DateTime time) {
  return DateTime.utc(time.year, time.month, time.day, time.hour);
}

int hoursAgo(DateTime time) {
  return DateTime.timestamp().difference(time).inHours;
}

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  // Credits per hour.
  final oneDayAgoAsHour =
      snapToHour(DateTime.timestamp().subtract(const Duration(hours: 24)));
  final transactions = await db.transactionsAfter(oneDayAgoAsHour);
  final firstTransactionHour = snapToHour(transactions.first.timestamp);

  const timeWidth = 5;
  const creditsWidth = 15;

  // print credit data on the hour.
  var nextPrintDate = firstTransactionHour.isBefore(oneDayAgoAsHour)
      ? oneDayAgoAsHour
      : firstTransactionHour;
  var latestCredits = 0;
  var lastPeriodCredits = 0;
  for (final transaction in transactions) {
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
  final last = transactions.lastOrNull;
  if (last != null) {
    final sinceLast =
        approximateDuration(DateTime.timestamp().difference(last.timestamp))
            .padRight(timeWidth);
    final credits = creditsString(last.agentCredits).padLeft(creditsWidth);
    logger.info('-$sinceLast $credits');
  }
  // Required or main will hang.
  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
