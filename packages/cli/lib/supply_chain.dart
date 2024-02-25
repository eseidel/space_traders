import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:types/types.dart';

final _minable = <TradeSymbol>{
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

final _siphonable = <TradeSymbol>{
  TradeSymbol.LIQUID_HYDROGEN,
  TradeSymbol.LIQUID_NITROGEN,
};

final _extractable = <TradeSymbol>{
  ..._minable,
  ..._siphonable,
};

/// Passed to describe when printing a supply chain.
class DescribeContext {
  /// Create a new description context.
  DescribeContext(this.systems, this.marketPrices);

  /// The systems cache.
  final SystemsCache systems;

  /// The market prices.
  final MarketPriceSnapshot marketPrices;
}

/// A supply chain node.
abstract class SupplyLink {
  /// Create a new supply link.
  SupplyLink(this.tradeSymbol);

  /// The trade symbol being supplied.
  final TradeSymbol tradeSymbol;

  /// Describe the sub-graph of the supply chain.
  void describe(DescribeContext ctx, {int indent = 0});
}

/// A supply chain node representing production
abstract class ProduceLink extends SupplyLink {
  /// Create a new production node.
  ProduceLink(super.tradeSymbol, this.waypointSymbol);

  /// The waypoint symbol where the good is produced.
  final WaypointSymbol waypointSymbol;
}

/// A supply chain node representing an extraction
class ExtractLink extends ProduceLink {
  /// Create a new extraction node.
  ExtractLink(super.tradeSymbol, super.waypointSymbol);

  @override
  void describe(DescribeContext ctx, {int indent = 0}) {
    final from = waypointSymbol.waypointName;
    final spaces = ' ' * indent;
    logger.info('${spaces}Extract $tradeSymbol from $from');
  }
}

/// A supply chain node representing a shuttle
class ShuttleLink extends SupplyLink {
  /// Create a new shuttle node.
  ShuttleLink(super.tradeSymbol, this.destination, this.source);

  /// The destination of the shuttle.
  final WaypointSymbol destination;

  // This could be a list if we wanted to support options.
  /// The source of the shuttle.
  final ProduceLink source;

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

class Manufacture extends ProduceLink {
  Manufacture(super.tradeSymbol, super.waypointSymbol, this.inputs);

  // This could map String -> List if we wanted to support options.
  final Map<TradeSymbol, ShuttleLink> inputs;

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

Set<TradeSymbol> _extractableFrom(SystemWaypoint waypoint) {
  if (waypoint.isAsteroid) {
    return _minable;
  }
  if (waypoint.type == WaypointType.GAS_GIANT) {
    return _siphonable;
  }
  return {};
}

WaypointSymbol? _nearestExtractionSiteFor(
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

MarketListing? _nearestListingWithExport(
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

/// Builds a supply chain.
class SupplyChainBuilder {
  /// Create a new supply chain builder.
  const SupplyChainBuilder(
    MarketListingSnapshot marketListings,
    SystemsCache systems,
    TradeExportCache exports,
  )   : _marketListings = marketListings,
        _systems = systems,
        _exports = exports;

  final MarketListingSnapshot _marketListings;
  final SystemsCache _systems;
  final TradeExportCache _exports;

  ProduceLink? _shuttleSource(
    TradeSymbol tradeSymbol,
    WaypointSymbol waypointSymbol,
  ) {
    // No need to manufacture if we can extract.
    if (_extractable.contains(tradeSymbol)) {
      // Find the nearest extraction location?
      final location = _nearestExtractionSiteFor(
        _systems,
        tradeSymbol,
        waypointSymbol,
      );
      if (location == null) {
        logger.warn('No extraction site for $tradeSymbol for $waypointSymbol');
        return null;
      }
      return ExtractLink(tradeSymbol, location);
    }

    // Look for the nearest export of the good.
    final closest = _nearestListingWithExport(
      _systems,
      _marketListings,
      tradeSymbol,
      waypointSymbol,
    );
    if (closest == null) {
      logger.warn('No export for $tradeSymbol for $waypointSymbol');
      return null;
    }
    return _sourceViaManufacture(tradeSymbol, closest.waypointSymbol);
  }

  ShuttleLink? _sourceViaShuttle(
    TradeSymbol tradeSymbol,
    WaypointSymbol waypointSymbol,
  ) {
    final source = _shuttleSource(tradeSymbol, waypointSymbol);
    if (source == null) {
      return null;
    }
    return ShuttleLink(tradeSymbol, waypointSymbol, source);
  }

  Manufacture? _sourceViaManufacture(
    TradeSymbol tradeSymbol,
    WaypointSymbol waypointSymbol,
  ) {
    final listing = _marketListings[waypointSymbol];
    if (listing == null) {
      throw ArgumentError('No market listing for $waypointSymbol');
    }
    final imports = _exports[tradeSymbol]!.imports;
    final inputs = <TradeSymbol, ShuttleLink>{};
    for (final import in imports) {
      final source = _sourceViaShuttle(import, waypointSymbol);
      if (source == null) {
        return null;
      }
      inputs[import] = source;
    }
    return Manufacture(tradeSymbol, waypointSymbol, inputs);
  }

  /// Build a supply chain to source a good for a waypoint.
  SupplyLink? buildChainTo(
    TradeSymbol tradeSymbol,
    WaypointSymbol waypointSymbol, {
    int indent = 0,
  }) {
    final listing = _marketListings[waypointSymbol];
    // If the end isn't a market this must be a shuttle step.
    if (listing == null) {
      return _sourceViaShuttle(tradeSymbol, waypointSymbol);
    } else {
      // If we're sourcing for an export, this must be a manufacture step.
      if (listing.exports.contains(tradeSymbol)) {
        return _sourceViaManufacture(tradeSymbol, waypointSymbol);
      } else {
        // If we're sourcing for an import, this must be a shuttle step.
        return _sourceViaShuttle(tradeSymbol, waypointSymbol);
      }
    }
  }
}
