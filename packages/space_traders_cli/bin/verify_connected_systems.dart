import 'package:collection/collection.dart';
import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/systems_cache.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

// void printConnectedSystems(List<ConnectedSystem> connectedSystems) {
//   for (final system in connectedSystems) {
//     logger.info('${system.symbol} - ${system.distance}');
//   }
// }

bool compareConnectedSystemsLists(
  List<ConnectedSystem> jumpGateConnecteSystems,
  List<ConnectedSystem> cacheConnectedSystems,
) {
  var listsAreEqual = true;
  // Walk through the two lists and print any differences
  final seenSymbols = <String>{};
  for (final system in jumpGateConnecteSystems) {
    seenSymbols.add(system.symbol);
    final cacheSystem = cacheConnectedSystems.firstWhereOrNull(
      (s) => s.symbol == system.symbol,
    );
    if (cacheSystem == null) {
      logger.info('System ${system.symbol} is missing from cache');
      listsAreEqual = false;
    } else if (cacheSystem.distance != system.distance) {
      logger.info(
        'System ${system.symbol} has distance ${system.distance} in api, '
        'but ${cacheSystem.distance} in cache',
      );
      listsAreEqual = false;
    }
  }
  for (final system in cacheConnectedSystems) {
    if (!seenSymbols.contains(system.symbol)) {
      logger.info('System ${system.symbol} is missing from api');
      listsAreEqual = false;
    }
  }
  return listsAreEqual;
}

void main() async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final systemsCache = await SystemsCache.load(fs);
  final waypointCache = WaypointCache(api, systemsCache);
  final hq = await waypointCache.getAgentHeadquarters();
  final jumpGate = await waypointCache.jumpGateForSystem(hq.systemSymbol);
  logger.info('Jump gate range: ${jumpGate!.jumpRange}');
  final jumpGateConnecteSystems = jumpGate.connectedSystems;
  // logger.info('From Jump Gate: ');
  // printConnectedSystems(jumpGateConnecteSystems);

  // fetch connected systems from the api
  // verify that it matches what we compute ourselves from SystemsCache.
  final systemCache = await SystemsCache.load(fs);
  final cacheConnectedSystems = systemCache.connectedSystems(hq.systemSymbol);
  // logger.info('From Cache: ');
  // printConnectedSystems(cacheConnectedSystems);

  if (compareConnectedSystemsLists(
    jumpGateConnecteSystems,
    cacheConnectedSystems,
  )) {
    logger.info('Lists are equal');
  } else {
    logger.info('Lists are not equal');
  }
}