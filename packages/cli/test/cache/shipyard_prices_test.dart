import 'package:cli/api.dart';
import 'package:cli/cache/shipyard_prices.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  test('ShipyardPrice JSON roundtrip', () {
    final moonLanding = DateTime.utc(1969, 7, 20, 20, 18, 04);
    final price = ShipyardPrice(
      waypointSymbol: 'A',
      shipType: ShipType.EXPLORER,
      purchasePrice: 1,
      timestamp: moonLanding,
    );
    final json = price.toJson();
    final price2 = ShipyardPrice.fromJson(json);
    final json2 = price2.toJson();
    expect(price2, price);
    expect(json2, json);
  });

  test('ShipyardPrices load/save roundtrip', () async {
    final fs = MemoryFileSystem();
    final shipyardPrices = ShipyardPrices([], fs: fs);
    final moonLanding = DateTime.utc(1969, 7, 20, 20, 18, 04);
    final a = ShipyardPrice(
      waypointSymbol: 'A',
      shipType: ShipType.EXPLORER,
      purchasePrice: 1,
      timestamp: moonLanding,
    );
    final b = ShipyardPrice(
      waypointSymbol: 'B',
      shipType: ShipType.EXPLORER,
      purchasePrice: 2,
      timestamp: moonLanding,
    );
    await shipyardPrices.addPrices([a, b]);
    expect(shipyardPrices.prices, [a, b]);
    await shipyardPrices.save();
    final shipyardPrices2 = ShipyardPrices.load(fs);
    expect(shipyardPrices2.prices, [a, b]);
  });

  test('ShipyardPrices.hasRecentShipyardData', () {
    final fs = MemoryFileSystem();
    final shipyardPrices = ShipyardPrices([], fs: fs);
    expect(shipyardPrices.hasRecentShipyardData('A'), false);
    final oneMinuteAgo = DateTime.now().subtract(const Duration(minutes: 1));
    expect(
      shipyardPrices.recentPurchasePrice(
        shipyardSymbol: 'A',
        shipType: ShipType.EXPLORER,
        maxAge: const Duration(minutes: 1),
      ),
      isNull,
    );
    final a = ShipyardPrice(
      waypointSymbol: 'A',
      shipType: ShipType.EXPLORER,
      purchasePrice: 1,
      timestamp: oneMinuteAgo,
    );
    shipyardPrices.addPrices([a]);
    expect(shipyardPrices.hasRecentShipyardData('A'), true);
    expect(
      shipyardPrices.recentPurchasePrice(
        shipyardSymbol: 'A',
        shipType: ShipType.EXPLORER,
        maxAge: const Duration(minutes: 1),
      ),
      1,
    );
    expect(
      shipyardPrices.hasRecentShipyardData(
        'A',
        maxAge: const Duration(seconds: 1),
      ),
      false,
    );
    expect(
      shipyardPrices.hasRecentShipyardData(
        'A',
        maxAge: const Duration(hours: 1),
      ),
      true,
    );
  });
}
