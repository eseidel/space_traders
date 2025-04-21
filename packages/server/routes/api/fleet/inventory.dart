import 'package:cli/caches.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:db/db.dart';
import 'package:protocol/protocol.dart';
import 'package:server/read_async.dart';
import 'package:types/types.dart';

Future<GetFleetInventoryResponse> computeInventoryValue({
  required Database db,
}) async {
  final ships = await ShipSnapshot.load(db);
  final marketPrices = await MarketPriceSnapshot.loadAll(db);
  final countByTradeSymbol = <TradeSymbol, int>{};
  for (final ship in ships.ships) {
    final inventory = ship.cargo.inventory;
    for (final item in inventory) {
      final symbol = item.tradeSymbol;
      final count = countByTradeSymbol[symbol] ?? 0;
      countByTradeSymbol[symbol] = count + item.units;
    }
  }
  final items = countByTradeSymbol.entries.map((entry) {
    final symbol = entry.key;
    final count = entry.value;
    return ItemValue(
      tradeSymbol: symbol,
      count: count,
      medianPrice: marketPrices.medianSellPrice(symbol),
    );
  });
  return GetFleetInventoryResponse(items: items.toList());
}

Future<Response> onRequest(RequestContext context) async {
  final db = await context.readAsync<Database>();
  final inventory = await computeInventoryValue(db: db);
  return Response.json(
    body: inventory.toJson(),
    headers: {'Cache-Control': 'no-store', 'Content-Type': 'application/json'},
  );
}
