import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/idle_queue.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  // Start at the agent's headquarters system.
  // Walk the web of jump gates to find endpoints we should scan.
  final db = await defaultDatabase();
  final agentCache = AgentCache.load(fs)!;
  final systemSymbol = agentCache.headquartersSystemSymbol;
  final systemsCache = SystemsCache.load(fs)!;
  final jumpGateCache = JumpGateCache.load(fs);
  final constructionSnapshot = await ConstructionSnapshot.load(db);
  final waypointTraits = WaypointTraitCache.load(fs);
  final chartingCache = ChartingCache.load(fs, waypointTraits);

  final systems = NonRepeatingQueue<SystemSymbol>();
  final jumpGates = NonRepeatingQueue<WaypointSymbol>();
  final needsJumpgateFetch = <WaypointSymbol>{};
  final needsChart = <WaypointSymbol>{};
  final needsConstructionCheck = <WaypointSymbol>{};
  systems.queue(systemSymbol);

  while (systems.isNotEmpty || jumpGates.isNotEmpty) {
    if (jumpGates.isNotEmpty) {
      final from = jumpGates.take();
      final fromRecord = jumpGateCache.recordForSymbol(from);
      if (fromRecord == null) {
        final chartingRecord = chartingCache.getRecord(from);
        if (chartingRecord == null) {
          needsChart.add(from);
        } else if (chartingRecord.isCharted) {
          needsJumpgateFetch.add(from);
        }
        continue;
      }
      if (!canJumpFrom(jumpGateCache, constructionSnapshot, from)) {
        continue;
      }
      for (final to in fromRecord.connections) {
        if (!constructionSnapshot.hasRecentData(to)) {
          needsConstructionCheck.add(to);
        } else {
          jumpGates.queue(to);
        }
      }
      continue;
    }
    if (systems.isNotEmpty) {
      final system = systems.take();
      final systemRecord = systemsCache[system];
      for (final waypoint in systemRecord.waypoints) {
        if (waypoint.isJumpGate) {
          jumpGates.queue(waypoint.waypointSymbol);
        }
      }
    }
  }
  logger.info('${needsJumpgateFetch.length} gates charted but not fetched');
  for (final waypoint in needsJumpgateFetch) {
    logger.info('  $waypoint');
  }

  logger.info('${needsChart.length} gates to visit');
  for (final waypoint in needsChart) {
    logger.info('  $waypoint');
  }

  logger.info(
    '${needsConstructionCheck.length} jumpgates to check for construction',
  );
  for (final waypoint in needsConstructionCheck) {
    logger.info('  $waypoint');
  }

  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
