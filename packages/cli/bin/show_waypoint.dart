import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';

void main(List<String> args) async {
  await runWithArgs(args, command);
}

Future<void> command(
  List<String> args,
  FileSystem fs,
  Api api,
  Caches caches,
) async {
  final hq = caches.agent.headquarters(caches.systems);
  final systemSymbol = args.firstOrNull ?? hq.systemSymbol;
  final waypointFetcher =
      WaypointFetcher(api, caches.waypoints, caches.systems);
  final waypoints = await waypointFetcher.waypointsInSystem(systemSymbol);

  final waypoint = logger.chooseOne(
    'Which waypoint?',
    choices: waypoints,
    display: waypointDescription,
  );

  prettyPrintJson(waypoint.toJson());
}
