import 'package:cli/api.dart';
import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cache/construction_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/waypoint_cache.dart';
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
    final SystemsApi systemsApi = _MockSystemsApi();
    when(() => api.systems).thenReturn(systemsApi);
    final expectedWaypoint = Waypoint(
      symbol: 'S-E-A',
      systemSymbol: 'S-E',
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
    final symbol = WaypointSymbol.fromString('S-E-A');
    when(() => systemsCache.waypointsInSystem(symbol.systemSymbol)).thenReturn([
      SystemWaypoint(
        symbol: 'S-E-A',
        type: WaypointType.PLANET,
        x: 0,
        y: 0,
      ),
    ]);
    final chartingCache = _MockChartingCache();
    final constructionCache = _MockConstructionCache();
    final waypointCache =
        WaypointCache(api, systemsCache, chartingCache, constructionCache);
    expect(await waypointCache.waypoint(symbol), expectedWaypoint);
    // Call it twice, it should cache.
    expect(await waypointCache.waypoint(symbol), expectedWaypoint);
    verify(
      () => systemsApi.getSystemWaypoints(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).called(1);
  });
}
