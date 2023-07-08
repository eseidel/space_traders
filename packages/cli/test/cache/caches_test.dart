import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockApi extends Mock implements Api {}

class _MockAgentsApi extends Mock implements AgentsApi {}

class _MockAgent extends Mock implements Agent {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

class _MockContractsApi extends Mock implements ContractsApi {}

class _MockFactionsApi extends Mock implements FactionsApi {}

void main() {
  test('Caches load test', () async {
    final api = _MockApi();
    final agentsApi = _MockAgentsApi();
    when(() => api.agents).thenReturn(agentsApi);
    final agent = _MockAgent();
    when(agentsApi.getMyAgent)
        .thenAnswer((_) => Future.value(GetMyAgent200Response(data: agent)));
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

    final fs = MemoryFileSystem.test();
    final logger = _MockLogger();
    final caches =
        await runWithLogger(logger, () async => Caches.load(fs, api));
    expect(caches.agent, isNotNull);
  });
}
