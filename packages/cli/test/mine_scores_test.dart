import 'package:cli/cache/market_cache.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/mine_scores.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockWaypointCache extends Mock implements WaypointCache {}

class _MockMarketListingCache extends Mock implements MarketListingCache {}

void main() {
  test('evaluateWaypointsForMining', () async {
    final waypointCache = _MockWaypointCache();
    final marketLisingCache = _MockMarketListingCache();
    final systemSymbol = SystemSymbol.fromString('W-A');
    when(() => waypointCache.waypointsInSystem(systemSymbol))
        .thenAnswer((_) => Future.value(<Waypoint>[]));

    final waypoints = await evaluateWaypointsForMining(
      waypointCache,
      marketLisingCache,
      systemSymbol,
    );
    expect(waypoints, isEmpty);
  });

  test('evaluateWaypointsForSiphoning', () async {
    final waypointCache = _MockWaypointCache();
    final marketLisingCache = _MockMarketListingCache();
    final systemSymbol = SystemSymbol.fromString('W-A');
    when(() => waypointCache.waypointsInSystem(systemSymbol))
        .thenAnswer((_) => Future.value(<Waypoint>[]));

    final waypoints = await evaluateWaypointsForSiphoning(
      waypointCache,
      marketLisingCache,
      systemSymbol,
    );
    expect(waypoints, isEmpty);
  });
}
