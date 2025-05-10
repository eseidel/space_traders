import 'package:cli/caches.dart';
import 'package:mocktail/mocktail.dart';
import 'package:types/types.dart';

// class _MockEventCache extends Mock implements EventCache {}

class _MockMarketCache extends Mock implements MarketCache {}

class _MockMarketPrices extends Mock implements MarketPriceSnapshot {}

class _MockRoutePlanner extends Mock implements RoutePlanner {}

// class _MockShipEngineStore extends Mock implements ShipEngineStore {}

// class _MockShipModuleStore extends Mock implements ShipModuleStore {}

// class _MockShipMountStore extends Mock implements ShipMountStore {}

// class _MockShipReactorStore extends Mock implements ShipReactorStore {}

// class _MockShipyardShipStore extends Mock implements ShipyardShipStore {}

class _MockSystemConnectivity extends Mock implements SystemConnectivity {}

class _MockSystemsSnapshot extends Mock implements SystemsSnapshot {}

// class _MockTradeExportStore extends Mock implements TradeExportStore {}

// class _MockTradeGoodStore extends Mock implements TradeGoodStore {}

// class _MockWaypointStore extends Mock implements WaypointStore {}

// class _MockWaypointTraitStore extends Mock implements WaypointTraitStore {}

class _MockGalaxyStats extends Mock implements GalaxyStats {}

class _MockWaypointCache extends Mock implements WaypointCache {}

// void _addMocks<Symbol extends Object, Record extends Object>(
//   StaticCache<Symbol, Record> cache,
// ) {
//   when(() => cache.addAll(any())).thenAnswer((_) async {
//     return null;
//   });
//   // Can't mock add() without also registering a fallback value for the type.
// }

Caches mockCaches() {
  // final mounts = _MockShipMountCache();
  // final modules = _MockShipModuleCache();
  // final shipyardShips = _MockShipyardShipCache();
  // final engines = _MockShipEngineCache();
  // final reactors = _MockShipReactorCache();
  // final waypointTraits = _MockWaypointTraitCache();
  // final tradeGoods = _MockTradeGoodCache();
  // final exports = _MockTradeExportCache();
  // final events = _MockEventCache();
  // _addMocks(mounts);
  // _addMocks(modules);
  // _addMocks(shipyardShips);
  // _addMocks(engines);
  // _addMocks(reactors);
  // _addMocks(waypointTraits);
  // _addMocks(tradeGoods);
  // _addMocks(exports);
  // _addMocks(events);

  // final staticCaches = StaticCaches.test(
  //   mounts: mounts,
  //   modules: modules,
  //   shipyardShips: shipyardShips,
  //   engines: engines,
  //   reactors: reactors,
  //   waypointTraits: waypointTraits,
  //   tradeGoods: tradeGoods,
  //   exports: exports,
  //   events: events,
  // );
  return Caches(
    marketPrices: _MockMarketPrices(),
    systems: _MockSystemsSnapshot(),
    waypoints: _MockWaypointCache(),
    markets: _MockMarketCache(),
    routePlanner: _MockRoutePlanner(),
    factions: [],
    systemConnectivity: _MockSystemConnectivity(),
    galaxy: _MockGalaxyStats(),
  );
}
