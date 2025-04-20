import 'package:cli/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/plan/supply_chain.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockLogger extends Mock implements Logger {}

void main() {
  test('SupplyChainBuilder smoke test', () async {
    final fs = MemoryFileSystem.test();
    final systems = _MockSystemsCache();
    final to = WaypointSymbol.fromString('W-A-A');
    when(() => systems.waypoint(to)).thenReturn(SystemWaypoint.test(to));
    final builder = SupplyChainBuilder(
      systems: systems,
      marketListings: MarketListingSnapshot([]),
      exports: TradeExportCache([], fs: fs),
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
