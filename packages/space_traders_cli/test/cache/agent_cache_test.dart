import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/cache/agent_cache.dart';
import 'package:test/test.dart';

class MockAgent extends Mock implements Agent {}

class MockApi extends Mock implements Api {}

class MockAgentsApi extends Mock implements AgentsApi {}

void main() {
  test('AgentCache smoke test', () {
    final api = MockApi();
    final agent = MockAgent();
    when(agent.toJson).thenReturn({});
    final newAgent = MockAgent();
    when(newAgent.toJson).thenReturn({});
    final agents = MockAgentsApi();
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
