import 'package:cli/api.dart';
import 'package:cli/cache/agent_cache.dart';
import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockAgentsApi extends Mock implements AgentsApi {}

class _MockApi extends Mock implements Api {}

class _MockLogger extends Mock implements Logger {}

class _MockDatabase extends Mock implements Database {}

void main() {
  test('AgentCache smoke test', () {
    final api = _MockApi();
    final agent = Agent.test(credits: 1);
    final newAgent = Agent.test(credits: 2);
    final agents = _MockAgentsApi();
    when(() => api.agents).thenReturn(agents);
    when(agents.getMyAgent).thenAnswer(
      (_) => Future.value(GetMyAgent200Response(data: newAgent.toOpenApi())),
    );
    final db = _MockDatabase();
    registerFallbackValue(Agent.test());
    when(() => db.upsertAgent(any())).thenAnswer((_) => Future.value());
    final cache = AgentCache(agent, db, requestsBetweenChecks: 3);
    expect(cache.agent, agent);
    cache.ensureAgentUpToDate(api);
    verifyNever(agents.getMyAgent);
    cache.ensureAgentUpToDate(api);
    verifyNever(agents.getMyAgent);
    final logger = _MockLogger();
    runWithLogger(logger, () {
      cache.ensureAgentUpToDate(api);
    });
    verify(agents.getMyAgent).called(1);
  });
}
