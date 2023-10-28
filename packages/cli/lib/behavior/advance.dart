import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/buy_ship.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/explorer.dart';
import 'package:cli/behavior/miner.dart';
import 'package:cli/behavior/mount_from_buy.dart';
import 'package:cli/behavior/surveyor.dart';
import 'package:cli/behavior/trader.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

Future<DateTime?> _advanceIdle(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  BehaviorState state,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  shipDetail(ship, 'Idling');
  // Make sure ships don't stay idle forever.
  state.isComplete = true;
  // Return a time in the future so we don't spin hot.
  return DateTime.now().add(const Duration(minutes: 10));
}

Future<DateTime?> Function(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  BehaviorState state,
  Ship ship, {
  DateTime Function() getNow,
}) _behaviorFunction(Behavior behavior) {
  switch (behavior) {
    case Behavior.buyShip:
      return advanceBuyShip;
    case Behavior.trader:
      return advanceTrader;
    case Behavior.miner:
      return advanceMiner;
    case Behavior.surveyor:
      return advanceSurveyor;
    case Behavior.explorer:
      return advanceExplorer;
    case Behavior.mountFromBuy:
      return advanceMountFromBuy;
    case Behavior.idle:
      return _advanceIdle;
  }
}

/// Advance the behavior of the given ship.
/// Returns the time at which the behavior should be advanced again
/// or null if can be advanced immediately.
Future<DateTime?> advanceShipBehavior(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final state =
      await centralCommand.loadBehaviorState(ship, caches.agent.agent.credits);

  final NavResult navResult;
  try {
    navResult = await continueNavigationIfNeeded(
      api,
      ship,
      state,
      caches.ships,
      caches.systems,
      centralCommand,
      getNow: getNow,
    );
  } on NavigationException catch (e) {
    logger.err('Error advancing ship behavior: $e');
    caches.behaviors.deleteBehavior(ship.shipSymbol);
    return null;
  }
  if (navResult.shouldReturn()) {
    return navResult.waitTime;
  }

  // shipDetail(ship, 'Advancing behavior: ${behavior.behavior.name}');
  final behaviorFunction = _behaviorFunction(state.behavior);
  try {
    final waitUntil = await behaviorFunction(
      api,
      db,
      centralCommand,
      caches,
      state,
      ship,
      getNow: getNow,
    );
    if (state.isComplete) {
      // If the behavior is complete, clear it.
      caches.behaviors.deleteBehavior(ship.shipSymbol);
    } else {
      // Otherwise update the behavior state.
      caches.behaviors.setBehavior(ship.shipSymbol, state);
    }
    return waitUntil;
  } on JobException catch (error) {
    caches.behaviors.disableBehaviorForShip(
      ship,
      error.message,
      error.timeout,
    );
  }
  return null;
}
