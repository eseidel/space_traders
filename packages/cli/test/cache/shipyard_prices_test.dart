import 'package:cli/cache/shipyard_prices.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('ShipyardPrices.hasRecentShipyardData', () {
    final shipyardPrices = ShipyardPrices([]);
    final symbol = WaypointSymbol.fromString('S-A-W');
    expect(shipyardPrices.hasRecentData(symbol), false);
    final now = DateTime(2021);
    DateTime getNow() => now;
    expect(
      shipyardPrices.recentPurchasePrice(
        shipyardSymbol: symbol,
        shipType: ShipType.EXPLORER,
        maxAge: const Duration(minutes: 1),
        getNow: getNow,
      ),
      isNull,
    );
  });
}
