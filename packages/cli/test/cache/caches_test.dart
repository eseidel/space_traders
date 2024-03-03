import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockAgentsApi extends Mock implements AgentsApi {}

class _MockApi extends Mock implements Api {}

class _MockContractsApi extends Mock implements ContractsApi {}

class _MockDatabase extends Mock implements Database {}

class _MockFactionsApi extends Mock implements FactionsApi {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

void main() {
  test('Caches load test', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final agentsApi = _MockAgentsApi();
    when(() => api.agents).thenReturn(agentsApi);
    final agent = Agent.test();
    when(() => db.getAgent(symbol: any(named: 'symbol')))
        .thenAnswer((_) => Future.value(agent));
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
      (_) => Future.value(
        GetContracts200Response(meta: Meta(total: 0), data: []),
      ),
    );
    final factionsApi = _MockFactionsApi();
    when(() => api.factions).thenReturn(factionsApi);
    when(
      () => factionsApi.getFactions(
        limit: any(named: 'limit'),
        page: any(named: 'page'),
      ),
    ).thenAnswer(
      (_) => Future.value(
        GetFactions200Response(meta: Meta(total: 0), data: []),
      ),
    );
    when(db.allFactions).thenAnswer((_) => Future.value(<Faction>[]));
    when(() => db.upsertFaction(any())).thenAnswer((_) async => {});
    when(db.allConstructionRecords)
        .thenAnswer((_) => Future.value(<ConstructionRecord>[]));

    when(db.allMarketListings).thenAnswer((_) async => []);
    when(db.allMarketPrices).thenAnswer((_) async => []);
    when(db.allShipyardListings).thenAnswer((_) async => []);
    when(db.allShipyardPrices).thenAnswer((_) async => []);
    when(db.allJumpGates).thenAnswer((_) async => []);
    when(db.allBehaviorStates).thenAnswer((_) async => []);

    final fs = MemoryFileSystem.test();
    fs.file(SystemsCache.defaultCacheFilePath).createSync(recursive: true);
    fs.file(SystemsCache.defaultCacheFilePath).writeAsStringSync('[]');
    final logger = _MockLogger();
    Never httpGet(f) => throw UnimplementedError();
    final caches = await runWithLogger(
      logger,
      () async => Caches.loadOrFetch(fs, api, db, httpGet: httpGet),
    );
    expect(caches.agent, isNotNull);
  });
}
