import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';
import 'package:cli_table/cli_table.dart';

String annotatedName(CostedDeal deal) {
  if (deal.isConstructionDeal) {
    return '${deal.tradeSymbol} (construction)';
  }
  if (deal.isContractDeal) {
    return '${deal.tradeSymbol} (contract)';
  }
  return deal.tradeSymbol.value;
}

Future<void> cliMain(FileSystem fs, ArgResults argResults) async {
  final behaviorCache = BehaviorCache.load(fs);

  final states =
      behaviorCache.states.where((state) => state.deal != null).toList();

  if (states.isEmpty) {
    logger.info('No deal found.');
    return;
  }
  final table = Table(
    header: [
      'S#',
      'Symbol',
      'Src',
      'Buy',
      'Dest',
      'Sell',
      'Profit',
      'Gain %',
      'c/s',
      'Est',
      'Act',
    ],
    style: const TableStyle(compact: true),
  );

  final start = states.first.deal!.deal.sourceSymbol;
  final allSameSystem = states.every(
    (s) =>
        s.deal!.deal.sourceSymbol.systemSymbol == start.systemSymbol &&
        s.deal!.deal.destinationSymbol.systemSymbol == start.systemSymbol,
  );

  String w(WaypointSymbol symbol) =>
      allSameSystem ? symbol.waypointName : symbol.sectorLocalName;
  Map<String, dynamic> rightAlign(String content) => <String, dynamic>{
        'content': content,
        'hAlign': HorizontalAlign.right,
      };
  Map<String, dynamic> c(int credits) => rightAlign(creditsString(credits));
  for (final state in states) {
    final costed = state.deal!;
    final deal = costed.deal;
    final profit = costed.expectedProfit;
    final sign = profit > 0 ? '+' : '';
    final profitPercent = (profit / costed.expectedCosts) * 100;

    final since = DateTime.timestamp().difference(costed.startTime);
    final actualDuration = approximateDuration(since);
    final expectedDuration = approximateDuration(costed.expectedTime);

    table.add([
      state.shipSymbol.hexNumber,
      annotatedName(costed),
      w(deal.sourceSymbol),
      c(costed.expectedInitialBuyPrice),
      w(deal.destinationSymbol),
      c(costed.expectedInitialSellPrice),
      c(profit),
      rightAlign('$sign${profitPercent.toStringAsFixed(0)}%'),
      rightAlign(costed.expectedProfitPerSecond.toString()),
      rightAlign(expectedDuration),
      rightAlign(actualDuration),
    ]);
  }
  logger.info(table.toString());
}

void main(List<String> args) async {
  await runOffline(args, cliMain);
}
