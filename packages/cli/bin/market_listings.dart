import 'package:cli/cli.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli_table/cli_table.dart';

Map<String, dynamic> rightAlign(Object? content) => <String, dynamic>{
  'content': content.toString(),
  'hAlign': HorizontalAlign.right,
};

void addSymbols(
  Table table,
  String category,
  Set<TradeSymbol> tradeSymbols,
  WaypointSymbol marketSymbol,
  MarketPriceSnapshot marketPrices,
) {
  if (tradeSymbols.isEmpty) {
    return;
  }

  var haveAddedHeader = false;
  for (final tradeSymbol in tradeSymbols) {
    final price = marketPrices.priceAt(marketSymbol, tradeSymbol);
    if (price == null) {
      table.add([tradeSymbol.toString()]);
    } else {
      table.add([
        if (!haveAddedHeader)
          {
            'rowSpan': tradeSymbols.length,
            'content': category,
            'vAlign': VerticalAlign.center,
          },
        tradeSymbol.toString(),
        price.supply.toString(),
        rightAlign(price.tradeVolume),
        rightAlign(price.activity),
        rightAlign(price.purchasePrice),
        rightAlign(
          stringForPriceDeviance(
            price.tradeSymbol,
            price: price.purchasePrice,
            median: marketPrices.medianPurchasePrice(price.tradeSymbol),
            MarketTransactionType.PURCHASE,
          ),
        ),
        rightAlign(price.sellPrice),
        rightAlign(
          stringForPriceDeviance(
            price.tradeSymbol,
            price: price.sellPrice,
            median: marketPrices.medianSellPrice(price.tradeSymbol),
            MarketTransactionType.SELL,
          ),
        ),
      ]);
      haveAddedHeader = true;
    }
  }
}

Future<void> command(Database db, ArgResults argResults) async {
  final systemsCache = await db.systems.snapshotAllSystems();
  final hqSystem = await myHqSystemSymbol(db);
  final marketListings = await db.marketListings.snapshotAll();

  final waypoints = systemsCache.waypointsInSystem(hqSystem);
  final marketPrices = await db.marketPrices.snapshotInSystem(hqSystem);

  for (final waypoint in waypoints) {
    final marketSymbol = waypoint.symbol;

    // Adding a price to MarketPrices updates our listing, so if we don't
    // have a listing we won't have a price.
    final listing = marketListings[marketSymbol];
    if (listing == null) {
      continue;
    }

    final table = Table(
      header: [
        marketSymbol.sectorLocalName,
        'symbol',
        'supply',
        'volume',
        'activity',
        'buy',
        'buy diff',
        'sell',
        'sell diff',
      ],
    );

    addSymbols(table, 'imports', listing.imports, marketSymbol, marketPrices);
    addSymbols(table, 'exports', listing.exports, marketSymbol, marketPrices);
    addSymbols(table, 'exchange', listing.exchange, marketSymbol, marketPrices);
    logger.info(table.toString());
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
