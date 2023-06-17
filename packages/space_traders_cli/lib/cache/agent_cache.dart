import 'package:space_traders_cli/api.dart';

/// Holds the Agent object between requests.
/// The "Agent" api object doesn't have a way to be updated, so this
/// is a holder for that object.
class AgentCache {
  /// Creates a new ship cache.
  AgentCache(this.agent);

  /// Ships in the cache.
  Agent agent;
}
