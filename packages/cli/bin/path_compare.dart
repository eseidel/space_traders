import 'package:cli/api.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/system_pathing.dart';
import 'package:cli/nav/waypoint_pathing.dart';
import 'package:collection/collection.dart';

void main(List<String> args) async {
  await runOffline(args, command);
}

Future<void> command(FileSystem fs, List<String> args) async {
  final systemsCache = SystemsCache.loadCached(fs)!;

  final pathPairs = [
    ['X1-GS75-60911D', 'X1-AF26-74510E'],
    ['X1-ZR9-75906Z', 'X1-YC79-34498D'],
    ['X1-MB51-30537A', 'X1-BC72-95737A'],
    ['X1-B70-19706Z', 'X1-ZH33-52003C'],
    ['X1-UC22-54804B', 'X1-PK64-51356E'],
    ['X1-ST46-41127Z', 'X1-MR68-95269A'],
    ['X1-BM3-91319E', 'X1-CU25-06012C'],
    ['X1-SH58-32806E', 'X1-KM13-63088C'],
    ['X1-YU90-78175C', 'X1-BJ17-37034X'],
    ['X1-DT66-19157X', 'X1-SA20-58176B'],
  ];

  const shipSpeed = 30;
  for (final pair in pathPairs) {
    final start = WaypointSymbol.fromString(pair[0]);
    final end = WaypointSymbol.fromString(pair[1]);
    final waypointPath = findWaypointPath(
      systemsCache,
      start,
      end,
      shipSpeed,
    );
    final jumpsOnly =
        findWaypointPathJumpsOnly(systemsCache, start, end, shipSpeed);
    final matches =
        const ListEquality<WaypointSymbol>().equals(waypointPath, jumpsOnly);
    logger.info('$start -> $end');
    if (matches) {
      logger.info('  matches');
    } else {
      logger
        ..info('  old: $waypointPath')
        ..info('  new: $jumpsOnly');
    }
  }
}
