import 'package:cli/caches.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockApi extends Mock implements Api {}

class _MockSystemsApi extends Mock implements SystemsApi {}

class _MockDatabase extends Mock implements Database {}

void main() {
  test('WaypointCache.waypoint', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final SystemsApi systemsApi = _MockSystemsApi();
    when(() => api.systems).thenReturn(systemsApi);
    final waypointSymbol = WaypointSymbol.fromString('S-E-A');
    final expectedWaypoint = Waypoint.test(waypointSymbol);
    when(
      () => systemsApi.getSystemWaypoints(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) async {
      return GetSystemWaypoints200Response(
        data: [expectedWaypoint.toOpenApi()],
        meta: Meta(total: 1),
      );
    });

    registerFallbackValue(waypointSymbol);
    registerFallbackValue(Duration.zero);
    when(
      () => db.getChartingRecord(any(), any()),
    ).thenAnswer((_) async => null);
    registerFallbackValue(waypointSymbol.system);
    when(
      () => db.systemWaypointsBySystemSymbol(any()),
    ).thenAnswer((_) async => [expectedWaypoint.toSystemWaypoint()]);
    registerFallbackValue(ChartingRecord.fallbackValue());
    when(() => db.upsertChartingRecord(any())).thenAnswer((_) async {});
    registerFallbackValue(ConstructionRecord.fallbackValue());
    when(() => db.upsertConstruction(any())).thenAnswer((_) async {});

    final waypointCache = WaypointCache(api, db);
    expect(
      (await waypointCache.waypoint(waypointSymbol)).symbol,
      waypointSymbol,
    );
    // WaypointCache no longer has it's own in-memory cache, it just delegates
    // the other caches, which are mocked in this example to always return
    // the same values, so we expect this to hit the API twice.
    expect(
      (await waypointCache.waypoint(waypointSymbol)).symbol,
      waypointSymbol,
    );
    verify(
      () => systemsApi.getSystemWaypoints(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).called(2);

    // For coverage.
    expect(await waypointCache.hasMarketplace(waypointSymbol), false);
    expect(await waypointCache.hasShipyard(waypointSymbol), false);
    expect(await waypointCache.canBeMined(waypointSymbol), false);
    expect(await waypointCache.canBeSiphoned(waypointSymbol), false);

    // The has getters still throw if the waypoint doesn't exist.
    // TODO(eseidel): this will need db mocks.
    expect(
      () async => await waypointCache.hasMarketplace(
        WaypointSymbol.fromString('A-B-C'),
      ),
      throwsArgumentError,
    );
  });
}
