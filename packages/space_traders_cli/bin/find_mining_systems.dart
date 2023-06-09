// Walk a list of nearby systems, looking for ones which have something
// mineable and a marketplace (ideally at the same location).
// Optionally also a shipyard.

import 'package:args/args.dart';
import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/navigation.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/systems_cache.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'jumps',
      abbr: 'j',
      help: 'Maximum number of jumps to walk out',
      defaultsTo: '10',
    )
    ..addOption(
      'start',
      abbr: 's',
      help: 'Starting system (defaults to agent headquarters)',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Verbose logging',
      negatable: false,
    );
  final results = parser.parse(args);
  final maxJumps = int.parse(results['jumps'] as String);
  if (results['verbose'] as bool) {
    setVerboseLogging();
  }

  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final systemsCache = await SystemsCache.load(fs);
  final waypointCache = WaypointCache(api, systemsCache);

  Waypoint start;
  final startArg = results['start'] as String?;
  if (startArg != null) {
    final maybeStart = await waypointCache.waypointOrNull(startArg);
    if (maybeStart == null) {
      logger.err('--start was invalid, unknown system: ${results['start']}');
      return;
    }
    start = maybeStart;
  } else {
    start = await waypointCache.getAgentHeadquarters();
  }

  await for (final (systemSymbol, jumps) in systemSymbolsInJumpRadius(
    waypointCache: waypointCache,
    startSystem: start.systemSymbol,
    maxJumps: maxJumps,
  )) {
    var hasMarket = false;
    var hasShipyard = false;
    var hasMining = false;
    var marketAndMineTogether = false;
    final waypoints = await waypointCache.waypointsInSystem(systemSymbol);
    for (final waypoint in waypoints) {
      if (waypoint.hasShipyard) {
        hasShipyard = true;
      }
      if (waypoint.hasMarketplace) {
        hasMarket = true;
      }
      if (waypoint.canBeMined) {
        hasMining = true;
      }
      if (waypoint.hasMarketplace && waypoint.canBeMined) {
        marketAndMineTogether = true;
      }
    }
    final market = hasMarket ? 'market ' : '';
    final shipyard = hasShipyard ? 'shipyard ' : '';
    final mining = hasMining ? 'mining ' : '';
    final together = marketAndMineTogether ? 'together ' : '';
    logger.info(
      '$systemSymbol: $jumps jumps $together$market$shipyard$mining',
    );
    // Want to know if the market buys what the mine produces?
  }
}
