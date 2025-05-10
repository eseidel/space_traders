import 'package:cli/logger.dart';
import 'package:cli/plan/supply_chain.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  test('SupplyChainBuilder smoke test', () async {
    final to = WaypointSymbol.fromString('W-A-A');
    final systemsSnapshot = SystemsSnapshot([
      System.test(to.system, waypoints: [SystemWaypoint.test(to)]),
    ]);
    final builder = SupplyChainBuilder(
      systems: systemsSnapshot,
      marketListings: MarketListingSnapshot([]),
      exports: TradeExportSnapshot([]),
      charting: ChartingSnapshot([]),
    );
    const tradeSymbol = TradeSymbol.ADVANCED_CIRCUITRY;

    final logger = _MockLogger();
    final supplyChain = runWithLogger(
      logger,
      () => builder.buildChainTo(tradeSymbol, to),
    );
    expect(supplyChain, isNull);
  });
}
