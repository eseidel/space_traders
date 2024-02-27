import 'package:cli/cache/caches.dart';
import 'package:mocktail/mocktail.dart';

class _MockAgentCache extends Mock implements AgentCache {}

class _MockChartingCache extends Mock implements ChartingCache {}

class _MockConstructionCache extends Mock implements ConstructionCache {}

class _MockJumpGateSnapshot extends Mock implements JumpGateSnapshot {}

class _MockMarketCache extends Mock implements MarketCache {}

class _MockMarketPrices extends Mock implements MarketPriceSnapshot {}

class _MockRoutePlanner extends Mock implements RoutePlanner {}

class _MockShipEngineCache extends Mock implements ShipEngineCache {}

class _MockShipModuleCache extends Mock implements ShipModuleCache {}

class _MockShipMountCache extends Mock implements ShipMountCache {}

class _MockShipReactorCache extends Mock implements ShipReactorCache {}

class _MockShipyardListingCache extends Mock
    implements ShipyardListingSnapshot {}

class _MockShipyardShipCache extends Mock implements ShipyardShipCache {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockSystemConnectivity extends Mock implements SystemConnectivity {}

class _MockTradeExportCache extends Mock implements TradeExportCache {}

class _MockTradeGoodCache extends Mock implements TradeGoodCache {}

class _MockWaypointCache extends Mock implements WaypointCache {}

class _MockWaypointTraitCache extends Mock implements WaypointTraitCache {}

Caches mockCaches() {
  final mounts = _MockShipMountCache();
  final modules = _MockShipModuleCache();
  final shipyardShips = _MockShipyardShipCache();
  final engines = _MockShipEngineCache();
  final reactors = _MockShipReactorCache();
  final waypointTraits = _MockWaypointTraitCache();
  final tradeGoods = _MockTradeGoodCache();
  final exports = _MockTradeExportCache();
  final staticCaches = StaticCaches(
    mounts: mounts,
    modules: modules,
    shipyardShips: shipyardShips,
    engines: engines,
    reactors: reactors,
    waypointTraits: waypointTraits,
    tradeGoods: tradeGoods,
    exports: exports,
  );
  return Caches(
    agent: _MockAgentCache(),
    marketPrices: _MockMarketPrices(),
    systems: _MockSystemsCache(),
    waypoints: _MockWaypointCache(),
    markets: _MockMarketCache(),
    charting: _MockChartingCache(),
    routePlanner: _MockRoutePlanner(),
    factions: [],
    static: staticCaches,
    construction: _MockConstructionCache(),
    systemConnectivity: _MockSystemConnectivity(),
    jumpGates: _MockJumpGateSnapshot(),
    shipyardListings: _MockShipyardListingCache(),
  );
}
