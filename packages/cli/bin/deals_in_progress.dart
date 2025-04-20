import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli_table/cli_table.dart';
import 'package:types/prediction.dart';

String annotatedName(CostedDeal deal) {
  if (deal.isConstructionDeal) {
    return '${deal.tradeSymbol} (construction)';
  }
  if (deal.isContractDeal) {
    return '${deal.tradeSymbol} (contract)';
  }
  return deal.tradeSymbol.value;
}

Future<void> cliMain(FileSystem fs, Database db, ArgResults argResults) async {
  final behaviors = await BehaviorSnapshot.load(db);
  final states = behaviors.states.where((state) => state.deal != null).toList();

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
    (s) => s.deal!.deal.withinSystem(start.system),
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
    final isLate = since > costed.expectedTime;
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
      rightAlign(isLate ? red.wrap(actualDuration)! : actualDuration),
    ]);
  }
  logger.info(table.toString());

  final ships = await ShipSnapshot.load(db);
  final idleHaulers =
      behaviors.idleHaulerSymbols(ships).map((s) => s.hexNumber).toList();
  if (idleHaulers.isNotEmpty) {
    logger.info('${idleHaulers.length} idle: ${idleHaulers.join(', ')}');
  }

  final minerHaulers =
      behaviors.states
          .where((state) => state.behavior == Behavior.minerHauler)
          .map((state) => state.shipSymbol.hexNumber)
          .toList();
  if (minerHaulers.isNotEmpty) {
    logger.info(
      '${minerHaulers.length} miner haulers: ${minerHaulers.join(', ')}',
    );
  }
}

void main(List<String> args) async {
  await runOffline(args, cliMain);
}
