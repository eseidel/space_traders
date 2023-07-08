import 'dart:convert';

import 'package:cli/api.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/third_party/compare.dart';

bool _agentsMatch(Agent actual, Agent expected) {
  final diff = findDifferenceBetweenStrings(
    jsonEncode(actual.toJson()),
    jsonEncode(expected.toJson()),
  );
  if (diff != null) {
    logger.info('Agent differs from expected: $diff');
    return false;
  }
  return true;
}

/// Holds the Agent object between requests.
/// The "Agent" api object doesn't have a way to be updated, so this
/// is a holder for that object.
class AgentCache {
  /// Creates a new ship cache.
  AgentCache(this.agent, {this.requestsBetweenChecks = 100});

  /// Creates a new AgentCache from the API.
  static Future<AgentCache> load(Api api) async {
    final agent = await getMyAgent(api);
    return AgentCache(agent);
  }

  /// Ships in the cache.
  Agent agent;

  /// Number of requests between checks to ensure ships are up to date.
  final int requestsBetweenChecks;

  int _requestsSinceLastCheck = 0;

  /// The headquarters of the agent.
  SystemWaypoint headquarters(SystemsCache systems) =>
      systems.waypointFromSymbol(agent.headquarters);

  /// Updates the agent.
  // ignore: use_setters_to_change_properties
  void updateAgent(Agent newAgent) => agent = newAgent;

  /// Ensures the agent in the cache is up to date.
  Future<void> ensureAgentUpToDate(Api api) async {
    _requestsSinceLastCheck++;
    if (_requestsSinceLastCheck < requestsBetweenChecks) {
      return;
    }
    final newAgent = await getMyAgent(api);
    _requestsSinceLastCheck = 0;
    if (_agentsMatch(agent, newAgent)) {
      return;
    }
    logger.warn('Agent changed, updating cache.');
    updateAgent(newAgent);
  }
}
