import 'package:cli/cli.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli_table/cli_table.dart';

Map<String, dynamic> rightAlign(Object? content) => <String, dynamic>{
  'content': content.toString(),
  'hAlign': HorizontalAlign.right,
};

// Returns the distance between two waypoints, or null if they are in different
// systems.
int? distanceBetween(
  SystemsSnapshot systemsCache,
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

Future<void> command(Database db, ArgResults argResults) async {
  final systemsCache = await db.systems.snapshotAllSystems();
  final hqSystem = await myHqSystemSymbol(db);
  final marketPrices = await db.marketPrices.snapshotInSystem(hqSystem);
  final marketListings = await db.marketListings.snapshotSystem(hqSystem);

  // Collect all imports and exports.
  final exports = <TradeSymbol, WaypointSymbol>{};
  final imports = <TradeSymbol, WaypointSymbol>{};
  for (final listing in marketListings.listings) {
    // This is wrong because the last waypoint "wins", even if we have multiple.
    for (final export in listing.exports) {
      exports[export] = listing.waypointSymbol;
    }
    for (final import in listing.imports) {
      imports[import] = listing.waypointSymbol;
    }
  }

  final table = Table(
    header: [
      'symbol',
      'export',
      'vol',
      'supply',
      'activity',
      'price',
      'deviance',
      'import',
      'vol',
      'supply',
      'activity',
      'imp price',
      'deviance',
      'distance',
      'spread',
    ],
  );

  for (final tradeSymbol in exports.keys) {
    final exportWaypoint = exports[tradeSymbol]!;
    final importWaypoint = imports[tradeSymbol];
    if (importWaypoint == null) {
      logger.warn('No import for $tradeSymbol');
      // table.add([
      //   tradeSymbol.toString(),
      //   exportWaypoint.sectorLocalName,
      // ]);
      continue;
    }
    final distance = distanceBetween(
      systemsCache,
      exportWaypoint,
      importWaypoint,
    )!;
    String deviance(int price, MarketTransactionType type) {
      final median = marketPrices.medianPrice(tradeSymbol, type);
      final deviance = stringForPriceDeviance(
        tradeSymbol,
        price: price,
        median: median,
        type,
      );
      // table_cli doesn't correctly handle emojis.
      if (deviance.contains('⚖️')) {
        return '-';
      }
      return deviance;
    }

    final exportPrice = marketPrices.priceAt(exportWaypoint, tradeSymbol)!;
    final importPrice = marketPrices.priceAt(importWaypoint, tradeSymbol)!;
    final spread = importPrice.sellPrice - exportPrice.purchasePrice;
    table.add([
      tradeSymbol.toString(),
      exportWaypoint.sectorLocalName,
      rightAlign(exportPrice.tradeVolume),
      rightAlign(exportPrice.supply),
      rightAlign(exportPrice.activity),
      rightAlign(creditsString(exportPrice.purchasePrice)),
      rightAlign(
        deviance(exportPrice.purchasePrice, MarketTransactionType.PURCHASE),
      ),
      importWaypoint.sectorLocalName,
      rightAlign(importPrice.tradeVolume),
      rightAlign(importPrice.supply),
      rightAlign(importPrice.activity),
      rightAlign(creditsString(importPrice.sellPrice)),
      rightAlign(deviance(importPrice.sellPrice, MarketTransactionType.SELL)),
      distance,
      creditsString(spread),
    ]);
  }
  logger.info(table.toString());
}

void main(List<String> args) async {
  await runOffline(args, command);
}
