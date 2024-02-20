import 'package:cli/api.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/config.dart';
import 'package:cli/net/queries.dart';

/// Holds the Agent object between requests.
/// The "Agent" api object doesn't have a way to be updated, so this
/// is a holder for that object.
class AgentCache {
  /// Creates a new ship cache.
  AgentCache(Agent agent, Database db, {this.requestsBetweenChecks = 100})
      : _agent = agent,
        _db = db;

  Agent _agent;
  final Database _db;

  /// Loads the agent from the cache.
  // TODO(eseidel): Do callers need an AgentCache or just an Agent?
  static Future<AgentCache?> load(Database db) async {
    final agent = await db.getAgent(symbol: config.agentSymbol);
    if (agent == null) {
      return null;
    }
    return AgentCache(agent, db);
  }

  /// Creates a new AgentCache from the API.
  static Future<AgentCache> loadOrFetch(Database db, Api api) async {
    final cached = await db.getAgent(symbol: config.agentSymbol);
    if (cached != null) {
      return AgentCache(cached, db);
    }
    final agent = await getMyAgent(api);
    return AgentCache(agent, db);
  }

  /// Agent object held in the cache.
  Agent get agent => _agent;

  /// Sets the agent in the cache.
  Future<void> updateAgent(Agent agent) async {
    _agent = agent;
    await _db.upsertAgent(agent);
  }

  /// Number of requests between checks to ensure ships are up to date.
  final int requestsBetweenChecks;

  int _requestsSinceLastCheck = 0;

  /// The headquarters of the agent.
  SystemWaypoint headquarters(SystemsCache systems) =>
      systems.waypoint(agent.headquarters);

  /// The symbol of the agent's headquarters.
  WaypointSymbol get headquartersSymbol => agent.headquarters;

  /// The symbol of the system of the agent's headquarters.
  SystemSymbol get headquartersSystemSymbol => agent.headquarters.system;

  /// Ensures the agent in the cache is up to date.
  // TODO(eseidel): Move this out of this class.
  Future<void> ensureAgentUpToDate(Api api) async {
    _requestsSinceLastCheck++;
    if (_requestsSinceLastCheck < requestsBetweenChecks) {
      return;
    }
    final newAgent = await getMyAgent(api);
    _requestsSinceLastCheck = 0;
    if (newAgent == agent) {
      return;
    }
    logger.warn('Agent changed, updating cache.');
    await updateAgent(newAgent);
  }
}
