import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/net/queries.dart';

/// A queue for fetching system information.
class FetchQueue {
  /// Create a new fetch queue.
  FetchQueue();

  final List<SystemSymbol> _systems = [];
  final Set<SystemSymbol> _seen = {};

  /// Queue a system for fetching.
  void queueSystem(SystemSymbol systemSymbol) {
    if (_seen.contains(systemSymbol)) {
      return;
    }
    logger.info('Queuing: $systemSymbol');
    _systems.add(systemSymbol);
  }

  Future<void> _processSystem(
    Api api,
    Caches caches,
    SystemSymbol systemSymbol,
  ) async {
    logger.info('Process: $systemSymbol');
    _seen.add(systemSymbol);
    final waypoints = await caches.waypoints.waypointsInSystem(systemSymbol);
    for (final waypoint in waypoints) {
      final waypointSymbol = waypoint.waypointSymbol;
      if (waypoint.hasMarketplace) {
        final listing = caches.marketListings[waypointSymbol];
        if (listing == null) {
          logger.info(' Market: $waypointSymbol');
          await caches.markets.refreshMarket(waypointSymbol);
        }
      }
      if (waypoint.hasShipyard) {
        final listing = caches.shipyardListings[waypointSymbol];
        if (listing == null) {
          logger.info(' Shipyard: $waypointSymbol');
          final shipyard = await getShipyard(api, waypointSymbol);
          caches.shipyardListings.addShipyard(shipyard);
        }
      }

      // Can only fetch jump gates for waypoints which are charted or have
      // a ship there.
      if (waypoint.isJumpGate && waypoint.isCharted) {
        final jumpGateRecord =
            await caches.jumpGates.getOrFetch(api, waypoint.waypointSymbol);
        for (final systemSymbol in jumpGateRecord.connectedSystemSymbols) {
          queueSystem(systemSymbol);
        }
      }
    }
  }

  /// Run one fetch.
  Future<void> runOne(Api api, Caches caches) async {
    if (isDone) {
      return;
    }
    await _processSystem(api, caches, _systems.removeLast());
  }

  /// Returns true when the queue is empty.
  bool get isDone => _systems.isEmpty;
}
