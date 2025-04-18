import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:collection/collection.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  // A slot is defined as the number of uncharted adjacent systems to a system.

  // Walk all known jumpgate connections?
  // List all systems on the "to" side that are missing charted non-asteroids?
  // Maybe walk all jumpgate connections and list ones where the "to" side has
  // no chart?

  final systemsCache = SystemsCache.load(fs);
  final jumpGates = await JumpGateSnapshot.load(db);
  final charts = await ChartingSnapshot.load(db);
  final construction = await ConstructionSnapshot.load(db);
  final ships = await ShipSnapshot.load(db);
  final behaviors = await BehaviorSnapshot.load(db);

  final systemConnectivity =
      SystemConnectivity.fromJumpGates(jumpGates, construction);

  final connectedMissingCharts = <SystemSymbol, int>{};
  final connectedProbeCount = <SystemSymbol, int>{};
  final slotCount = <SystemSymbol, int>{};

  SystemSymbol systemForShip(Ship ship) {
    final state = behaviors[ship.symbol];
    final endSystem = state?.routePlan?.endSymbol.system;
    if (endSystem != null) {
      return endSystem;
    }
    return ship.systemSymbol;
  }

  // TODO(eseidel): Use behaviors and consider the route end point.
  final probeCountBySystem =
      ships.ships.where((s) => s.isProbe).groupFoldBy<SystemSymbol, int>(
            systemForShip,
            (count, systemSymbol) => count ?? 0 + 1,
          );

  final agentCache = await AgentCache.load(db);
  final hqSystemSymbol = agentCache!.headquartersSystemSymbol;

  for (final jumpGate in jumpGates.values) {
    final fromSystemSymbol = jumpGate.waypointSymbol.system;
    // Restrict to the main cluster for now.
    if (!systemConnectivity.existsJumpPathBetween(
      hqSystemSymbol,
      fromSystemSymbol,
    )) {
      continue;
    }
    var slots = 0;
    var probesNearby = probeCountBySystem[fromSystemSymbol] ?? 0;
    for (final toSystemSymbol in jumpGate.connectedSystemSymbols) {
      probesNearby += probeCountBySystem[toSystemSymbol] ?? 0;
      final maybeMissingChartCount = connectedMissingCharts[toSystemSymbol];
      if (maybeMissingChartCount != null) {
        if (maybeMissingChartCount > 0) {
          slots += 1;
        }
        continue;
      }
      final toSystem = systemsCache[toSystemSymbol];
      final missingChartCount = toSystem.waypoints
          .where((w) => !w.isAsteroid)
          .where((w) => !(charts.isCharted(w.symbol) ?? false))
          .length;
      connectedMissingCharts[toSystemSymbol] = missingChartCount;
      if (missingChartCount > 0) {
        slots += 1;
      }
    }
    slotCount[fromSystemSymbol] = slots;
    connectedProbeCount[fromSystemSymbol] = probesNearby;
  }

  final sortedSlots =
      slotCount.entries.where((e) => e.value > 0).sortedBy<num>((e) => e.value);

  for (final entry in sortedSlots) {
    final slots = entry.value;
    final probes = connectedProbeCount[entry.key] ?? 0;
    logger.info('${entry.key.systemName} ($slots slots, $probes probes)');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
