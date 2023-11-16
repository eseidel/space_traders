import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/trading.dart';
import 'package:collection/collection.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final staticCache = StaticCaches.load(fs);
  final systemsCache = SystemsCache.load(fs)!;
  final marketListings = MarketListingCache.load(fs, staticCache.tradeGoods);

  final marketPrices = MarketPrices.load(fs);
  final routePlanner = RoutePlanner(
    systemsCache: systemsCache,
    sellsFuel: defaultSellsFuel(marketListings),
  );
  final staticCaches = StaticCaches.load(fs);

  const shipType = ShipType.LIGHT_HAULER;
  final ship = staticCaches.shipyardShips[shipType]!;
  final shipSpeed = ship.engine.speed;
  final fuelCapacity = ship.frame.fuelCapacity;
  final cargoCapacity = ship.cargoCapacity;

  // Given a desired export.  Find a market to feed.
  final export = TradeSymbol.fromJson(argResults['export'] as String)!;
  final listing = marketListings.listings
      .firstWhereOrNull((l) => l.exports.contains(export));
  if (listing == null) {
    logger.info('No market found for $export');
    return;
  }

  // Look up what trade symbols are required dto produce the export.
  final targetImports = [
    TradeSymbol.IRON,
    TradeSymbol.QUARTZ_SAND,
    TradeSymbol.PLASTICS,
  ];

  final marketScan = scanNearbyMarkets(
    systemsCache,
    marketPrices,
    systemSymbol: listing.waypointSymbol.systemSymbol,
    maxWaypoints: 100,
  );
  final deals = findDealsFor(
    marketPrices,
    systemsCache,
    routePlanner,
    marketScan,
    maxTotalOutlay: 1000000,
    startSymbol: listing.waypointSymbol,
    fuelCapacity: fuelCapacity,
    cargoCapacity: cargoCapacity,
    shipSpeed: shipSpeed,
    filter: (Deal deal) {
      return deal.destinationSymbol == listing.waypointSymbol &&
          targetImports.contains(deal.tradeSymbol);
    },
    minProfitPerSecond: -5,
  );
  for (final deal in deals) {
    logger.info(describeCostedDeal(deal));
  }
}

void main(List<String> args) async {
  await runOffline(
    args,
    command,
    addArgs: (parser) {
      parser.addOption(
        'export',
        abbr: 'e',
        help: 'Export to find a market for',
        defaultsTo: TradeSymbol.FAB_MATS.value,
      );
    },
  );
}
