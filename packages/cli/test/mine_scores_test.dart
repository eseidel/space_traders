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
    final marketListingCache = _MockMarketListingCache();
    final systemSymbol = SystemSymbol.fromString('W-A');
    when(() => waypointCache.waypointsInSystem(systemSymbol)).thenAnswer(
      (_) => Future.value([
        Waypoint(
          symbol: 'W-A-A',
          systemSymbol: 'W-A',
          type: WaypointType.ASTEROID,
          traits: [
            WaypointTrait(
              symbol: WaypointTraitSymbol.COMMON_METAL_DEPOSITS,
              name: 'name',
              description: 'description',
            ),
          ],
          x: 0,
          y: 0,
          isUnderConstruction: false,
        ),
        Waypoint(
          symbol: 'W-A-B',
          systemSymbol: 'W-A',
          type: WaypointType.ASTEROID,
          traits: [
            WaypointTrait(
              symbol: WaypointTraitSymbol.MARKETPLACE,
              name: 'name',
              description: 'description',
            ),
          ],
          x: 10,
          y: 0,
          isUnderConstruction: false,
        ),
      ]),
    );

    final scores = await evaluateWaypointsForMining(
      waypointCache,
      marketListingCache,
      systemSymbol,
    );
    expect(scores.length, 1);
    final score = scores.first;
    expect(score.score, 10);
    expect(score.mineTraitNames, ['COMMON_METAL']);
    expect(score.producedGoods, {
      TradeSymbol.IRON_ORE,
      TradeSymbol.COPPER_ORE,
      TradeSymbol.ALUMINUM_ORE,
      TradeSymbol.ICE_WATER,
      TradeSymbol.SILICON_CRYSTALS,
      TradeSymbol.QUARTZ_SAND,
    });
    expect(score.marketTradesAllProducedGoods, false);
    expect(score.goodsMissingFromMarket, {
      TradeSymbol.IRON_ORE,
      TradeSymbol.COPPER_ORE,
      TradeSymbol.ALUMINUM_ORE,
      TradeSymbol.ICE_WATER,
      TradeSymbol.SILICON_CRYSTALS,
      TradeSymbol.QUARTZ_SAND,
    });
  });

  test('evaluateWaypointsForSiphoning', () async {
    final waypointCache = _MockWaypointCache();
    final marketListingCache = _MockMarketListingCache();
    final systemSymbol = SystemSymbol.fromString('W-A');
    when(() => waypointCache.waypointsInSystem(systemSymbol)).thenAnswer(
      (_) => Future.value([
        Waypoint(
          symbol: 'W-A-A',
          systemSymbol: 'W-A',
          type: WaypointType.GAS_GIANT,
          x: 0,
          y: 0,
          isUnderConstruction: false,
        ),
        Waypoint(
          symbol: 'W-A-B',
          systemSymbol: 'W-A',
          type: WaypointType.ASTEROID,
          traits: [
            WaypointTrait(
              symbol: WaypointTraitSymbol.MARKETPLACE,
              name: 'name',
              description: 'description',
            ),
          ],
          x: 10,
          y: 0,
          isUnderConstruction: false,
        ),
      ]),
    );

    final scores = await evaluateWaypointsForSiphoning(
      waypointCache,
      marketListingCache,
      systemSymbol,
    );
    expect(scores.length, 1);
    expect(scores.first.score, 10);
  });
}
