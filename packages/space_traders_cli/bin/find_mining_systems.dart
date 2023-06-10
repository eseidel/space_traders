// Walk a list of nearby systems, looking for ones which have something
// mineable and a marketplace (ideally at the same location).
// Optionally also a shipyard.

import 'package:args/args.dart';
import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/navigation.dart';
import 'package:space_traders_cli/behavior/trading.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/systems_cache.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

/// Want to find systems which have both a mineable resource and a marketplace.
/// Want to sort by distance between the two.
/// As well as relative prices for the market.
/// Might also want to consider what resources the mine produces and if the
/// market buys them.

// class MineAndSell {
//   MineAndSell({
//     required this.mineSymbol,
//     required this.marketSymbol,
//     required this.jumps,
//     required this.marketPercentile,
//   });

//   final String mineSymbol;
//   final String marketSymbol;
//   final int jumps;
//   final int marketPercentile;
// }

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
  final marketCache = MarketCache(waypointCache);
  final priceData = await PriceData.load(fs);

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

  const tradeSymbol = 'ICE_WATER';

  // final candidates = <MineAndSell>[];

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
    // final markets = waypoints.where((w) => w.hasMarketplace);
    // final mines = waypoints.where((w) => w.canBeMined);

    for (final waypoint in waypoints) {
      if (waypoint.hasShipyard) {
        hasShipyard = true;
      }
      if (waypoint.hasMarketplace) {
        hasMarket = true;
        final market = await marketCache.marketForSymbol(waypoint.symbol);
        final sellPrice = estimateSellPrice(priceData, market!, tradeSymbol);
        if (sellPrice != null) {
          final priceDeviance = stringForPriceDeviance(
            priceData,
            tradeSymbol,
            sellPrice,
            MarketTransactionTypeEnum.SELL,
          );
          final priceString = creditsString(sellPrice);
          logger.info(
            '${waypoint.symbol}: $priceString $priceDeviance of $tradeSymbol',
          );
        }
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
