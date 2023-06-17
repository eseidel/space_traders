import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/behavior/trader.dart';
import 'package:space_traders_cli/cache/prices.dart';
import 'package:space_traders_cli/cache/waypoint_cache.dart';
import 'package:test/test.dart';

class MockWaypointCache extends Mock implements WaypointCache {}

class MockPriceData extends Mock implements PriceData {}

void main() {
  test('DealFinder', () {
    final priceData = MockPriceData();
    final finder = DealFinder(priceData);
    final deals = finder.findDeals();
    expect(deals, isEmpty);
  });
}
