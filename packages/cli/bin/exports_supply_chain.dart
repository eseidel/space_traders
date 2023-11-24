import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';

final extractable = <TradeSymbol>{
  TradeSymbol.ALUMINUM_ORE,
  TradeSymbol.AMMONIA_ICE,
  TradeSymbol.COPPER_ORE,
  TradeSymbol.GOLD_ORE,
  TradeSymbol.ICE_WATER,
  TradeSymbol.IRON_ORE,
  TradeSymbol.LIQUID_HYDROGEN,
  TradeSymbol.LIQUID_NITROGEN,
  TradeSymbol.MERITIUM_ORE,
  TradeSymbol.PRECIOUS_STONES,
  TradeSymbol.QUARTZ_SAND,
  TradeSymbol.SILICON_CRYSTALS,
  TradeSymbol.SILVER_ORE,
};

MarketListing? nearestListingWithExport(
  SystemsCache systemsCache,
  MarketListingCache marketListings,
  TradeSymbol tradeSymbol,
  WaypointSymbol waypointSymbol,
) {
  final listings = marketListings.listings
      // Listings in this same system which export the good.
      .where(
        (entry) =>
            entry.waypointSymbol.systemSymbol == waypointSymbol.systemSymbol &&
            entry.exports.contains(tradeSymbol),
      )
      .toList();
  final destination = systemsCache.waypoint(waypointSymbol);
  listings.sort(
    (a, b) => systemsCache
        .waypoint(a.waypointSymbol)
        .distanceTo(destination)
        .compareTo(
          systemsCache.waypoint(b.waypointSymbol).distanceTo(destination),
        ),
  );
  return listings.firstOrNull;
}

class Sourcer {
  const Sourcer({
    required this.marketListings,
    required this.systemsCache,
    required this.staticCaches,
    required this.marketPrices,
  });

  final MarketListingCache marketListings;
  final SystemsCache systemsCache;
  final StaticCaches staticCaches;
  final MarketPrices marketPrices;

  void sourceViaShuttle(
    TradeSymbol tradeSymbol,
    WaypointSymbol waypointSymbol,
  ) {
    // No need to manufacture if we can extract.
    if (extractable.contains(tradeSymbol)) {
      // Find the nearest extraction location?
      logger.info('Extract $tradeSymbol');
      return;
    }

    // Look for the nearest export of the good.
    final closest = nearestListingWithExport(
      systemsCache,
      marketListings,
      tradeSymbol,
      waypointSymbol,
    );
    if (closest == null) {
      logger.warn('No export for $tradeSymbol for $waypointSymbol');
      return;
    }
    logger.info('Shuttle $tradeSymbol from '
        '${closest.waypointSymbol} to $waypointSymbol');
    sourceViaManufacture(tradeSymbol, closest.waypointSymbol);
  }

  void sourceViaManufacture(
    TradeSymbol tradeSymbol,
    WaypointSymbol waypointSymbol,
  ) {
    logger.info('Manufacture $tradeSymbol at $waypointSymbol');
    final listing = marketListings[waypointSymbol];
    if (listing == null) {
      logger.warn('No listing for $waypointSymbol');
      return;
    }
    final imports = staticCaches.exports[tradeSymbol]!.imports;
    for (final import in imports) {
      sourceGoodsFor(import, waypointSymbol);
    }
  }

  void sourceGoodsFor(TradeSymbol tradeSymbol, WaypointSymbol waypointSymbol) {
    final listing = marketListings[waypointSymbol];
    // If the end isn't a market this must be a shuttle step.
    if (listing == null) {
      sourceViaShuttle(tradeSymbol, waypointSymbol);
    } else {
      // If we're sourcing for an export, this must be a manufacture step.
      if (listing.exports.contains(tradeSymbol)) {
        sourceViaManufacture(tradeSymbol, waypointSymbol);
      } else {
        // If we're sourcing for an import, this must be a shuttle step.
        sourceViaShuttle(tradeSymbol, waypointSymbol);
      }
    }
  }
}

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final staticCaches = StaticCaches.load(fs);
  final systemsCache = SystemsCache.load(fs)!;
  final marketListings = MarketListingCache.load(fs, staticCaches.tradeGoods);
  final marketPrices = MarketPrices.load(fs);
  final agentCache = AgentCache.load(fs)!;

  final jumpgate = systemsCache
      .jumpGateWaypointForSystem(agentCache.headquartersSystemSymbol)!;
  const tradeSymbol = TradeSymbol.FAB_MATS;

  final waypointSymbol = jumpgate.waypointSymbol;
  logger.info('$tradeSymbol for $waypointSymbol');
  Sourcer(
    marketListings: marketListings,
    systemsCache: systemsCache,
    staticCaches: staticCaches,
    marketPrices: marketPrices,
  ).sourceGoodsFor(tradeSymbol, waypointSymbol);
}

void main(List<String> args) async {
  await runOffline(args, command);
}
