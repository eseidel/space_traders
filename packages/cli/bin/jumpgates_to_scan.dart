import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logic/idle_queue.dart';

Future<void> command(Database db, ArgResults argResults) async {
  // Start at the agent's headquarters system.
  // Walk the web of jump gates to find endpoints we should scan.
  final systemSymbol = await myHqSystemSymbol(db);
  final systemsCache = await db.systems.snapshotAllSystems();
  final jumpGateSnapshot = await JumpGateSnapshot.load(db);
  final constructionSnapshot = await db.construction.snapshotAllRecords();
  final chartingSnapshot = await ChartingSnapshot.load(db);

  final systems = NonRepeatingDistanceQueue<SystemSymbol>();
  final jumpGates = NonRepeatingDistanceQueue<WaypointSymbol>();
  final needsJumpgateFetch = <WaypointSymbol>{};
  final needsChart = <WaypointSymbol>{};
  final needsConstructionCheck = <WaypointSymbol>{};
  systems.queue(systemSymbol, 0);

  while (systems.isNotEmpty || jumpGates.isNotEmpty) {
    if (jumpGates.isNotEmpty) {
      final from = jumpGates.take();
      final fromRecord = jumpGateSnapshot.recordForSymbol(from.value);
      if (fromRecord == null) {
        final chartingRecord = chartingSnapshot.getRecord(from.value);
        if (chartingRecord == null) {
          needsChart.add(from.value);
        } else if (chartingRecord.isCharted) {
          needsJumpgateFetch.add(from.value);
        }
        continue;
      }
      if (!canJumpFrom(jumpGateSnapshot, constructionSnapshot, from.value)) {
        continue;
      }
      for (final to in fromRecord.connections) {
        if (!constructionSnapshot.hasRecentData(to)) {
          needsConstructionCheck.add(to);
        } else {
          jumpGates.queue(to, from.jumpDistance + 1);
        }
      }
      continue;
    }
    if (systems.isNotEmpty) {
      final system = systems.take();
      final jumpGate = systemsCache.jumpGateWaypointForSystem(system.value);
      if (jumpGate != null) {
        jumpGates.queue(jumpGate.symbol, system.jumpDistance);
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
}

void main(List<String> args) async {
  await runOffline(args, command);
}
