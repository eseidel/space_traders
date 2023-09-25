import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/deliver.dart';
import 'package:cli/behavior/mount_from_delivery.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/trading.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// Generates a buy job for the first mount we know how to find a buy job for.
BuyJob? _buyJobForMount(
  MountSymbolSet needed,
  MarketPrices marketPrices,
  RoutePlanner routePlanner,
  Ship ship, {
  required int expectedCreditsPerSecond,
}) {
  // Walk through the needed mounts.  Find the first one we have a known
  // buy location for.
  for (final mount in needed) {
    final tradeSymbol = tradeSymbolForMountSymbol(mount);
    final marketTrip = findBestMarketToBuy(
      marketPrices,
      routePlanner,
      ship,
      tradeSymbol,
      expectedCreditsPerSecond: expectedCreditsPerSecond,
    );
    if (marketTrip != null) {
      return BuyJob(
        tradeSymbol: tradeSymbol,
        units: 1,
        buyLocation: marketTrip.route.endSymbol,
      );
    }
  }
  return null;
}

/// Init the mount-from-buy job.
Future<JobResult> _initMountFromBuy(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final template = assertNotNull(
    centralCommand.templateForShip(ship),
    'No template.',
    const Duration(hours: 1),
  );
  final needed = mountsToAddToShip(ship, template);
  jobAssert(needed.isNotEmpty, 'No mounts needed.', const Duration(hours: 1));

  final buyJob = assertNotNull(
    _buyJobForMount(
      needed,
      caches.marketPrices,
      caches.routePlanner,
      ship,
      expectedCreditsPerSecond: centralCommand.expectedCreditsPerSecond(ship),
    ),
    'No buy job for mounts.',
    const Duration(minutes: 10),
  );
  state.buyJob = buyJob;
  return JobResult.complete();
}

/// Advance the behavior of the given ship.
final advanceMountFromBuy = const MultiJob('Mount from Buy', [
  _initMountFromBuy,
  doBuyJob,
  doMountJob,
]).run;
