import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli/nav/navigation.dart';

void main(List<String> args) async {
  await runOffline(args, command);
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  // Systems to visit:
  final marketListings = await MarketListingSnapshot.load(db);
  final systemsToWatch = marketListings.systemsWithAtLeastNMarkets(5);

  final systemsCache = SystemsCache.load(fs)!;
  final ships = await ShipSnapshot.load(db);

  // Find ones not in our main cluster.
  final systemConnectivity = await loadSystemConnectivity(db);
  final mainClusterId = systemConnectivity.clusterIdForSystem(
    ships.ships.first.systemSymbol,
  );

  final routePlanner = RoutePlanner.fromSystemsCache(
    systemsCache,
    systemConnectivity,
    sellsFuel: defaultSellsFuel(marketListings),
  );

  final explorer = ships.ships.firstWhere((s) => s.isExplorer);

  final unreachableSystems = systemsToWatch
      .where(
        (systemSymbol) =>
            systemConnectivity.clusterIdForSystem(systemSymbol) !=
            mainClusterId,
      )
      .toList();

  // Look check all systems within 800 units of an unreachable system for
  // a reachable system.
  const maxFuel = 800;

  for (final systemSymbol in unreachableSystems) {
    final system = systemsCache[systemSymbol];
    final nearbySystems = systemsCache.systems.where(
      (s) => s.symbol != systemSymbol && s.distanceTo(system) < maxFuel,
    );
    if (nearbySystems.isEmpty) {
      logger.info('No nearby systems for $systemSymbol');
      continue;
    }
    logger.info('Nearby systems for $systemSymbol:');
    for (final nearbySystem in nearbySystems) {
      final distance = system.distanceTo(nearbySystem).round().toString();
      final near = nearbySystem.symbol.systemName;

      // Figure out the time to route from current location to the jumpgate
      // for nearbySystem.
      final jumpGate = nearbySystem.jumpGateWaypoints.first;
      final route = routePlanner.planRoute(
        explorer.shipSpec,
        start: explorer.waypointSymbol,
        end: jumpGate.symbol,
      );
      final duration = approximateDuration(route!.duration);
      logger.info(' ${distance.padLeft(3)} to $near ($duration)');
    }
  }
}
