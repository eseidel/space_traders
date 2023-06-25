import 'package:cli/api.dart';
import 'package:cli/cache/agent_cache.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockAgent extends Mock implements Agent {}

class _MockApi extends Mock implements Api {}

class _MockAgentsApi extends Mock implements AgentsApi {}

void main() {
  test('AgentCache smoke test', () {
    final api = _MockApi();
    final agent = _MockAgent();
    when(agent.toJson).thenReturn({});
    final newAgent = _MockAgent();
    when(newAgent.toJson).thenReturn({});
    final agents = _MockAgentsApi();
    when(() => api.agents).thenReturn(agents);
    when(agents.getMyAgent).thenAnswer(
      (_) => Future.value(GetMyAgent200Response(data: newAgent)),
    );
    final cache = AgentCache(agent, requestsBetweenChecks: 3);
    expect(cache.agent, agent);
    cache.ensureAgentUpToDate(api);
    verifyNever(agents.getMyAgent);
    cache.ensureAgentUpToDate(api);
    verifyNever(agents.getMyAgent);
    cache.ensureAgentUpToDate(api);
    verify(agents.getMyAgent).called(1);
  });
}
