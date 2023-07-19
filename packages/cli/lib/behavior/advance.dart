import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/buy_ship.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/explorer.dart';
import 'package:cli/behavior/miner.dart';
import 'package:cli/behavior/trader.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';

/// Advance the behavior of the given ship.
/// Returns the time at which the behavior should be advanced again
/// or null if can be advanced immediately.
Future<DateTime?> advanceShipBehavior(
  Api api,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final behavior = await centralCommand.loadBehaviorState(ship);
  final navResult = await continueNavigationIfNeeded(
    api,
    ship,
    caches.systems,
    centralCommand,
    getNow: getNow,
  );
  if (navResult.shouldReturn()) {
    return navResult.waitTime;
  }

  // shipDetail(ship, 'Advancing behavior: ${behavior.behavior.name}');
  switch (behavior.behavior) {
    case Behavior.buyShip:
      return advanceBuyShip(
        api,
        centralCommand,
        caches,
        ship,
      );
    case Behavior.trader:
      return advanceTrader(
        api,
        centralCommand,
        caches,
        ship,
      );
    case Behavior.miner:
      return advanceMiner(
        api,
        centralCommand,
        caches,
        ship,
      );

    case Behavior.explorer:
      return advanceExplorer(
        api,
        centralCommand,
        caches,
        ship,
      );
    case Behavior.idle:
      shipDetail(ship, 'Idling');
      // Make sure ships don't stay idle forever.
      caches.behaviors.completeBehavior(ship.symbol);
      // Return a time in the future so we don't spin hot.
      return DateTime.now().add(const Duration(minutes: 10));
  }
}
