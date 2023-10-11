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

  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
