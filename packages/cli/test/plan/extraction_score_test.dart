import 'package:cli/plan/extraction_score.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockChartingStore extends Mock implements ChartingStore {}

class _MockDatabase extends Mock implements Database {}

class _MockMarketListingStore extends Mock implements MarketListingStore {}

void main() {
  test('evaluateWaypointsForMining', () async {
    final db = _MockDatabase();

    final marketListingStore = _MockMarketListingStore();
    when(() => db.marketListings).thenReturn(marketListingStore);

    final systemSymbol = SystemSymbol.fromString('W-A');
    final sourceSymbol = WaypointSymbol.fromString('W-A-A');
    final source = SystemWaypoint.test(sourceSymbol);
    final marketASymbol = WaypointSymbol.fromString('W-A-M');
    final marketA = SystemWaypoint.test(
      marketASymbol,
      position: WaypointPosition(10, 0, systemSymbol),
    );
    final marketBSymbol = WaypointSymbol.fromString('W-A-N');
    final marketB = SystemWaypoint.test(
      marketBSymbol,
      position: WaypointPosition(0, 20, systemSymbol),
    );
    final waypoints = [source, marketA, marketB];
    final systems = [System.test(systemSymbol, waypoints: waypoints)];
    final systemsSnapshot = SystemsSnapshot(systems);
    final producedGoods = {
      TradeSymbol.IRON_ORE,
      TradeSymbol.COPPER_ORE,
      TradeSymbol.ALUMINUM_ORE,
      TradeSymbol.ICE_WATER,
      TradeSymbol.SILICON_CRYSTALS,
      TradeSymbol.QUARTZ_SAND,
    };
    const aImports = {
      TradeSymbol.IRON_ORE,
      TradeSymbol.COPPER_ORE,
      TradeSymbol.ALUMINUM_ORE,
    };
    for (final good in aImports) {
      when(
        () => marketListingStore.marketsWithImportInSystem(systemSymbol, good),
      ).thenAnswer((_) async => [marketA.symbol]);
    }
    const bImports = {
      TradeSymbol.ICE_WATER,
      TradeSymbol.SILICON_CRYSTALS,
      TradeSymbol.QUARTZ_SAND,
    };
    for (final good in bImports) {
      when(
        () => marketListingStore.marketsWithImportInSystem(systemSymbol, good),
      ).thenAnswer((_) async => [marketB.symbol]);
    }
    final chartingStore = _MockChartingStore();
    when(() => db.charting).thenReturn(chartingStore);

    when(() => chartingStore.chartedValues(sourceSymbol)).thenAnswer(
      (_) async => ChartedValues.test(
        traitSymbols: const {WaypointTraitSymbol.COMMON_METAL_DEPOSITS},
      ),
    );
    when(
      () => chartingStore.chartedValues(marketASymbol),
    ).thenAnswer((_) async => ChartedValues.test());
    when(
      () => chartingStore.chartedValues(marketBSymbol),
    ).thenAnswer((_) async => ChartedValues.test());

    final scores = await evaluateWaypointsForMining(
      db,
      systemsSnapshot,

      systemSymbol,
    );
    expect(scores.length, 1);
    final score = scores.first;
    expect(score.score, 53);
    expect(score.displayTraitNames, ['COMMON_METAL']);
    expect(score.producedGoods, producedGoods);
  });

  test('evaluateWaypointsForSiphoning', () async {
    final db = _MockDatabase();

    final marketListingStore = _MockMarketListingStore();
    when(() => db.marketListings).thenReturn(marketListingStore);

    final sourceSymbol = WaypointSymbol.fromString('W-A-A');
    final systemSymbol = SystemSymbol.fromString('W-A');
    final source = SystemWaypoint.test(
      sourceSymbol,
      type: WaypointType.GAS_GIANT,
    );
    final marketSymbol = WaypointSymbol.fromString('W-A-B');
    final market = SystemWaypoint.test(
      marketSymbol,
      position: WaypointPosition(10, 0, systemSymbol),
    );
    final waypoints = [source, market];
    final systems = [System.test(systemSymbol, waypoints: waypoints)];
    final systemsSnapshot = SystemsSnapshot(systems);
    final producedGoods = {
      TradeSymbol.HYDROCARBON,
      TradeSymbol.LIQUID_HYDROGEN,
      TradeSymbol.LIQUID_NITROGEN,
    };
    for (final good in producedGoods) {
      when(
        () => marketListingStore.marketsWithImportInSystem(systemSymbol, good),
      ).thenAnswer((_) async => [market.symbol]);
    }

    final chartingStore = _MockChartingStore();
    when(() => db.charting).thenReturn(chartingStore);

    when(
      () => chartingStore.chartedValues(sourceSymbol),
    ).thenAnswer((_) async => ChartedValues.test());
    when(
      () => chartingStore.chartedValues(marketSymbol),
    ).thenAnswer((_) async => ChartedValues.test());

    final scores = await evaluateWaypointsForSiphoning(
      db,
      systemsSnapshot,

      systemSymbol,
    );
    expect(scores.length, 1);
    expect(scores.first.score, 20);
    expect(scores.first.producedGoods, producedGoods);
    expect(scores.first.goodsMissingFromMarkets, <TradeSymbol>{});
  });
}
