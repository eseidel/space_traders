import 'package:cli/caches.dart';
import 'package:cli/cli.dart';

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

  final unreachableSystems = systemsToWatch
      .where(
        (systemSymbol) =>
            systemConnectivity.clusterIdForSystem(systemSymbol) !=
            mainClusterId,
      )
      .toList();

  // Look check all systems within 800 units of an unreachable system for
  // a reachable system.
  for (final systemSymbol in unreachableSystems) {
    final system = systemsCache[systemSymbol];
    final nearbySystems = systemsCache.systems
        .where((s) => s.symbol != systemSymbol && s.distanceTo(system) < 800);
    if (nearbySystems.isEmpty) {
      logger.info('No nearby systems for $systemSymbol');
      continue;
    }
    logger.info('Nearby systems for $systemSymbol:');
    for (final nearbySystem in nearbySystems) {
      final distance = system.distanceTo(nearbySystem).round().toString();
      final near = nearbySystem.symbol.systemName;
      logger.info(' ${distance.padLeft(3)} to $near');
    }
  }
}
