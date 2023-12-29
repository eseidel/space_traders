import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cache/market_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/extraction_score.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockWaypointCache extends Mock implements WaypointCache {}

class _MockMarketListingCache extends Mock implements MarketListingCache {}

class _MockChartingCache extends Mock implements ChartingCache {}

void main() {
  test('evaluateWaypointsForMining', () async {
    final systemsCache = _MockSystemsCache();
    final waypointCache = _MockWaypointCache();
    final chartingCache = _MockChartingCache();
    final marketListingCache = _MockMarketListingCache();
    final systemSymbol = SystemSymbol.fromString('W-A');
    final sourceSymbol = WaypointSymbol.fromString('W-A-A');
    final source = Waypoint.test(
      sourceSymbol,
      traits: [
        WaypointTrait(
          symbol: WaypointTraitSymbol.COMMON_METAL_DEPOSITS,
          name: 'name',
          description: 'description',
        ),
      ],
    );
    final marketASymbol = WaypointSymbol.fromString('W-A-M');
    final marketA = Waypoint.test(
      marketASymbol,
      traits: [
        WaypointTrait(
          symbol: WaypointTraitSymbol.MARKETPLACE,
          name: 'name',
          description: 'description',
        ),
      ],
      position: WaypointPosition(10, 0, systemSymbol),
    );
    final marketBSymbol = WaypointSymbol.fromString('W-A-N');
    final marketB = Waypoint.test(
      marketBSymbol,
      traits: [
        WaypointTrait(
          symbol: WaypointTraitSymbol.MARKETPLACE,
          name: 'name',
          description: 'description',
        ),
      ],
      position: WaypointPosition(0, 20, systemSymbol),
    );
    final waypoints = [source, marketA, marketB];
    when(() => waypointCache.waypointsInSystem(systemSymbol)).thenAnswer(
      (_) => Future.value(waypoints),
    );
    when(() => systemsCache.waypointsInSystem(systemSymbol))
        .thenReturn(waypoints.map((e) => e.toSystemWaypoint()).toList());
    when(() => systemsCache.waypoint(source.symbol))
        .thenReturn(source.toSystemWaypoint());
    when(() => systemsCache.waypoint(marketA.symbol))
        .thenReturn(marketA.toSystemWaypoint());
    when(() => systemsCache.waypoint(marketB.symbol))
        .thenReturn(marketB.toSystemWaypoint());
    final producedGoods = {
      TradeSymbol.IRON_ORE,
      TradeSymbol.COPPER_ORE,
      TradeSymbol.ALUMINUM_ORE,
      TradeSymbol.ICE_WATER,
      TradeSymbol.SILICON_CRYSTALS,
      TradeSymbol.QUARTZ_SAND,
    };
    when(() => marketListingCache[marketA.symbol]).thenReturn(
      MarketListing(
        waypointSymbol: marketA.symbol,
        imports: const {
          TradeSymbol.IRON_ORE,
          TradeSymbol.COPPER_ORE,
          TradeSymbol.ALUMINUM_ORE,
        },
      ),
    );
    when(() => marketListingCache[marketB.symbol]).thenReturn(
      MarketListing(
        waypointSymbol: marketB.symbol,
        imports: const {
          TradeSymbol.ICE_WATER,
          TradeSymbol.SILICON_CRYSTALS,
          TradeSymbol.QUARTZ_SAND,
        },
      ),
    );

    final scores = await evaluateWaypointsForMining(
      systemsCache,
      chartingCache,
      marketListingCache,
      systemSymbol,
    );
    expect(scores.length, 1);
    final score = scores.first;
    expect(score.score, 53);
    expect(score.displayTraitNames, ['COMMON_METAL']);
    expect(score.producedGoods, producedGoods);
  });

  test('evaluateWaypointsForSiphoning', () async {
    final systemsCache = _MockSystemsCache();
    final waypointCache = _MockWaypointCache();
    final chartingCache = _MockChartingCache();
    final marketListingCache = _MockMarketListingCache();
    final sourceSymbol = WaypointSymbol.fromString('W-A-A');
    final systemSymbol = SystemSymbol.fromString('W-A');
    final source = Waypoint.test(
      sourceSymbol,
      type: WaypointType.GAS_GIANT,
    );
    final marketSymbol = WaypointSymbol.fromString('W-A-B');
    final market = Waypoint.test(
      marketSymbol,
      traits: [
        WaypointTrait(
          symbol: WaypointTraitSymbol.MARKETPLACE,
          name: 'name',
          description: 'description',
        ),
      ],
      position: WaypointPosition(10, 0, systemSymbol),
    );
    final waypoints = [source, market];
    when(() => waypointCache.waypointsInSystem(systemSymbol)).thenAnswer(
      (_) => Future.value(waypoints),
    );
    when(() => systemsCache.waypointsInSystem(systemSymbol))
        .thenReturn(waypoints.map((e) => e.toSystemWaypoint()).toList());
    when(() => systemsCache.waypoint(source.symbol))
        .thenReturn(source.toSystemWaypoint());
    when(() => systemsCache.waypoint(market.symbol))
        .thenReturn(market.toSystemWaypoint());

    final producedGoods = {
      TradeSymbol.HYDROCARBON,
      TradeSymbol.LIQUID_HYDROGEN,
      TradeSymbol.LIQUID_NITROGEN,
    };
    when(() => marketListingCache[market.symbol]).thenReturn(
      MarketListing(
        waypointSymbol: market.symbol,
        imports: producedGoods,
      ),
    );

    final scores = await evaluateWaypointsForSiphoning(
      systemsCache,
      chartingCache,
      marketListingCache,
      systemSymbol,
    );
    expect(scores.length, 1);
    expect(scores.first.score, 20);
    expect(scores.first.producedGoods, producedGoods);
    expect(scores.first.goodsMissingFromMarkets, <TradeSymbol>{});
  });
}
