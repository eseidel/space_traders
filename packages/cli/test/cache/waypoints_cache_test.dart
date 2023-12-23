import 'package:cli/cache/caches.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockApi extends Mock implements Api {}

class _MockSystemsApi extends Mock implements SystemsApi {}

class _MockChartingCache extends Mock implements ChartingCache {}

class _MockConstructionCache extends Mock implements ConstructionCache {}

void main() {
  test('WaypointCache.waypoint', () async {
    final api = _MockApi();
    final fs = MemoryFileSystem.test();
    final SystemsApi systemsApi = _MockSystemsApi();
    when(() => api.systems).thenReturn(systemsApi);
    final waypointSymbol = WaypointSymbol.fromString('S-E-A');
    final expectedWaypoint = Waypoint(
      symbol: waypointSymbol.waypoint,
      systemSymbol: waypointSymbol.system,
      type: WaypointType.PLANET,
      x: 0,
      y: 0,
      isUnderConstruction: false,
    );
    when(
      () => systemsApi.getSystemWaypoints(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) async {
      return GetSystemWaypoints200Response(
        data: [expectedWaypoint],
        meta: Meta(total: 1),
      );
    });
    final systemsCache = _MockSystemsCache();
    when(() => systemsCache.waypointsInSystem(waypointSymbol.systemSymbol))
        .thenReturn([
      SystemWaypoint(
        symbol: waypointSymbol.waypoint,
        type: WaypointType.PLANET,
        x: 0,
        y: 0,
      ),
    ]);
    final chartingCache = _MockChartingCache();
    final constructionCache = _MockConstructionCache();
    when(
      () => constructionCache.updateConstruction(waypointSymbol, null),
    ).thenAnswer((_) async => {});

    final waypointTraitCache = WaypointTraitCache([], fs: fs);
    final waypointCache = WaypointCache(
      api,
      systemsCache,
      chartingCache,
      constructionCache,
      waypointTraitCache,
    );
    expect(await waypointCache.waypoint(waypointSymbol), expectedWaypoint);
    // Call it twice, it should cache.
    expect(await waypointCache.waypoint(waypointSymbol), expectedWaypoint);
    verify(
      () => systemsApi.getSystemWaypoints(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).called(1);

    // For coverage.
    expect(await waypointCache.hasMarketplace(waypointSymbol), false);
    expect(await waypointCache.hasShipyard(waypointSymbol), false);
    expect(await waypointCache.canBeMined(waypointSymbol), false);
    expect(await waypointCache.canBeSiphoned(waypointSymbol), false);

    // The has getters still throw if the waypoint doesn't exist.
    when(() => systemsCache.waypointsInSystem(SystemSymbol.fromString('A-B')))
        .thenReturn([]);
    expect(
      () async => await waypointCache
          .hasMarketplace(WaypointSymbol.fromString('A-B-C')),
      throwsArgumentError,
    );
  });
}
