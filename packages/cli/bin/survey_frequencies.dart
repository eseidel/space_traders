import 'package:cli/cli.dart';
import 'package:collection/collection.dart';

Future<void> command(Database db, ArgResults argResults) async {
  // Load up historical surveys from the db.
  // Count all the trade symbols they saw.
  // Print drop rates for each trade symbol.

  final surveys = await db.surveys.all();
  // Was the trade symbol in the survey at all.
  final surveyBySymbol = <TradeSymbol, int>{};
  // Of all values across all surveys, how many were the trade symbol.
  final depositBySymbol = <TradeSymbol, int>{};
  // The total deposits for surveys containing this trade symbol.
  // Used for computing the expected # of deposits of a trade symbol given
  // its known to be in a survey.
  final totalDepositsByUniqueSymbol = <TradeSymbol, int>{};
  final totalSurveys = surveys.length;
  var totalDeposits = 0;
  for (final survey in surveys) {
    final uniqueSymbols = survey.survey.deposits.map((e) => e.symbol).toSet();
    for (final symbol in uniqueSymbols) {
      surveyBySymbol[symbol] = (surveyBySymbol[symbol] ?? 0) + 1;
      totalDepositsByUniqueSymbol[symbol] =
          (totalDepositsByUniqueSymbol[symbol] ?? 0) +
          survey.survey.deposits.length;
    }
    for (final deposit in survey.survey.deposits) {
      depositBySymbol[deposit.symbol] =
          (depositBySymbol[deposit.symbol] ?? 0) + 1;
    }
    totalDeposits += survey.survey.deposits.length;
  }
  logger.info('$totalSurveys surveys with $totalDeposits deposits');
  final symbols = Set<TradeSymbol>.from(surveyBySymbol.keys)
    ..addAll(depositBySymbol.keys)
    ..toList()
    ..sorted((a, b) => a.value.compareTo(b.value));

  final symbolLength = symbols.map((e) => e.value.length).max;
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
    final depositCountInSurveys = totalDepositsByUniqueSymbol[symbol] ?? 0;
    final surveyPercent = surveyCount / totalSurveys;
    final depositOverallPercent = depositCount / totalDeposits;
    final depositPerSurveyPercent = depositCount / depositCountInSurveys;
    logger.info(
      '${symbol.value.padRight(symbolLength)} '
      '${count(surveyCount)} ${percent(surveyPercent)}% '
      '${count(depositCount)} ${percent(depositOverallPercent)}% '
      '(${percent(depositPerSurveyPercent)}%)',
    );
  }
  logger.info(
    'number in () is the expected number of deposits per survey '
    'if the symbol is known to be in the survey',
  );
}

void main(List<String> args) async {
  await runOffline(args, command);
}
