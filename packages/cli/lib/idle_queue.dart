import 'dart:collection';

import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/net/queries.dart';

/// A queue which does not allow items to be queued more than once.
class NonRepeatingQueue<T> {
  final Queue<T> _items = Queue();
  final Set<T> _seen = {};

  /// Add an item to the queue.
  bool queue(T item) {
    if (_seen.contains(item) || _items.contains(item)) {
      return false;
    }
    _items.add(item);
    return true;
  }

  /// Take the next item from the queue.
  T take() {
    final item = _items.removeFirst();
    _seen.add(item);
    return item;
  }

  /// How many items are in the queue.
  int get length => _items.length;

  /// Returns true when the queue is not empty.
  bool get isNotEmpty => _items.isNotEmpty;

  /// Returns true when the queue is empty.
  bool get isEmpty => _items.isEmpty;
}

/// A queue for fetching system information.
class IdleQueue {
  /// Create a new fetch queue.
  IdleQueue();

  final NonRepeatingQueue<SystemSymbol> _systems = NonRepeatingQueue();
  final NonRepeatingQueue<WaypointSymbol> _jumpGates = NonRepeatingQueue();

  /// Queue a system for fetching.
  void queueSystem(SystemSymbol systemSymbol) {
    final queued = _systems.queue(systemSymbol);
    if (queued) {
      logger.info('Queued System (${_systems.length}): $systemSymbol');
    }
  }

  /// Queue jump gate connections for fetching.
  // TODO(eseidel): Jump gate construction completion should call this.
  void queueJumpGateConnections(JumpGateRecord jumpGateRecord) {
    for (final connection in jumpGateRecord.connections) {
      _queueJumpGate(connection);
    }
  }

  /// Queue a jump gate for fetching.
  void _queueJumpGate(WaypointSymbol waypointSymbol) {
    final queued = _jumpGates.queue(waypointSymbol);
    if (queued) {
      logger.info('Queued JumpGate (${_jumpGates.length}): $waypointSymbol');
    }
  }

  Future<void> _processNextJumpGate(Api api, Caches caches) async {
    final to = _jumpGates.take();
    logger.detail('Process (${_jumpGates.length}): $to');
    // Make sure we have construction data for the destination before
    // checking if we can jump there.
    await caches.waypoints.isUnderConstruction(to);
    if (canJumpTo(caches.jumpGates, caches.construction, to)) {
      queueSystem(to.systemSymbol);
    }
  }

  Future<void> _processNextSystem(Api api, Caches caches) async {
    final systemSymbol = _systems.take();
    logger.detail('Process (${_systems.length}): $systemSymbol');
    final waypoints = caches.systems.waypointsInSystem(systemSymbol);
    for (final waypoint in waypoints) {
      final waypointSymbol = waypoint.waypointSymbol;
      if (await caches.waypoints.hasMarketplace(waypointSymbol)) {
        final listing = caches.marketListings[waypointSymbol];
        if (listing == null) {
          logger.info(' Market: $waypointSymbol');
          await caches.markets.refreshMarket(waypointSymbol);
        }
      }
      if (await caches.waypoints.hasShipyard(waypointSymbol)) {
        final listing = caches.shipyardListings[waypointSymbol];
        if (listing == null) {
          logger.info(' Shipyard: $waypointSymbol');
          final shipyard = await getShipyard(api, waypointSymbol);
          caches.shipyardListings.addShipyard(shipyard);
        }
      }

      // Can only fetch jump gates for waypoints which are charted or have
      // a ship there.
      if (waypoint.isJumpGate &&
          (await caches.waypoints.isCharted(waypointSymbol))) {
        final fromRecord =
            await caches.jumpGates.getOrFetch(api, waypoint.waypointSymbol);
        final from = fromRecord.waypointSymbol;
        if (!canJumpFrom(caches.jumpGates, caches.construction, from)) {
          continue;
        }
        // Queue each jumpGate as it might fetch construction data which could
        // total to many requests for a single processNextSystem call.
        queueJumpGateConnections(fromRecord);
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
    if (_systems.isNotEmpty) {
      await _processNextSystem(api, caches);
      return;
    }
    if (_jumpGates.isNotEmpty) {
      await _processNextJumpGate(api, caches);
      return;
    }
  }

  /// Returns true when the queue is empty.
  bool get isDone => _systems.isEmpty && _jumpGates.isEmpty;
}
