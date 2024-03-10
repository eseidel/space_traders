import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/plan/market_scores.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  // A slot is defined as the number of deals available from a example waypoint
  // within a system (probably the jumpgate), above a certain c/s threshold.
  // Slots are the same for all ship types, just better ships get first pick.

  // findBetterTradeLocation used to use "Market scores" to find systems
  // worth trading in.  It would avoid any system which already had a trader.

  // First figure out if we have any traders needing reassignment.
  // If so, compute possible trades for systems near them with markets?

  // First need to figure out which systems are worth checking.

  final systems = SystemsCache.load(fs);
  final systemConnectivity = await loadSystemConnectivity(db);
  final marketPrices = await MarketPriceSnapshot.load(db);
  final agentCache = await AgentCache.load(db);
  final contractSnapshot = await ContractSnapshot.load(db);
  final marketListings = await MarketListingSnapshot.load(db);
  final routePlanner = RoutePlanner.fromSystemsCache(
    systems!,
    systemConnectivity,
    sellsFuel: defaultSellsFuel(marketListings),
  );

  final behaviors = await BehaviorSnapshot.load(db);
  final ships = await ShipSnapshot.load(db);
  final idleHaulers = behaviors.idleHaulerSymbols(ships);
  logger.info('Idle haulers: ${idleHaulers.length}');
  final centralCommand = CentralCommand();

  final avoidSystems = <SystemSymbol>{};

  for (final shipSymbol in idleHaulers) {
    final ship = ships[shipSymbol];

    final location = findBetterTradeLocation(
      systems,
      systemConnectivity,
      marketPrices,
      findDeal: (Ship ship, WaypointSymbol startSymbol) {
        return centralCommand.findNextDealAndLog(
          agentCache!,
          contractSnapshot,
          marketPrices,
          systems,
          systemConnectivity,
          routePlanner,
          behaviors,
          ship,
          overrideStartSymbol: startSymbol,
          maxTotalOutlay: agentCache.agent.credits,
        );
      },
      ship,
      avoidSystems: avoidSystems,
      profitPerSecondThreshold: centralCommand.expectedCreditsPerSecond(ship),
    );
    logger.info('Ship $shipSymbol: $location');
    if (location != null) {
      avoidSystems.add(location.system);
    }
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
