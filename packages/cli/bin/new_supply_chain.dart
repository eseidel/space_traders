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

class DescribeContext {
  DescribeContext(this.systems, this.marketListings, this.marketPrices);
  final SystemsCache systems;
  final MarketListingSnapshot marketListings;
  final MarketPriceSnapshot marketPrices;
}

abstract class Node {
  Node(this.tradeSymbol);
  final TradeSymbol tradeSymbol;

  void describe(DescribeContext ctx, {int indent = 0});
}

abstract class Produce extends Node {
  Produce(super.tradeSymbol, this.waypointSymbol);
  final WaypointSymbol waypointSymbol;
}

class Extract extends Produce {
  Extract(super.tradeSymbol, super.waypointSymbol);

  @override
  void describe(DescribeContext ctx, {int indent = 0}) {
    final from = waypointSymbol.waypointName;
    final spaces = ' ' * indent;
    logger.info('${spaces}Extract $tradeSymbol from $from');
  }
}

class Shuttle extends Node {
  Shuttle(super.tradeSymbol, this.destination, this.source);
  final WaypointSymbol destination;

  // This could be a list if we wanted to support options.
  final Produce source;

  @override
  void describe(DescribeContext ctx, {int indent = 0}) {
    final distance = distanceBetween(
      ctx.systems,
      source.waypointSymbol,
      destination,
    );

    final sourcePrice = ctx.marketPrices.priceAt(
      source.waypointSymbol,
      tradeSymbol,
    );

    final destinationPrice = ctx.marketPrices.priceAt(
      destination,
      tradeSymbol,
    );

    final spaces = ' ' * indent;
    logger.info(
      '${spaces}Shuttle $tradeSymbol from '
      '${describeMarket(source.waypointSymbol, sourcePrice)} '
      'to ${describeMarket(destination, destinationPrice)} '
      'distance = $distance',
    );

    source.describe(ctx, indent: indent + 1);
  }
}

class Manufacture extends Produce {
  Manufacture(super.tradeSymbol, super.waypointSymbol, this.inputs);

  // This could map String -> List if we wanted to support options.
  final Map<TradeSymbol, Shuttle> inputs;

  @override
  void describe(DescribeContext ctx, {int indent = 0}) {
    final inputSymbols = inputs.keys.map((s) => s.toString()).join(', ');
    final spaces = ' ' * indent;
    logger.info(
      '${spaces}Manufacture $tradeSymbol at $waypointSymbol from $inputSymbols',
    );
    for (final input in inputs.values) {
      input.describe(ctx, indent: indent + 1);
    }
  }
}

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
  MarketListingSnapshot marketListings,
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
  final name = waypointSymbol.waypointName;
  if (price == null) {
    return '$name (no market)';
  }
  return '$name (${price.supply}, ${price.activity})';
}

class Sourcer {
  const Sourcer({
    required this.marketListings,
    required this.systemsCache,
    required this.exportCache,
    required this.marketPrices,
  });

  final MarketListingSnapshot marketListings;
  final SystemsCache systemsCache;
  final TradeExportCache exportCache;
  final MarketPriceSnapshot marketPrices;

  Produce? _shuttleSource(
    TradeSymbol tradeSymbol,
    WaypointSymbol waypointSymbol,
  ) {
    // No need to manufacture if we can extract.
    if (extractable.contains(tradeSymbol)) {
      // Find the nearest extraction location?
      final location = nearestExtractionSiteFor(
        systemsCache,
        tradeSymbol,
        waypointSymbol,
      );
      if (location == null) {
        logger.warn('No extraction site for $tradeSymbol for $waypointSymbol');
        return null;
      }
      return Extract(tradeSymbol, location);
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
      return null;
    }
    return sourceViaManufacture(tradeSymbol, closest.waypointSymbol);
  }

  Shuttle? sourceViaShuttle(
    TradeSymbol tradeSymbol,
    WaypointSymbol waypointSymbol,
  ) {
    final source = _shuttleSource(tradeSymbol, waypointSymbol);
    if (source == null) {
      return null;
    }
    return Shuttle(tradeSymbol, waypointSymbol, source);
  }

  Manufacture? sourceViaManufacture(
    TradeSymbol tradeSymbol,
    WaypointSymbol waypointSymbol,
  ) {
    final listing = marketListings[waypointSymbol];
    if (listing == null) {
      throw ArgumentError('No market listing for $waypointSymbol');
    }
    final imports = exportCache[tradeSymbol]!.imports;
    final inputs = <TradeSymbol, Shuttle>{};
    for (final import in imports) {
      final source = sourceViaShuttle(import, waypointSymbol);
      if (source == null) {
        return null;
      }
      inputs[import] = source;
    }
    return Manufacture(tradeSymbol, waypointSymbol, inputs);
  }

  Node? sourceGoodsFor(
    TradeSymbol tradeSymbol,
    WaypointSymbol waypointSymbol, {
    int indent = 0,
  }) {
    final listing = marketListings[waypointSymbol];
    // If the end isn't a market this must be a shuttle step.
    if (listing == null) {
      return sourceViaShuttle(tradeSymbol, waypointSymbol);
    } else {
      // If we're sourcing for an export, this must be a manufacture step.
      if (listing.exports.contains(tradeSymbol)) {
        return sourceViaManufacture(tradeSymbol, waypointSymbol);
      } else {
        // If we're sourcing for an import, this must be a shuttle step.
        return sourceViaShuttle(tradeSymbol, waypointSymbol);
      }
    }
  }
}

void source(
  MarketListingSnapshot marketListings,
  SystemsCache systemsCache,
  TradeExportCache exportCache,
  MarketPriceSnapshot marketPrices,
  TradeSymbol tradeSymbol,
  WaypointSymbol waypointSymbol,
) {
  logger.info('Sourcing $tradeSymbol for $waypointSymbol');
  final action = Sourcer(
    marketListings: marketListings,
    systemsCache: systemsCache,
    exportCache: exportCache,
    marketPrices: marketPrices,
  ).sourceGoodsFor(tradeSymbol, waypointSymbol);
  if (action == null) {
    logger.warn('No source for $tradeSymbol for $waypointSymbol');
    return;
  }
  final ctx = DescribeContext(systemsCache, marketListings, marketPrices);
  action.describe(ctx);
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final exportCache = TradeExportCache.load(fs);
  final systemsCache = SystemsCache.load(fs)!;
  final marketListings = await MarketListingSnapshot.load(db);
  final marketPrices = await MarketPriceSnapshot.load(db);
  final agent = await myAgent(db);
  final constructionCache = ConstructionCache(db);

  final jumpgate =
      systemsCache.jumpGateWaypointForSystem(agent.headquarters.system)!;
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
}

Future<void> main(List<String> args) async {
  await runOffline(args, command);
}
