import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/net/queries.dart';

/// A queue for fetching system information.
class IdleQueue {
  /// Create a new fetch queue.
  IdleQueue();

  final List<SystemSymbol> _systems = [];
  final Set<SystemSymbol> _seen = {};

  /// Queue a system for fetching.
  void queueSystem(SystemSymbol systemSymbol) {
    if (_seen.contains(systemSymbol)) {
      return;
    }
    logger.detail('Queuing: $systemSymbol');
    _systems.add(systemSymbol);
  }

  Future<void> _processSystem(
    Api api,
    Caches caches,
    SystemSymbol systemSymbol,
  ) async {
    logger.detail('Process: $systemSymbol');
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
        final fromRecord =
            await caches.jumpGates.getOrFetch(api, waypoint.waypointSymbol);
        final from = fromRecord.waypointSymbol;
        if (!canJumpFrom(caches.jumpGates, caches.construction, from)) {
          continue;
        }
        for (final to in fromRecord.connections) {
          if (canJumpTo(caches.jumpGates, caches.construction, to)) {
            queueSystem(to.systemSymbol);
          }
        }
      }
    }
  }

  /// A guess at the minimum time we need to do one loop.
  Duration get minProcessingTime => const Duration(seconds: 1);

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
