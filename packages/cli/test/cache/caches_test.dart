import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:db/src/stores/systems_store.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockAgentsApi extends Mock implements AgentsApi {}

class _MockApi extends Mock implements Api {}

class _MockContractsApi extends Mock implements ContractsApi {}

class _MockDataApi extends Mock implements DataApi {}

class _MockDatabase extends Mock implements Database {}

class _MockFactionsApi extends Mock implements FactionsApi {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockGlobalApi extends Mock implements GlobalApi {}

class _MockLogger extends Mock implements Logger {}

class _MockSystemsStore extends Mock implements SystemsStore {}

void main() {
  test('Caches load test', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final systemsStore = _MockSystemsStore();
    when(() => db.systems).thenReturn(systemsStore);
    final agentsApi = _MockAgentsApi();
    when(() => api.agents).thenReturn(agentsApi);
    final agent = Agent.test();
    when(db.getMyAgent).thenAnswer((_) => Future.value(agent));
    when(agentsApi.getMyAgent).thenAnswer(
      (_) => Future.value(GetMyAgent200Response(data: agent.toOpenApi())),
    );
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    when(
      () => fleetApi.getMyShips(
        limit: any(named: 'limit'),
        page: any(named: 'page'),
      ),
    ).thenAnswer(
      (_) =>
          Future.value(GetMyShips200Response(meta: Meta(total: 0), data: [])),
    );
    final contractsApi = _MockContractsApi();
    when(() => api.contracts).thenReturn(contractsApi);
    when(
      () => contractsApi.getContracts(
        limit: any(named: 'limit'),
        page: any(named: 'page'),
      ),
    ).thenAnswer(
      (_) =>
          Future.value(GetContracts200Response(meta: Meta(total: 0), data: [])),
    );
    final factionsApi = _MockFactionsApi();
    when(() => api.factions).thenReturn(factionsApi);
    when(
      () => factionsApi.getFactions(
        limit: any(named: 'limit'),
        page: any(named: 'page'),
      ),
    ).thenAnswer(
      (_) =>
          Future.value(GetFactions200Response(meta: Meta(total: 0), data: [])),
    );
    when(db.allFactions).thenAnswer((_) => Future.value(<Faction>[]));
    registerFallbackValue(
      Faction(
        symbol: FactionSymbol.ANCIENTS,
        name: '',
        description: '',
        headquarters: '',
        isRecruiting: false,
      ),
    );
    when(() => db.upsertFaction(any())).thenAnswer((_) async => {});
    when(
      db.allConstructionRecords,
    ).thenAnswer((_) => Future.value(<ConstructionRecord>[]));

    when(db.allMarketListings).thenAnswer((_) async => []);
    when(db.allMarketPrices).thenAnswer((_) async => []);
    when(db.allShipyardListings).thenAnswer((_) async => []);
    when(db.allShipyardPrices).thenAnswer((_) async => []);
    when(db.allJumpGates).thenAnswer((_) async => []);
    when(db.allBehaviorStates).thenAnswer((_) async => []);
    when(systemsStore.allSystemRecords).thenAnswer((_) async => []);
    when(systemsStore.allSystemWaypoints).thenAnswer((_) async => []);

    final dataApi = _MockDataApi();
    when(() => api.data).thenReturn(dataApi);
    registerFallbackValue(TradeExport);
    when(
      () => db.getAllFromStaticCache(type: any(named: 'type')),
    ).thenAnswer((_) async => []);
    when(dataApi.getSupplyChain).thenAnswer(
      (_) async => GetSupplyChain200Response(
        data: GetSupplyChain200ResponseData(exportToImportMap: {}),
      ),
    );

    final globalApi = _MockGlobalApi();
    when(() => api.global).thenReturn(globalApi);
    final status = GetStatus200Response(
      announcements: [],
      version: '1.0.0',
      resetDate: '2021-01-01',
      description: '',
      leaderboards: GetStatus200ResponseLeaderboards(
        mostCredits: [],
        mostSubmittedCharts: [],
      ),
      serverResets: GetStatus200ResponseServerResets(
        next: '2021-01-01',
        frequency: 'daily',
      ),
      stats: GetStatus200ResponseStats(
        systems: 100,
        waypoints: 100,
        agents: 100,
        ships: 100,
      ),
      status: 'OK',
    );
    when(globalApi.getStatus).thenAnswer((_) => Future.value(status));
    final logger = _MockLogger();
    Never httpGet(f) => throw UnimplementedError();
    final caches = await runWithLogger(
      logger,
      () async => Caches.loadOrFetch(api, db, httpGet: httpGet),
    );
    expect(caches.agent, isNotNull);
  });
}
