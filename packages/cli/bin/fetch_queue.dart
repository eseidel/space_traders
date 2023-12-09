import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/net/auth.dart';
import 'package:cli/net/queries.dart';

class FetchQueue {
  FetchQueue(this.api, this.db, this.caches);

  final Api api;
  final Database db;
  final Caches caches;
  final List<SystemSymbol> _systems = [];
  final Set<SystemSymbol> _seen = {};

  void queueSystem(SystemSymbol systemSymbol) {
    if (_seen.contains(systemSymbol)) {
      return;
    }
    logger.info('Add: $systemSymbol');
    _systems.add(systemSymbol);
  }

  Future<void> processSystem(SystemSymbol systemSymbol) async {
    logger.info('Process: $systemSymbol');
    _seen.add(systemSymbol);
    final waypoints = await caches.waypoints.waypointsInSystem(systemSymbol);
    for (final waypoint in waypoints) {
      if (waypoint.hasMarketplace) {
        final listing = caches.marketListings
            .marketListingForSymbol(waypoint.waypointSymbol);
        if (listing == null) {
          final market = await getMarket(api, waypoint.waypointSymbol);
          caches.marketListings.addMarket(market);
        }
      }
      // TODO(eseidel): Record Shipyard listings.

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

  Future<void> run() async {
    while (_systems.isNotEmpty) {
      if (_systems.isNotEmpty) {
        final system = _systems.removeLast();
        await processSystem(system);
      }
    }
  }
}

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final api = defaultApi(fs, db, getPriority: () => networkPriorityLow);
  final caches = await Caches.loadOrFetch(fs, api, db);

  final systemSymbol = caches.agent.headquartersSystemSymbol;
  final queue = FetchQueue(api, db, caches)..queueSystem(systemSymbol);
  await queue.run();

  // required or main() will hang
  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
