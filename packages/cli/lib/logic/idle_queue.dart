import 'package:cli/cli.dart';
import 'package:cli/config.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/net/queries.dart';
import 'package:collection/collection.dart';

/// Wrapper for a value to add jumpDistance.
class WithDistance<T> {
  /// Create a new wrapper.
  WithDistance(this.value, this.jumpDistance);

  /// The value.
  final T value;

  /// The jumpDistance.
  final int jumpDistance;

  @override
  String toString() => 'WithDistance($value, $jumpDistance)';
}

/// A queue which does not allow items to be queued more than once.
/// Uses WithDistance to track the jumpDistance of each item.
/// Items are sorted by jumpDistance.
class NonRepeatingDistanceQueue<T> {
  /// Create a new queue.
  NonRepeatingDistanceQueue()
    : _queue = PriorityQueue(
        (a, b) => a.jumpDistance.compareTo(b.jumpDistance),
      ),
      _queued = {};

  final PriorityQueue<WithDistance<T>> _queue;
  final Set<T> _queued;
  int _takenCount = 0;

  /// Add an item to the queue.
  bool queue(T item, int jumpDistance) {
    // Everything that's in _taken is also in _queued.
    if (_queued.contains(item)) {
      return false;
    }
    // _queued prevents us from every queuing the same item more than once.
    _queued.add(item);
    // _queue ensures we pull items out in jumpDistance order.
    _queue.add(WithDistance(item, jumpDistance));
    return true;
  }

  /// Take the next item from the queue.
  WithDistance<T> take() {
    final item = _queue.removeFirst();
    // _queued ensures items are only ever added once, so they can also only
    // ever be taken once, thus _takenCount is just an int rather than a set.
    _takenCount += 1;
    return item;
  }

  /// The first item in the queue.
  WithDistance<T> get first => _queue.first;

  /// How many items are in the queue.
  int get length => _queue.length;

  /// How many items have been seen/taken.
  int get seenLength => _takenCount;

  /// Returns true when the queue is not empty.
  bool get isNotEmpty => _queue.isNotEmpty;

  /// Returns true when the queue is empty.
  bool get isEmpty => _queue.isEmpty;
}

/// A queue for fetching system information.
class IdleQueue {
  /// Create a new fetch queue.
  IdleQueue();

  final NonRepeatingDistanceQueue<SystemSymbol> _systems =
      NonRepeatingDistanceQueue();
  final NonRepeatingDistanceQueue<WaypointSymbol> _jumpGates =
      NonRepeatingDistanceQueue();

  /// Queue a system for fetching.
  void queueSystem(SystemSymbol systemSymbol, {required int jumpDistance}) {
    final queued = _systems.queue(systemSymbol, jumpDistance);
    if (queued) {
      // logger.detail('Queued System (${_systems.length}): '
      //     '$systemSymbol ($jumpDistance)');
    }
  }

  /// Queue jump gate connections for fetching.
  // TODO(eseidel): Jump gate construction completion should call this.
  void queueJumpGateConnections(
    JumpGate jumpGate, {
    required int jumpDistance,
  }) {
    for (final connection in jumpGate.connections) {
      _queueJumpGate(connection, jumpDistance: jumpDistance);
    }
  }

  /// Queue a jump gate for fetching.
  void _queueJumpGate(
    WaypointSymbol waypointSymbol, {
    required int jumpDistance,
  }) {
    final queued = _jumpGates.queue(waypointSymbol, jumpDistance);
    if (queued) {
      // logger.detail('Queued JumpGate (${_jumpGates.length}): '
      //     '$waypointSymbol ($jumpDistance)');
    }
  }

  Future<void> _processNextJumpGate(Api api, WaypointCache waypoints) async {
    final record = _jumpGates.take();
    final to = record.value;
    final jumpDistance = record.jumpDistance;
    logger.detail(
      'Gate: $to ($jumpDistance jumps, ${_jumpGates.length} queued)',
    );
    // Make sure we have construction data for the destination before
    // checking if we can jump there.
    final underConstruction = await waypoints.isUnderConstruction(to);
    // Match canJumpTo and check if we can jump from the other side.
    if (!underConstruction) {
      queueSystem(to.system, jumpDistance: jumpDistance + 1);
    }
  }

  Future<void> _processNextSystem(
    Database db,
    Api api,
    WaypointCache waypointCache,
    MarketCache marketCache,
  ) async {
    final systemRecord = _systems.take();
    final systemSymbol = systemRecord.value;
    final jumpDistance = systemRecord.jumpDistance;
    logger.detail(
      'System: $systemSymbol ($jumpDistance jumps, ${_systems.length} queued)',
    );
    final waypoints = await db.systems.waypointsInSystem(systemSymbol);
    for (final waypoint in waypoints) {
      final waypointSymbol = waypoint.symbol;
      if (await waypointCache.hasMarketplace(waypointSymbol)) {
        final listing = await db.marketListings.at(waypointSymbol);
        if (listing == null) {
          logger.info(' Market: $waypointSymbol');
          await marketCache.refreshMarket(waypointSymbol);
        }
      }
      if (await waypointCache.hasShipyard(waypointSymbol)) {
        final listing = await db.shipyardListings.at(waypointSymbol);
        if (listing == null) {
          logger.info(' Shipyard: $waypointSymbol');
          final shipyard = await getShipyard(api, waypointSymbol);
          recordShipyardListing(db, shipyard);
        }
      }

      // Can only fetch jump gates for waypoints which are charted or have
      // a ship there.
      if (waypoint.isJumpGate) {
        if (await waypointCache.isCharted(waypointSymbol)) {
          final fromRecord = await getOrFetchJumpGate(db, api, waypointSymbol);
          // Don't follow links where the source is under construction, but
          // do follow them if the destination is. This will have the effect
          // of loading all the starter systems into our db, even if we can't
          // reach them yet.
          final from = fromRecord.waypointSymbol;
          if (await db.construction.isUnderConstruction(from) ?? true) {
            continue;
          }
          // Queue each jumpGate as it might fetch construction data which could
          // total to many requests for a single processNextSystem call.
          queueJumpGateConnections(fromRecord, jumpDistance: jumpDistance);
        }
      }
    }
  }

  /// A guess at the minimum time we need to do one loop.
  Duration get minProcessingTime {
    // Systems make about 4 requests.
    return Duration(
      milliseconds: (1000 * networkConfig.targetRequestsPerSecond * 4).ceil(),
    );
  }

  /// Run one fetch.
  Future<void> runOne(
    Database db,
    Api api,
    WaypointCache waypointCache,
    MarketCache marketCache,
  ) async {
    if (isDone) {
      return;
    }
    // Service systems before jumpgates to make a breadth-first search.
    if (_systems.isNotEmpty) {
      await _processNextSystem(db, api, waypointCache, marketCache);
      return;
    }
    if (_jumpGates.isNotEmpty) {
      await _processNextJumpGate(api, waypointCache);
      return;
    }
  }

  /// Returns true when the queue is empty.
  bool get isDone => _systems.isEmpty && _jumpGates.isEmpty;

  @override
  String toString() {
    final nextJumpDistance = _systems.isNotEmpty
        ? _systems.first.jumpDistance
        : _jumpGates.isNotEmpty
        ? _jumpGates.first.jumpDistance
        : null;

    return 'IdleQueue('
        'systems: ${_systems.length} queued, ${_systems.seenLength} seen; '
        'jumpGates: ${_jumpGates.length} queued, '
        '${_jumpGates.seenLength} seen, next jump distance: $nextJumpDistance)';
  }
}
