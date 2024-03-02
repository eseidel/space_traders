import 'package:cli/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/plan/extraction_score.dart';
import 'package:collection/collection.dart';
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

/// A visitor for supply chain nodes.
abstract class SupplyLinkVisitor {
  /// Visit an extraction node.
  Future<void> visitExtract(ExtractLink link, {required int depth}) async {}

  /// Visit a shuttle node.
  Future<void> visitShuttle(ShuttleLink link, {required int depth}) async {}

  /// Visit a manufacture node.
  Future<void> visitManufacture(
    ManufactureLink link, {
    required int depth,
  }) async {}
}

/// A supply chain node.
abstract class SupplyLink {
  /// Create a new supply link.
  SupplyLink(this.tradeSymbol);

  /// The trade symbol being supplied.
  final TradeSymbol tradeSymbol;

  /// The end waypointSymbol for this link.
  WaypointSymbol get waypointSymbol;

  /// Does a depth first walk with pre-order traversal.
  Future<void> accept(SupplyLinkVisitor visitor, {int depth = 0});
}

/// A supply chain node representing production
abstract class ProduceLink extends SupplyLink {
  /// Create a new production node.
  ProduceLink(super.tradeSymbol, this.waypointSymbol);

  /// The waypoint symbol where the good is produced.
  @override
  final WaypointSymbol waypointSymbol;
}

/// A supply chain node representing an extraction
class ExtractLink extends ProduceLink {
  /// Create a new extraction node.
  ExtractLink(super.tradeSymbol, super.waypointSymbol);

  @override
  Future<void> accept(SupplyLinkVisitor visitor, {int depth = 0}) async {
    await visitor.visitExtract(this, depth: depth);
  }
}

/// A supply chain node representing a shuttle
class ShuttleLink extends SupplyLink {
  /// Create a new shuttle node.
  ShuttleLink(super.tradeSymbol, this.destination, this.source);

  /// The destination of the shuttle.
  final WaypointSymbol destination;

  @override
  WaypointSymbol get waypointSymbol => destination;

  // This could be a list if we wanted to support options.
  /// The source of the shuttle.
  final ProduceLink source;

  @override
  Future<void> accept(SupplyLinkVisitor visitor, {int depth = 0}) async {
    await visitor.visitShuttle(this, depth: depth);
    await source.accept(visitor, depth: depth + 1);
  }
}

/// A supply chain node representing a manufacture
class ManufactureLink extends ProduceLink {
  /// Create a new manufacture node.
  ManufactureLink(super.tradeSymbol, super.waypointSymbol, this.inputs);

  // This could map String -> List if we wanted to support options.
  /// The inputs to the manufacture.
  final Map<TradeSymbol, ShuttleLink> inputs;

  @override
  Future<void> accept(SupplyLinkVisitor visitor, {int depth = 0}) async {
    await visitor.visitManufacture(this, depth: depth);
    for (final input in inputs.values) {
      await input.accept(visitor, depth: depth + 1);
    }
  }
}

bool? _hasExtractableGood(
  ChartingSnapshot chartingSnapshot,
  SystemWaypoint waypoint,
  TradeSymbol tradeSymbol,
) {
  final chartedValues = chartingSnapshot[waypoint.symbol]?.values;
  if (chartedValues == null) {
    return null;
  }
  return extractableGoodsAt(waypoint.type, chartedValues.traitSymbols)
      .contains(tradeSymbol);
}

WaypointSymbol? _nearestExtractionSiteFor(
  SystemsCache systemsCache,
  ChartingSnapshot chartingSnapshot,
  TradeSymbol tradeSymbol,
  WaypointSymbol waypointSymbol,
) {
  final destination = systemsCache.waypoint(waypointSymbol);
  final candidates = systemsCache
      .waypointsInSystem(waypointSymbol.system)
      .where(
        (waypoint) => _hasExtractableGood(
          chartingSnapshot,
          waypoint,
          tradeSymbol,
        )!,
      )
      .sortedBy<num>((w) => w.distanceTo(destination));
  return candidates.firstOrNull?.symbol;
}

MarketListing? _nearestListingWithExport(
  SystemsCache systemsCache,
  MarketListingSnapshot marketListings,
  TradeSymbol tradeSymbol,
  WaypointSymbol waypointSymbol,
) {
  final destination = systemsCache.waypoint(waypointSymbol);
  final sortedListings = marketListings.listings
      // Listings in this same system which export the good.
      .where(
        (entry) =>
            entry.waypointSymbol.system == waypointSymbol.system &&
            entry.exports.contains(tradeSymbol),
      )
      .sortedBy<num>(
        (l) => systemsCache.waypoint(l.waypointSymbol).distanceTo(destination),
      );
  return sortedListings.firstOrNull;
}

/// Builds a supply chain.
class SupplyChainBuilder {
  /// Create a new supply chain builder.
  const SupplyChainBuilder({
    required SystemsCache systems,
    required MarketListingSnapshot marketListings,
    required TradeExportCache exports,
    required ChartingSnapshot charting,
  })  : _marketListings = marketListings,
        _systems = systems,
        _exports = exports,
        _charting = charting;

  final MarketListingSnapshot _marketListings;
  final SystemsCache _systems;
  final TradeExportCache _exports;
  final ChartingSnapshot _charting;

  ProduceLink? _shuttleSource(
    TradeSymbol tradeSymbol,
    WaypointSymbol waypointSymbol,
  ) {
    // No need to manufacture if we can extract.
    if (_extractable.contains(tradeSymbol)) {
      // Find the nearest extraction location?
      final location = _nearestExtractionSiteFor(
        _systems,
        _charting,
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

  ManufactureLink? _sourceViaManufacture(
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
    return ManufactureLink(tradeSymbol, waypointSymbol, inputs);
  }

  /// Build a supply chain to source a good for a waypoint.
  SupplyLink? buildChainTo(
    TradeSymbol tradeSymbol,
    WaypointSymbol waypointSymbol,
  ) {
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
