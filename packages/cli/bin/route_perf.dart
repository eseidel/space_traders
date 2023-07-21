import 'package:cli/api.dart';
import 'package:cli/cache/faction_cache.dart';
import 'package:cli/cache/jump_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/nav/system_connectivity.dart';
import 'package:file/file.dart';

void main(List<String> args) async {
  await runOffline(args, command);
}

class Result {
  const Result({
    required this.from,
    required this.to,
    required this.duration,
  });

  final String from;
  final String to;
  final Duration duration;
}

Future<void> command(FileSystem fs, List<String> args) async {
  const count = 5000;

  final systemsCache = SystemsCache.loadCached(fs)!;
  final systemConnectivity = SystemConnectivity.fromSystemsCache(systemsCache);
  final jumpCache = JumpCache();
  final factionCache = FactionCache.loadFromCache(fs)!;
  // COSMIC has always been on the main jumpgate network.
  final faction = factionCache.factionBySymbol(FactionSymbols.COSMIC);
  final systemSymbol = parseWaypointString(faction.headquarters).system;
  final clusterId = systemConnectivity.clusterIdForSystem(systemSymbol);
  final allSystemSymbols =
      systemConnectivity.systemSymbolsByClusterId(clusterId);
  final systemSymbols = allSystemSymbols.take(count).toList();
  final jumpgates = systemSymbols
      .map((s) => systemsCache.jumpGateWaypointForSystem(s)!)
      .toList();

  final planner = RoutePlanner(
    jumpCache: jumpCache,
    systemsCache: systemsCache,
    systemConnectivity: systemConnectivity,
  );

  final results = <Result>[];
  // plan routes between each pair of jumpgates and print the timing.
  for (var i = 0; i < jumpgates.length - 1; i++) {
    final start = jumpgates[i];
    final end = jumpgates[i + 1];
    final routeStart = DateTime.now();
    planner.planRoute(
      start: start,
      end: end,
      fuelCapacity: 1200,
      shipSpeed: 30,
    );
    final routeEnd = DateTime.now();
    final duration = routeEnd.difference(routeStart);
    results.add(
      Result(
        from: start.symbol,
        to: end.symbol,
        duration: duration,
      ),
    );
  }

  // Print the 10 slowest routes.
  results.sort((a, b) => b.duration.compareTo(a.duration));
  for (var i = 0; i < 10; i++) {
    final result = results[i];
    logger.info(
      'Route from ${result.from} to ${result.to} '
      'took ${result.duration.inMilliseconds}ms',
    );
  }
}
