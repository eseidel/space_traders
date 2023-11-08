import 'package:cli/cache/caches.dart';
import 'package:mocktail/mocktail.dart';

class _MockAgentCache extends Mock implements AgentCache {}

class _MockBehaviorCache extends Mock implements BehaviorCache {}

class _MockChartingCache extends Mock implements ChartingCache {}

class _MockConstructionCache extends Mock implements ConstructionCache {}

class _MockContractCache extends Mock implements ContractCache {}

class _MockMarketCache extends Mock implements MarketCache {}

class _MockMarketListingCache extends Mock implements MarketListingCache {}

class _MockMarketPrices extends Mock implements MarketPrices {}

class _MockRoutePlanner extends Mock implements RoutePlanner {}

class _MockShipCache extends Mock implements ShipCache {}

class _MockShipEngineCache extends Mock implements ShipEngineCache {}

class _MockShipModuleCache extends Mock implements ShipModuleCache {}

class _MockShipMountCache extends Mock implements ShipMountCache {}

class _MockShipReactorCache extends Mock implements ShipReactorCache {}

class _MockShipyardPrices extends Mock implements ShipyardPrices {}

class _MockShipyardShipCache extends Mock implements ShipyardShipCache {}

class _MockSystemsCache extends Mock implements SystemsCache {}

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
  final staticCache = StaticCaches(
    mounts: mounts,
    modules: modules,
    shipyardShips: shipyardShips,
    engines: engines,
    reactors: reactors,
    waypointTraits: waypointTraits,
    tradeGoods: tradeGoods,
  );
  return Caches(
    agent: _MockAgentCache(),
    marketPrices: _MockMarketPrices(),
    ships: _MockShipCache(),
    shipyardPrices: _MockShipyardPrices(),
    systems: _MockSystemsCache(),
    waypoints: _MockWaypointCache(),
    markets: _MockMarketCache(),
    marketListings: _MockMarketListingCache(),
    contracts: _MockContractCache(),
    behaviors: _MockBehaviorCache(),
    charting: _MockChartingCache(),
    routePlanner: _MockRoutePlanner(),
    factions: [],
    static: staticCache,
    construction: _MockConstructionCache(),
  );
}
