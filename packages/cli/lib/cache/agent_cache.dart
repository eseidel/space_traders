import 'dart:convert';

import 'package:cli/api.dart';
import 'package:cli/cache/json_store.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/third_party/compare.dart';
import 'package:file/file.dart';
import 'package:types/types.dart';

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
class AgentCache extends JsonStore<Agent> {
  /// Creates a new ship cache.
  AgentCache(
    super.agent, {
    required super.fs,
    super.path = defaultPath,
    this.requestsBetweenChecks = 100,
  }) : super(recordToJson: (a) => a.toJson());

  /// Creates a new AgentCache from a file.
  static AgentCache? loadCached(FileSystem fs, {String path = defaultPath}) {
    final agent = JsonStore.load<Agent>(
      fs,
      path,
      (j) => Agent.fromJson(j)!,
    );
    if (agent == null) {
      return null;
    }
    return AgentCache(agent, fs: fs, path: path);
  }

  /// Creates a new AgentCache from the API.
  static Future<AgentCache> load(
    Api api, {
    required FileSystem fs,
    String path = defaultPath,
  }) async {
    final agent = await getMyAgent(api);
    return AgentCache(agent, fs: fs, path: path);
  }

  /// Default location of the cache file.
  static const String defaultPath = 'data/agent.json';

  /// Agent object held in the cache.
  Agent get agent => record;
  set agent(Agent newAgent) {
    record = newAgent;
    save();
  }

  /// Number of requests between checks to ensure ships are up to date.
  final int requestsBetweenChecks;

  int _requestsSinceLastCheck = 0;

  /// The headquarters of the agent.
  SystemWaypoint headquarters(SystemsCache systems) =>
      systems.waypointFromSymbol(agent.headquartersSymbol);

  /// The symbol of the agent's headquarters.
  WaypointSymbol get headquartersSymbol => agent.headquartersSymbol;

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
    agent = newAgent;
  }
}
