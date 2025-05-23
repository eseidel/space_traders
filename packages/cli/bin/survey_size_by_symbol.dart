import 'package:cli/cli.dart';
import 'package:collection/collection.dart';

Future<void> command(Database db, ArgResults argResults) async {
  final surveys = await db.surveys.all();

  // Survey size distribution by tradeSymbol
  logger.info('Survey size distribution by tradeSymbol');
  final sizeCountBySymbol = <TradeSymbol, Map<SurveySize, int>>{};
  for (final survey in surveys) {
    final size = survey.survey.size;
    for (final symbol in survey.survey.deposits.map((d) => d.symbol)) {
      sizeCountBySymbol.putIfAbsent(symbol, () => {})[size] =
          (sizeCountBySymbol[symbol]![size] ?? 0) + 1;
    }
  }
  final symbols = sizeCountBySymbol.keys.toList()..sort();
  final symbolLength = symbols.map((e) => e.value.length).max;
  const countLength = 6;
  const percentLength = 4;
  final sizeLength = SurveySize.values.map((e) => e.toString().length).max;

  for (final symbol in symbols) {
    final counts = sizeCountBySymbol[symbol]!;
    final total = counts.values.reduce((a, b) => a + b);
    logger.info(
      '${symbol.value.padRight(symbolLength)} '
      '${total.toString().padLeft(countLength)}',
    );
    // SurveySizeEnum.values rather than counts.keys print in consistent order.
    for (final size in SurveySize.values) {
      final count = counts[size]!;
      final percent = count / total;
      logger.info(
        '  ${size.toString().padRight(sizeLength)} '
        '${percent.toStringAsFixed(2).padLeft(percentLength)}% '
        '${count.toString().padLeft(countLength)}',
      );
    }
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
