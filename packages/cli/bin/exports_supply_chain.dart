import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';

final minable = <TradeSymbol>{
  TradeSymbol.ALUMINUM_ORE,
  TradeSymbol.COPPER_ORE,
  TradeSymbol.GOLD_ORE,
  TradeSymbol.IRON_ORE,
  TradeSymbol.MERITIUM_ORE,
  TradeSymbol.SILVER_ORE,
  TradeSymbol.AMMONIA_ICE,
  TradeSymbol.ICE_WATER,
  TradeSymbol.PRECIOUS_STONES,
  TradeSymbol.QUARTZ_SAND,
  TradeSymbol.SILICON_CRYSTALS,
};

final siphonable = <TradeSymbol>{
  TradeSymbol.LIQUID_HYDROGEN,
  TradeSymbol.LIQUID_NITROGEN,
};

final extractable = <TradeSymbol>{
  ...minable,
  ...siphonable,
};

Set<TradeSymbol> extractableFrom(SystemWaypoint waypoint) {
  if (waypoint.isAsteroid) {
    return minable;
  }
  if (waypoint.type == WaypointType.GAS_GIANT) {
    return siphonable;
  }
  return {};
}

WaypointSymbol? nearestExtractionSiteFor(
  SystemsCache systemsCache,
  TradeSymbol tradeSymbol,
  WaypointSymbol waypointSymbol,
) {
  final destination = systemsCache.waypoint(waypointSymbol);
  final candidates = systemsCache
      .waypointsInSystem(waypointSymbol.system)
      .where(
        (waypoint) =>
            waypoint.isAsteroid || waypoint.type == WaypointType.GAS_GIANT,
      )
      .toList()
    ..sort(
      (a, b) => a.distanceTo(destination).compareTo(b.distanceTo(destination)),
    );
  return candidates.firstOrNull?.symbol;
}

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
            entry.waypointSymbol.system == waypointSymbol.system &&
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

// Returns the distance between two waypoints, or null if they are in different
// systems.
int? distanceBetween(
  SystemsCache systemsCache,
  WaypointSymbol a,
  WaypointSymbol b,
) {
  final aWaypoint = systemsCache.waypoint(a);
  final bWaypoint = systemsCache.waypoint(b);
  if (aWaypoint.system != bWaypoint.system) {
    return null;
  }
  return aWaypoint.distanceTo(bWaypoint).toInt();
}

String describeMarket(WaypointSymbol waypointSymbol, MarketPrice? price) {
  if (price == null) {
    return '$waypointSymbol (no market)';
  }
  return '$waypointSymbol (${price.supply}, ${price.activity})';
}

class Sourcer {
  const Sourcer({
    required this.marketListings,
    required this.systemsCache,
    required this.exportCache,
    required this.marketPrices,
  });

  final MarketListingCache marketListings;
  final SystemsCache systemsCache;
  final TradeExportCache exportCache;
  final MarketPrices marketPrices;

  void sourceViaShuttle(
    TradeSymbol tradeSymbol,
    WaypointSymbol waypointSymbol, {
    int indent = 0,
  }) {
    final prefix = ' ' * indent;

    final destinationPrice = marketPrices.priceAt(
      waypointSymbol,
      tradeSymbol,
    );

    // No need to manufacture if we can extract.
    if (extractable.contains(tradeSymbol)) {
      // Find the nearest extraction location?
      final location = nearestExtractionSiteFor(
        systemsCache,
        tradeSymbol,
        waypointSymbol,
      );
      final distance = location == null
          ? null
          : distanceBetween(systemsCache, waypointSymbol, location);
      logger.info('${prefix}Extract $tradeSymbol from $location, '
          'deliver to ${describeMarket(waypointSymbol, destinationPrice)} '
          'distance = $distance');
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
      logger.warn('${prefix}No export for $tradeSymbol for $waypointSymbol');
      return;
    }
    final closestPrice = marketPrices.priceAt(
      closest.waypointSymbol,
      tradeSymbol,
    );
    final distance = distanceBetween(
      systemsCache,
      closest.waypointSymbol,
      waypointSymbol,
    );
    logger.info('${prefix}Shuttle $tradeSymbol from '
        '${describeMarket(closest.waypointSymbol, closestPrice)} '
        'to ${describeMarket(waypointSymbol, destinationPrice)} '
        'distance = $distance');
    sourceViaManufacture(
      tradeSymbol,
      closest.waypointSymbol,
      indent: indent + 1,
    );
  }

  void sourceViaManufacture(
    TradeSymbol tradeSymbol,
    WaypointSymbol waypointSymbol, {
    int indent = 0,
  }) {
    final prefix = ' ' * indent;
    final destinationPrice = marketPrices.priceAt(
      waypointSymbol,
      tradeSymbol,
    );
    logger.info(
      '${prefix}Manufacture $tradeSymbol at '
      '${describeMarket(waypointSymbol, destinationPrice)}',
    );
    final listing = marketListings[waypointSymbol];
    if (listing == null) {
      logger.warn('${prefix}No listing for $waypointSymbol');
      return;
    }
    final imports = exportCache[tradeSymbol]!.imports;
    for (final import in imports) {
      sourceGoodsFor(import, waypointSymbol, indent: indent + 1);
    }
  }

  void sourceGoodsFor(
    TradeSymbol tradeSymbol,
    WaypointSymbol waypointSymbol, {
    int indent = 0,
  }) {
    final listing = marketListings[waypointSymbol];
    // If the end isn't a market this must be a shuttle step.
    if (listing == null) {
      sourceViaShuttle(tradeSymbol, waypointSymbol, indent: indent);
    } else {
      // If we're sourcing for an export, this must be a manufacture step.
      if (listing.exports.contains(tradeSymbol)) {
        sourceViaManufacture(tradeSymbol, waypointSymbol, indent: indent);
      } else {
        // If we're sourcing for an import, this must be a shuttle step.
        sourceViaShuttle(tradeSymbol, waypointSymbol, indent: indent);
      }
    }
  }
}

void source(
  MarketListingCache marketListings,
  SystemsCache systemsCache,
  TradeExportCache exportCache,
  MarketPrices marketPrices,
  TradeSymbol tradeSymbol,
  WaypointSymbol waypointSymbol,
) {
  logger.info('Sourcing $tradeSymbol for $waypointSymbol');
  Sourcer(
    marketListings: marketListings,
    systemsCache: systemsCache,
    exportCache: exportCache,
    marketPrices: marketPrices,
  ).sourceGoodsFor(tradeSymbol, waypointSymbol);
}

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final exportCache = TradeExportCache.load(fs);
  final systemsCache = SystemsCache.load(fs)!;
  final marketListings = MarketListingCache.load(fs);
  final marketPrices = MarketPrices.load(fs);
  final agentCache = AgentCache.load(fs)!;
  final constructionCache = ConstructionCache(db);

  final jumpgate = systemsCache
      .jumpGateWaypointForSystem(agentCache.headquartersSystemSymbol)!;
  final waypointSymbol = jumpgate.symbol;
  final construction = await constructionCache.getConstruction(waypointSymbol);

  final neededExports = construction!.materials
      .where((m) => m.required_ > m.fulfilled)
      .map((m) => m.tradeSymbol);
  for (final tradeSymbol in neededExports) {
    source(
      marketListings,
      systemsCache,
      exportCache,
      marketPrices,
      tradeSymbol,
      waypointSymbol,
    );
  }

  // Required or main() will hang.
  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
