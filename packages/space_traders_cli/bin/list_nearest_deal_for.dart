import 'package:file/local.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/navigation.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/systems_cache.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

// This should end up sharing code with Deal, Route, etc.
class _Availability {
  const _Availability({
    required this.tradeSymbol,
    required this.marketSymbol,
    required this.sellPrice,
    required this.purchasePrice,
    required this.jumps,
  });
  final String tradeSymbol;
  final String marketSymbol;
  final int purchasePrice;
  final int sellPrice;
  final int jumps;
}

/// Look through nearby marketplaces (including ones a jump away)
/// looking for the best deal for a given symbol.
void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final systemsCache = await SystemsCache.load(fs);
  final waypointCache = WaypointCache(api, systemsCache);

  final priceData = await PriceData.load(fs);

  final promptResponse = logger.prompt(
    'Which trade symbol? (Options: ${TradeSymbol.values.join(', ')}))',
  );

  final tradeSymbol = TradeSymbol.fromJson(promptResponse.toUpperCase().trim());
  if (tradeSymbol == null) {
    logger.err('Invalid trade symbol: "$promptResponse"');
    return;
  }
  // Should start from a ship rather than hq.
  final hq = await waypointCache.getAgentHeadquarters();
  const maxJumps = 5;

  final availabilityList = <_Availability>[];

  await for (final (String system, int jumps) in systemSymbolsInJumpRadius(
    systemsCache: systemsCache,
    startSystem: hq.systemSymbol,
    maxJumps: maxJumps,
  )) {
    for (final marketplaceWaypoint
        in await waypointCache.marketWaypointsForSystem(system)) {
      final prices = priceData
          .sellPricesFor(
            tradeSymbol: tradeSymbol.value,
            marketSymbol: marketplaceWaypoint.symbol,
          )
          .toList();
      if (prices.isEmpty) {
        if (priceData.hasRecentMarketData(marketplaceWaypoint.symbol)) {
          logger.info(
            '${marketplaceWaypoint.symbol} does not have $tradeSymbol.',
          );
        } else {
          logger.info(
            'No recent price data for ${marketplaceWaypoint.symbol}',
          );
        }
        continue;
      }
      availabilityList.add(
        _Availability(
          tradeSymbol: tradeSymbol.value,
          marketSymbol: marketplaceWaypoint.symbol,
          sellPrice: prices.first.sellPrice,
          purchasePrice: prices.first.purchasePrice,
          jumps: jumps,
        ),
      );
    }
  }

  logger.info('Found ${availabilityList.length} deals for $tradeSymbol:');
  availabilityList.sort((a, b) => a.sellPrice.compareTo(b.sellPrice));
  logger.info('symbol - sell - purchase - jumps');
  for (final availability in availabilityList) {
    logger.info(
      '${availability.marketSymbol} - ${availability.sellPrice}'
      ' - ${availability.purchasePrice}'
      ' - ${availability.jumps}',
    );
  }
}
