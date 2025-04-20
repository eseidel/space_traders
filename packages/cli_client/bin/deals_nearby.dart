import 'package:cli_client/cli_args.dart';
import 'package:cli_client/cli_client.dart';
import 'package:cli_table/cli_table.dart';
import 'package:client/client.dart';
import 'package:types/prediction.dart';

Future<void> cliMain(BackendClient client, ArgResults argResults) async {
  final shipType = shipTypeFromArg(argResults['ship'] as String);
  final limit = int.parse(argResults['limit'] as String);
  final startArg = argResults['start'] as String?;
  final credits = int.parse(argResults['credits'] as String);

  final response = await client.getNearbyDeals(
    shipType: shipType,
    limit: limit,
    start: startArg != null ? WaypointSymbol.fromString(startArg) : null,
    credits: credits,
  );

  final shipSpec = response.shipSpec;
  final extraSellOpps = response.extraSellOpps;
  logger.info(
    '$shipType @ ${response.startSymbol}, '
    'speed = ${shipSpec.speed} '
    'capacity = ${shipSpec.cargoCapacity}, '
    'fuel <= ${shipSpec.fuelCapacity}, '
    'outlay <= $credits',
  );

  if (extraSellOpps.isNotEmpty) {
    logger.info('Extra sell opps:');
    for (final extraOpp in extraSellOpps) {
      final String type;
      if (extraOpp.isConstructionDelivery) {
        type = 'construction';
      } else if (extraOpp.isContractDelivery) {
        type = 'contract';
      } else {
        type = 'subsidy';
      }
      logger.info(
        '  $type: ${extraOpp.maxUnits} ${extraOpp.tradeSymbol} -> '
        '${extraOpp.waypointSymbol} @ ${creditsString(extraOpp.price)}',
      );
    }
  }

  logger.info('Opps for ${response.tradeSymbolCount} trade symbols.');

  final deals = response.deals;
  if (deals.isEmpty) {
    logger.info('No deal found.');
    return;
  }

  logger.info('Top $limit deals:');

  final table = Table(
    header: [
      'Symbol',
      'Start',
      'Buy',
      'End',
      'Sell',
      'Profit',
      'Gain',
      'Time',
      'c/s',
      'Outlay',
      'COGS',
      'OpEx',
    ],
    style: const TableStyle(compact: true),
  );

  final allSameSystem = deals.every(
    (deal) => deal.deal.withinSystem(deals.first.deal.sourceSymbol.system),
  );
  String w(WaypointSymbol symbol) =>
      allSameSystem ? symbol.waypointName : symbol.sectorLocalName;
  Map<String, dynamic> rightAlign(String content) => <String, dynamic>{
    'content': content,
    'hAlign': HorizontalAlign.right,
  };
  Map<String, dynamic> c(int credits) => rightAlign(creditsString(credits));
  for (final nearby in deals) {
    final costed = nearby.costed;
    final deal = nearby.deal;
    final profit = costed.expectedProfit;
    final sign = profit > 0 ? '+' : '';
    final profitPercent = (profit / costed.expectedCosts) * 100;
    final tradeSymbol = deal.tradeSymbol.value;
    final name =
        costed.isContractDeal ? '$tradeSymbol (contract)' : tradeSymbol;

    final inProgressMarker = !nearby.inProgress ? '' : '*';

    table.add([
      '$name$inProgressMarker',
      w(deal.sourceSymbol),
      c(costed.expectedInitialBuyPrice),
      w(deal.destinationSymbol),
      c(costed.expectedInitialSellPrice),
      c(profit),
      rightAlign('$sign${profitPercent.toStringAsFixed(0)}%'),
      rightAlign(approximateDuration(costed.expectedTime)),
      rightAlign(costed.expectedProfitPerSecond.toString()),
      c(costed.expectedCosts),
      c(costed.expectedCostOfGoodsSold),
      c(costed.expectedOperationalExpenses),
    ]);
  }
  logger.info(table.toString());
}

void main(List<String> args) async {
  await runAsClient(
    args,
    cliMain,
    addArgs: (ArgParser parser) {
      parser
        ..addOption(
          'start',
          abbr: 's',
          help: 'Starting system (defaults to agent headquarters)',
        )
        ..addOption(
          'limit',
          abbr: 'l',
          help: 'Maximum number of deals to show',
          defaultsTo: '10',
        )
        ..addOption(
          'ship',
          abbr: 't',
          help: 'Ship type used for calculations',
          allowed: ShipType.values.map(argFromShipType),
          defaultsTo: argFromShipType(ShipType.LIGHT_HAULER),
        )
        ..addOption(
          'credits',
          abbr: 'c',
          help: 'Credit limit used for calculations',
          defaultsTo: '1000000',
        );
    },
  );
}
