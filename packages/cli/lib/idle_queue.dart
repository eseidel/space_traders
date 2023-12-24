import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/config.dart';
import 'package:cli/net/queries.dart';
import 'package:collection/collection.dart';

/// A queue which does not allow items to be queued more than once.
class NonRepeatingQueue<T> {
  /// Create a new queue.
  NonRepeatingQueue([int Function(T, T)? comparison])
      : _items = PriorityQueue(comparison),
        _seen = {};

  final PriorityQueue<T> _items;
  final Set<T> _seen;

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

  /// How many items have been seen.
  int get seenLength => _seen.length;

  /// Returns true when the queue is not empty.
  bool get isNotEmpty => _items.isNotEmpty;

  /// Returns true when the queue is empty.
  bool get isEmpty => _items.isEmpty;
}

/// A queue for fetching system information.
class IdleQueue {
  /// Create a new fetch queue.
  IdleQueue();

  final NonRepeatingQueue<(SystemSymbol, int)> _systems = NonRepeatingQueue(
    (a, b) => a.$2.compareTo(b.$2),
  );
  final NonRepeatingQueue<(WaypointSymbol, int)> _jumpGates = NonRepeatingQueue(
    (a, b) => a.$2.compareTo(b.$2),
  );

  /// Queue a system for fetching.
  void queueSystem(SystemSymbol systemSymbol, {required int jumpDistance}) {
    final queued = _systems.queue((systemSymbol, jumpDistance));
    if (queued) {
      logger.detail('Queued System (${_systems.length}): '
          '$systemSymbol ($jumpDistance)');
    }
  }

  /// Queue jump gate connections for fetching.
  // TODO(eseidel): Jump gate construction completion should call this.
  void queueJumpGateConnections(
    JumpGateRecord jumpGateRecord, {
    required int jumpDistance,
  }) {
    for (final connection in jumpGateRecord.connections) {
      _queueJumpGate(connection, jumpDistance: jumpDistance);
    }
  }

  /// Queue a jump gate for fetching.
  void _queueJumpGate(
    WaypointSymbol waypointSymbol, {
    required int jumpDistance,
  }) {
    final queued = _jumpGates.queue((waypointSymbol, jumpDistance));
    if (queued) {
      logger.detail('Queued JumpGate (${_jumpGates.length}): '
          '$waypointSymbol ($jumpDistance)');
    }
  }

  Future<void> _processNextJumpGate(Api api, Caches caches) async {
    final (to, jumpDistance) = _jumpGates.take();
    logger.detail('Process (${_jumpGates.length}): $to ($jumpDistance)');
    // Make sure we have construction data for the destination before
    // checking if we can jump there.
    final underConstruction = await caches.waypoints.isUnderConstruction(to);
    // Match canJumpTo and check if we can jump from the other side.
    if (!underConstruction) {
      queueSystem(to.systemSymbol, jumpDistance: jumpDistance + 1);
    }
  }

  Future<void> _processNextSystem(Api api, Caches caches) async {
    final (systemSymbol, jumpDistance) = _systems.take();
    logger
        .detail('Process (${_systems.length}): $systemSymbol ($jumpDistance)');
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
        if (!await canJumpFromAsync(
          caches.jumpGates,
          caches.construction,
          from,
        )) {
          continue;
        }
        // Queue each jumpGate as it might fetch construction data which could
        // total to many requests for a single processNextSystem call.
        queueJumpGateConnections(fromRecord, jumpDistance: jumpDistance);
      }
    }
  }

  /// A guess at the minimum time we need to do one loop.
  Duration get minProcessingTime {
    // Systems make about 4 requests.
    return Duration(
      milliseconds: (1000 * config.targetRequestsPerSecond * 4).ceil(),
    );
  }

  /// Run one fetch.
  Future<void> runOne(Api api, Caches caches) async {
    if (isDone) {
      return;
    }
    // Service systems before jumpgates to make a breadth-first search.
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

  @override
  String toString() {
    return 'IdleQueue('
        'systems: ${_systems.length} queued, ${_systems.seenLength} seen; '
        'jumpGates: ${_jumpGates.length} queued, '
        '${_jumpGates.seenLength} seen)';
  }
}
