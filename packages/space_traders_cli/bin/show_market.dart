import 'package:file/local.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final waypointCache = WaypointCache(api);
  final marketCache = MarketCache(waypointCache);

  final hq = await waypointCache.getAgentHeadquarters();
  final marketplaceWaypoints =
      await waypointCache.marketWaypointsForSystem(hq.systemSymbol);

  final waypoint = logger.chooseOne(
    'Which marketplace?',
    choices: marketplaceWaypoints,
    display: waypointDescription,
  );

  final market = await marketCache.marketForSymbol(waypoint.symbol);
  prettyPrintJson(market!.toJson());
}
