import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

// This should end up sharing code with Deal, Route, etc.
class _Availability {
  const _Availability({
    required this.tradeSymbol,
    required this.marketSymbol,
    required this.sellPrice,
    required this.jumps,
  });
  final String tradeSymbol;
  final String marketSymbol;
  final int sellPrice;
  final int jumps;
}

Stream<_Availability> _availabilityInSystem(
  Api api,
  PriceData priceData,
  List<Waypoint> systemWaypoints,
  TradeSymbol tradeSymbol,
  int jumps,
) async* {
  final marketplaceWaypoints =
      systemWaypoints.where((w) => w.hasMarketplace).toList();

  for (final marketplaceWaypoint in marketplaceWaypoints) {
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
    yield _Availability(
      tradeSymbol: tradeSymbol.value,
      marketSymbol: marketplaceWaypoint.symbol,
      sellPrice: prices.first.sellPrice,
      jumps: jumps,
    );
  }
}

/// Look through nearby marketplaces (including ones a jump away)
/// looking for the best deal for a given symbol.
void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final waypointCache = WaypointCache(api);

  final priceData = await PriceData.load(fs);

  final promptResponse = logger.prompt(
    'Which trade symbol? (Options: ${TradeSymbol.values.join(', ')}))',
  );

  final tradeSymbol = TradeSymbol.fromJson(promptResponse.toUpperCase().trim());
  if (tradeSymbol == null) {
    logger.err('Invalid trade symbol');
    return;
  }
  final hq = await waypointCache.getAgentHeadquarters();
  final systemWaypoints =
      await waypointCache.waypointsInSystem(hq.systemSymbol);

  final availabilityList = <_Availability>[
    ...await _availabilityInSystem(
      api,
      priceData,
      systemWaypoints,
      tradeSymbol,
      0,
    ).toList(),
  ];

  await for (final system in waypointCache.connectedSystems(hq.systemSymbol)) {
    logger.info('${system.symbol} - ${system.distance}');
    final waypoints = await waypointCache.waypointsInSystem(system.symbol);
    availabilityList.addAll(
      await _availabilityInSystem(
        api,
        priceData,
        waypoints,
        tradeSymbol,
        1,
      ).toList(),
    );
  }

  availabilityList.sort((a, b) => a.sellPrice.compareTo(b.sellPrice));
  for (final availability in availabilityList) {
    logger.info(
      '${availability.marketSymbol} - ${availability.sellPrice}'
      ' - ${availability.jumps}',
    );
  }
}
