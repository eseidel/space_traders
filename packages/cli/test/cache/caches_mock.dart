import 'package:cli/caches.dart';
import 'package:mocktail/mocktail.dart';
import 'package:types/types.dart';

class _MockAgentCache extends Mock implements AgentCache {}

class _MockChartingCache extends Mock implements ChartingCache {}

class _MockConstructionCache extends Mock implements ConstructionCache {}

class _MockEventCache extends Mock implements EventCache {}

class _MockJumpGateSnapshot extends Mock implements JumpGateSnapshot {}

class _MockMarketCache extends Mock implements MarketCache {}

class _MockMarketPrices extends Mock implements MarketPriceSnapshot {}

class _MockRoutePlanner extends Mock implements RoutePlanner {}

class _MockShipEngineCache extends Mock implements ShipEngineCache {}

class _MockShipModuleCache extends Mock implements ShipModuleCache {}

class _MockShipMountCache extends Mock implements ShipMountCache {}

class _MockShipReactorCache extends Mock implements ShipReactorCache {}

class _MockShipyardShipCache extends Mock implements ShipyardShipCache {}

class _MockSystemConnectivity extends Mock implements SystemConnectivity {}

class _MockSystemsSnapshot extends Mock implements SystemsSnapshot {}

class _MockTradeExportCache extends Mock implements TradeExportCache {}

class _MockTradeGoodCache extends Mock implements TradeGoodCache {}

class _MockWaypointCache extends Mock implements WaypointCache {}

class _MockWaypointTraitCache extends Mock implements WaypointTraitCache {}

void _addMocks<Symbol extends Object, Record extends Object>(
  StaticCache<Symbol, Record> cache,
) {
  when(() => cache.addAll(any())).thenAnswer((_) async {});
  // Can't mock add() without also registering a fallback value for the type.
}

Caches mockCaches() {
  final mounts = _MockShipMountCache();
  final modules = _MockShipModuleCache();
  final shipyardShips = _MockShipyardShipCache();
  final engines = _MockShipEngineCache();
  final reactors = _MockShipReactorCache();
  final waypointTraits = _MockWaypointTraitCache();
  final tradeGoods = _MockTradeGoodCache();
  final exports = _MockTradeExportCache();
  final events = _MockEventCache();
  _addMocks(mounts);
  _addMocks(modules);
  _addMocks(shipyardShips);
  _addMocks(engines);
  _addMocks(reactors);
  _addMocks(waypointTraits);
  _addMocks(tradeGoods);
  _addMocks(exports);
  _addMocks(events);

  final staticCaches = StaticCaches.test(
    mounts: mounts,
    modules: modules,
    shipyardShips: shipyardShips,
    engines: engines,
    reactors: reactors,
    waypointTraits: waypointTraits,
    tradeGoods: tradeGoods,
    exports: exports,
    events: events,
  );
  return Caches(
    agent: _MockAgentCache(),
    marketPrices: _MockMarketPrices(),
    systems: _MockSystemsSnapshot(),
    waypoints: _MockWaypointCache(),
    markets: _MockMarketCache(),
    charting: _MockChartingCache(),
    routePlanner: _MockRoutePlanner(),
    factions: [],
    static: staticCaches,
    construction: _MockConstructionCache(),
    systemConnectivity: _MockSystemConnectivity(),
    jumpGates: _MockJumpGateSnapshot(),
  );
}
