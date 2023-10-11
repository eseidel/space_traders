import 'package:cli/cli.dart';
import 'package:stats/stats.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final extractions = await db.allExtractions();
  // Count extractions by surveySignature
  final extractionCountBySurveySignature = <String, int>{};
  for (final extraction in extractions) {
    final signature = extraction.surveySignature;
    if (signature == null) {
      continue;
    }
    extractionCountBySurveySignature[signature] =
        (extractionCountBySurveySignature[signature] ?? 0) + 1;
  }

  final surveys = await db.allSurveys();
  final surveyBySignature = <String, HistoricalSurvey>{};
  for (final survey in surveys) {
    surveyBySignature[survey.survey.signature] = survey;
  }

  final extractionCountsBySize = <SurveySizeEnum, List<int>>{};
  for (final extraction in extractions) {
    final survey = surveyBySignature[extraction.surveySignature];
    if (survey == null) {
      continue;
    }
    final extractionCount =
        extractionCountBySurveySignature[extraction.surveySignature];
    if (extractionCount == null) {
      continue;
    }
    extractionCountsBySize
        .putIfAbsent(survey.survey.size, () => [])
        .add(extractionCount);
  }

  for (final size in extractionCountsBySize.keys) {
    final values = extractionCountsBySize[size]!;
    final stats = Stats.fromData(values);
    logger.info('$size: ${stats.withPrecision(3)}');
  }

  final allCounts = extractionCountsBySize.values.expand((e) => e).toList();
  final stats = Stats.fromData(allCounts);
  logger.info('all: ${stats.withPrecision(3)}');

  // Survey size distribution by tradeSymbol
  final sizeCountBySymbol = <String, Map<SurveySizeEnum, int>>{};
  for (final survey in surveys) {
    final size = survey.survey.size;
    for (final symbol in survey.survey.deposits.map((d) => d.symbol)) {
      sizeCountBySymbol.putIfAbsent(symbol, () => {})[size] =
          (sizeCountBySymbol[symbol]![size] ?? 0) + 1;
    }
  }
  for (final symbol in sizeCountBySymbol.keys) {
    final counts = sizeCountBySymbol[symbol]!;
    final total = counts.values.reduce((a, b) => a + b);
    logger.info('$symbol: $total');
    for (final size in counts.keys) {
      final count = counts[size]!;
      logger.info('  $size: $count');
    }
  }

  await db.close();
}

void main(List<String> args) async {
  await runOffline(
    args,
    command,
  );
}
