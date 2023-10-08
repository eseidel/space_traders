import 'package:cli/cli.dart';
import 'package:collection/collection.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  // Load up historical surveys from the db.
  // Count all the trade symbols they saw.
  // Print drop rates for each trade symbol.

  final db = await defaultDatabase();
  final surveys = await db.allSurveys();
  // Was the trade symbol in the survey at all.
  final surveyBySymbol = <String, int>{};
  // Of all values across all surveys, how many were the trade symbol.
  final depositBySymbol = <String, int>{};
  final totalSurveys = surveys.length;
  var totalDeposits = 0;
  for (final survey in surveys) {
    final uniqueSymbols = survey.survey.deposits.map((e) => e.symbol).toSet();
    for (final symbol in uniqueSymbols) {
      surveyBySymbol[symbol] = (surveyBySymbol[symbol] ?? 0) + 1;
    }
    for (final deposit in survey.survey.deposits) {
      depositBySymbol[deposit.symbol] =
          (depositBySymbol[deposit.symbol] ?? 0) + 1;
    }
    totalDeposits += survey.survey.deposits.length;
  }
  logger.info('$totalSurveys surveys with $totalDeposits deposits');
  final symbols = Set<String>.from(surveyBySymbol.keys)
    ..addAll(depositBySymbol.keys)
    ..toList()
    ..sorted((a, b) => a.compareTo(b));

  final symbolLength = symbols.map((e) => e.length).max;
  const countLength = 5;
  const percentLength = 4;
  String percent(double value) =>
      (100.0 * value).toStringAsFixed(1).padLeft(percentLength);
  String count(int value) => value.toString().padLeft(countLength);

  logger.info(
    'Symbol'.padRight(symbolLength) +
        ' Survey'.padLeft(countLength + percentLength + 3) +
        ' Deposit'.padLeft(countLength + percentLength + 3),
  );
  for (final symbol in symbols) {
    final surveyCount = surveyBySymbol[symbol] ?? 0;
    final depositCount = depositBySymbol[symbol] ?? 0;
    final surveyPercent = surveyCount / totalSurveys;
    final depositPercent = depositCount / totalDeposits;
    logger.info(
      '${symbol.padRight(symbolLength)} '
      '${count(surveyCount)} ${percent(surveyPercent)}% '
      '${count(depositCount)} ${percent(depositPercent)}%',
    );
  }

  await db.close();
}

void main(List<String> args) async {
  await runOffline(
    args,
    command,
  );
}
