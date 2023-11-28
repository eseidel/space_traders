import 'package:cli/cache/market_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/mine_scores.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockWaypointCache extends Mock implements WaypointCache {}

class _MockMarketListingCache extends Mock implements MarketListingCache {}

void main() {
  test('evaluateWaypointsForMining', () async {
    final systemsCache = _MockSystemsCache();
    final waypointCache = _MockWaypointCache();
    final marketListingCache = _MockMarketListingCache();
    final systemSymbol = SystemSymbol.fromString('W-A');
    final source = Waypoint(
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
    );
    final marketA = Waypoint(
      symbol: 'W-A-M',
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
    );
    final marketB = Waypoint(
      symbol: 'W-A-N',
      systemSymbol: 'W-A',
      type: WaypointType.ASTEROID,
      traits: [
        WaypointTrait(
          symbol: WaypointTraitSymbol.MARKETPLACE,
          name: 'name',
          description: 'description',
        ),
      ],
      x: 0,
      y: 20,
      isUnderConstruction: false,
    );
    final waypoints = [source, marketA, marketB];
    when(() => waypointCache.waypointsInSystem(systemSymbol)).thenAnswer(
      (_) => Future.value(waypoints),
    );
    when(() => systemsCache.waypointsInSystem(systemSymbol))
        .thenReturn(waypoints.map((e) => e.toSystemWaypoint()).toList());
    when(() => systemsCache.waypoint(source.waypointSymbol))
        .thenReturn(source.toSystemWaypoint());
    when(() => systemsCache.waypoint(marketA.waypointSymbol))
        .thenReturn(marketA.toSystemWaypoint());
    when(() => systemsCache.waypoint(marketB.waypointSymbol))
        .thenReturn(marketB.toSystemWaypoint());
    final producedGoods = {
      TradeSymbol.IRON_ORE,
      TradeSymbol.COPPER_ORE,
      TradeSymbol.ALUMINUM_ORE,
      TradeSymbol.ICE_WATER,
      TradeSymbol.SILICON_CRYSTALS,
      TradeSymbol.QUARTZ_SAND,
    };
    when(() => marketListingCache[marketA.waypointSymbol]).thenReturn(
      MarketListing(
        waypointSymbol: marketA.waypointSymbol,
        imports: const {
          TradeSymbol.IRON_ORE,
          TradeSymbol.COPPER_ORE,
          TradeSymbol.ALUMINUM_ORE,
        },
      ),
    );
    when(() => marketListingCache[marketB.waypointSymbol]).thenReturn(
      MarketListing(
        waypointSymbol: marketB.waypointSymbol,
        imports: const {
          TradeSymbol.ICE_WATER,
          TradeSymbol.SILICON_CRYSTALS,
          TradeSymbol.QUARTZ_SAND,
        },
      ),
    );

    final scores = await evaluateWaypointsForMining(
      waypointCache,
      systemsCache,
      marketListingCache,
      systemSymbol,
    );
    expect(scores.length, 1);
    final score = scores.first;
    expect(score.score, 53);
    expect(score.mineTraitNames, ['COMMON_METAL']);
    expect(score.producedGoods, producedGoods);
  });

  test('evaluateWaypointsForSiphoning', () async {
    final systemsCache = _MockSystemsCache();
    final waypointCache = _MockWaypointCache();
    final marketListingCache = _MockMarketListingCache();
    final systemSymbol = SystemSymbol.fromString('W-A');
    final source = Waypoint(
      symbol: 'W-A-A',
      systemSymbol: 'W-A',
      type: WaypointType.GAS_GIANT,
      x: 0,
      y: 0,
      isUnderConstruction: false,
    );
    final market = Waypoint(
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
    );
    final waypoints = [source, market];
    when(() => waypointCache.waypointsInSystem(systemSymbol)).thenAnswer(
      (_) => Future.value(waypoints),
    );
    when(() => systemsCache.waypointsInSystem(systemSymbol))
        .thenReturn(waypoints.map((e) => e.toSystemWaypoint()).toList());
    when(() => systemsCache.waypoint(source.waypointSymbol))
        .thenReturn(source.toSystemWaypoint());
    when(() => systemsCache.waypoint(market.waypointSymbol))
        .thenReturn(market.toSystemWaypoint());

    final producedGoods = {
      TradeSymbol.HYDROCARBON,
      TradeSymbol.LIQUID_HYDROGEN,
      TradeSymbol.LIQUID_NITROGEN,
    };
    when(() => marketListingCache[market.waypointSymbol]).thenReturn(
      MarketListing(
        waypointSymbol: market.waypointSymbol,
        imports: producedGoods,
      ),
    );

    final scores = await evaluateWaypointsForSiphoning(
      waypointCache,
      systemsCache,
      marketListingCache,
      systemSymbol,
    );
    expect(scores.length, 1);
    expect(scores.first.score, 20);
    expect(scores.first.producedGoods, producedGoods);
    expect(scores.first.goodsMissingFromMarkets, <TradeSymbol>{});
  });
}
