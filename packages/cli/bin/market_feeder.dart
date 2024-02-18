import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/trading.dart';
import 'package:collection/collection.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final staticCaches = StaticCaches.load(fs);
  final systemsCache = SystemsCache.load(fs)!;
  final marketListings = await MarketListingSnapshot.load(db);

  final marketPrices = await MarketPrices.load(db);
  final systemConnectivity = await loadSystemConnectivity(db);
  final routePlanner = RoutePlanner.fromSystemsCache(
    systemsCache,
    systemConnectivity,
    sellsFuel: defaultSellsFuel(marketListings),
  );

  final behaviorCache = BehaviorCache.load(fs);

  const shipType = ShipType.LIGHT_HAULER;
  final ship = staticCaches.shipyardShips[shipType]!;
  final shipSpec = ship.shipSpec;
  final credits = await myCredits(db);

  // Given a desired export.  Find a market to feed.
  final export = TradeSymbol.fromJson(argResults['export'] as String)!;
  final listing = marketListings.listings
      .firstWhereOrNull((l) => l.exports.contains(export));
  if (listing == null) {
    logger.info('No market found for $export');
    return;
  }

  // Look up what trade symbols are required to produce the export.
  final tradeSymbols = staticCaches.exports[export]!.imports;
  const minProfitPerSecond = -100;
  final waypointSymbol = listing.waypointSymbol;

  logger.info('$shipType @ $waypointSymbol, '
      'speed = ${shipSpec.speed} '
      'capacity = ${shipSpec.cargoCapacity}, '
      'fuel <= ${shipSpec.fuelCapacity}, '
      'outlay <= $credits');

  final neededSymbols = <TradeSymbol>[];
  for (final tradeSymbol in tradeSymbols) {
    final price = marketPrices.priceAt(waypointSymbol, tradeSymbol);
    if (price != null &&
        SupplyLevel.values.indexOf(price.supply) <
            SupplyLevel.values.indexOf(SupplyLevel.ABUNDANT)) {
      neededSymbols.add(tradeSymbol);
    }
    logger.info('$tradeSymbol : ${price?.supply}');
  }

  final deals = scanAndFindDeals(
    systemsCache,
    systemConnectivity,
    marketPrices,
    routePlanner,
    maxTotalOutlay: credits,
    startSymbol: waypointSymbol,
    shipSpec: shipSpec,
    filter: avoidDealsInProgress(
      behaviorCache.dealsInProgress(),
      filter: (Deal deal) {
        return deal.destinationSymbol == waypointSymbol &&
            neededSymbols.contains(deal.tradeSymbol);
      },
    ),
    minProfitPerSecond: minProfitPerSecond,
  );

  logger.info('Available:');
  for (final deal in deals) {
    logger.info('  ${describeCostedDeal(deal)}');
  }

  final dealsInProgress = behaviorCache.dealsInProgress();
  final feederDeals = dealsInProgress.where(
    (deal) => deal.deal.destinationSymbol == waypointSymbol,
  );
  if (feederDeals.isEmpty) {
    logger.info('In progress: None');
  } else {
    logger.info('In progress:');
    for (final deal in feederDeals) {
      logger.info('  ${describeCostedDeal(deal)}');
    }
  }

  await db.close();
}

void main(List<String> args) async {
  await runOffline(
    args,
    command,
    addArgs: (ArgParser parser) {
      parser.addOption(
        'export',
        abbr: 'e',
        help: 'Export to find a market for',
        defaultsTo: TradeSymbol.FAB_MATS.value,
      );
    },
  );
}
