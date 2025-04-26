import 'package:cli_client/cli_client.dart';
import 'package:client/client.dart';

String statsToString(SystemStats stats) {
  // Save ourselves some typing.
  final s = stats;
  String p(double d) => '${(d * 100).round()}%';

  return '''
Starting from ${s.startSystem}, known reachable:
${s.reachableSystems} systems (${p(s.reachableSystemPercent)} of ${s.totalSystems})
${s.reachableWaypoints} waypoints (${p(s.reachableWaypointPercent)} of ${s.totalWaypoints})
 ${s.chartedWaypoints} charted non-asteroid (${p(s.nonAsteroidChartPercent)})
 ${s.chartedAsteroids} charted asteroid (${p(s.asteroidChartPercent)})
${s.reachableMarkets} markets
${s.reachableShipyards} shipyards
${s.reachableJumpGates} jump gates (${p(s.reachableJumpGatePercent)} of ${s.totalJumpgates})
 ${s.cachedJumpGates} cached
 ${s.chartedJumpGates} charted
''';
}

Future<void> command(BackendClient client, ArgResults argResults) async {
  final systemArg = argResults.rest.firstOrNull;
  final startSystem =
      systemArg != null ? SystemSymbol.fromString(systemArg) : null;

  final stats = await client.getSystemStats(startSystem: startSystem);
  logger.info(statsToString(stats));
}

Future<void> main(List<String> args) async {
  await runAsClient(args, command);
}
