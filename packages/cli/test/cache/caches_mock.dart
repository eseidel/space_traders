import 'package:cli/cache/caches.dart';
import 'package:mocktail/mocktail.dart';

class _MockAgentCache extends Mock implements AgentCache {}

class _MockChartingCache extends Mock implements ChartingCache {}

class _MockMarketCache extends Mock implements MarketCache {}

class _MockMarketPrices extends Mock implements MarketPrices {}

class _MockShipyardPrices extends Mock implements ShipyardPrices {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockWaypointCache extends Mock implements WaypointCache {}

class _MockShipCache extends Mock implements ShipCache {}

class _MockContractCache extends Mock implements ContractCache {}

class _MockBehaviorCache extends Mock implements BehaviorCache {}

class _MockRoutePlanner extends Mock implements RoutePlanner {}

class _MockShipMountCache extends Mock implements ShipMountCache {}

class _MockShipModuleCache extends Mock implements ShipModuleCache {}

class _MockShipyardShipCache extends Mock implements ShipyardShipCache {}

class _MockShipEngineCache extends Mock implements ShipEngineCache {}

class _MockShipReactorCache extends Mock implements ShipReactorCache {}

class _MockWaypointTraitCache extends Mock implements WaypointTraitCache {}

Caches mockCaches() {
  final mounts = _MockShipMountCache();
  final modules = _MockShipModuleCache();
  final shipyardShips = _MockShipyardShipCache();
  final engines = _MockShipEngineCache();
  final reactors = _MockShipReactorCache();
  final waypointTraits = _MockWaypointTraitCache();
  final staticCache = StaticCaches(
    mounts: mounts,
    modules: modules,
    shipyardShips: shipyardShips,
    engines: engines,
    reactors: reactors,
    waypointTraits: waypointTraits,
  );
  return Caches(
    agent: _MockAgentCache(),
    marketPrices: _MockMarketPrices(),
    ships: _MockShipCache(),
    shipyardPrices: _MockShipyardPrices(),
    systems: _MockSystemsCache(),
    waypoints: _MockWaypointCache(),
    markets: _MockMarketCache(),
    contracts: _MockContractCache(),
    behaviors: _MockBehaviorCache(),
    charting: _MockChartingCache(),
    routePlanner: _MockRoutePlanner(),
    factions: [],
    static: staticCache,
  );
}
