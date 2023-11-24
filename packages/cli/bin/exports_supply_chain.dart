import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:meta/meta.dart';

@immutable
class MarketNeed {
  const MarketNeed(this.tradeSymbol, this.marketSymbol);

  final TradeSymbol tradeSymbol;
  final WaypointSymbol marketSymbol;
}

// abstract class SupplySource {
//   const SupplySource(this.tradeSymbol);

//   final TradeSymbol tradeSymbol;

//   WaypointSymbol get endSymbol;
//   WaypointSymbol get startSymbol;
// }

// class Manufacture extends SupplySource {
//   const Manufacture(super.tradeSymbol, this.imports);
//   final List<TradeSymbol> imports;
// }

// class Shuttle extends SupplySource {
//   const Shuttle(super.tradeSymbol, this.marketSymbol);

//   final WaypointSymbol marketSymbol;
// }

// class SupplyLink {
//   const SupplyLink(this.source);

//   final TradeSymbol tradeSymbol;
//   final WaypointSymbol marketSymbol;

//   SupplySource source;
// }

// A supply chain is built from various links.
// When you want to get FAB_MATS for the jump gate, you'd need:
// Place to buy FAB_MATS
// Need links for each of the imports needed to produce that fab mat?
// Place to buy each import.
// Links to produce each import.
// Place to buy each import's import.

final extractable = {
  TradeSymbol.IRON_ORE,
};

class Sourcer {
  const Sourcer({
    required this.marketListings,
    required this.systemsCache,
    required this.staticCaches,
  });

  final MarketListingCache marketListings;
  final SystemsCache systemsCache;
  final StaticCaches staticCaches;

// Goal is to print this:
// FAB_MATS for X
// Shuttle FAB_MATS from Y to X
// Manufacture FAB_MATS at X from A, B, C
// Shuttle A from Z to X

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
    final listings = marketListings.listings
        // Listings in this same system which export the good.
        .where(
          (entry) =>
              entry.waypointSymbol.systemSymbol ==
                  waypointSymbol.systemSymbol &&
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
    final closest = listings.firstOrNull;
    if (closest == null) {
      logger.warn('No export for $tradeSymbol for $waypointSymbol');
      return;
    }
    logger.info('Shuttle $tradeSymbol from '
        '${closest.waypointSymbol} to ${destination.waypointSymbol}');
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
  // final marketPrices = MarketPrices.load(fs);
  // final constructionCache = ConstructionCache.load(fs);
  final agentCache = AgentCache.load(fs)!;

  final jumpgate = systemsCache
      .jumpGateWaypointForSystem(agentCache.headquartersSystemSymbol)!;
  // final construction =
  //     constructionCache.constructionForSymbol(jumpgate.waypointSymbol);
  const tradeSymbol = TradeSymbol.FAB_MATS;

  final waypointSymbol = jumpgate.waypointSymbol;
  logger.info('$tradeSymbol for $waypointSymbol');
  Sourcer(
    marketListings: marketListings,
    systemsCache: systemsCache,
    staticCaches: staticCaches,
  ).sourceGoodsFor(tradeSymbol, waypointSymbol);

  // final need = MarketNeed(export, listing.waypointSymbol);
  // // Look up what trade symbols are required to produce the export.
  // final tradeSymbols = staticCaches.exports[export]!.imports;
  // final waypointSymbol = listing.waypointSymbol;
  // Find the nearest market that has the needed import?

  // Where each import needs at least one deal?
  // How do you handle chains?  Maybe you just assume the closest market
  // for each?
}

void main(List<String> args) async {
  await runOffline(args, command);
}
