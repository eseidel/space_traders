import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';

void main(List<String> args) async {
  await run(args, command);
}

Future<void> command(FileSystem fs, Api api, Caches caches) async {
  final hq = await caches.waypoints.getAgentHeadquarters();
  final waypoints = await caches.waypoints.waypointsInSystem(hq.systemSymbol);

  final waypoint = logger.chooseOne(
    'Which waypoint?',
    choices: waypoints,
    display: waypointDescription,
  );

  prettyPrintJson(waypoint.toJson());
}
