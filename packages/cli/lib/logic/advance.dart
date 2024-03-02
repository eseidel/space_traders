import 'package:cli/behavior/job.dart';
import 'package:cli/behavior/buy_ship.dart';
import 'package:cli/behavior/charter.dart';
import 'package:cli/behavior/miner.dart';
import 'package:cli/behavior/miner_hauler.dart';
import 'package:cli/behavior/mount_from_buy.dart';
import 'package:cli/behavior/siphoner.dart';
import 'package:cli/behavior/surveyor.dart';
import 'package:cli/behavior/system_watcher.dart';
import 'package:cli/behavior/trader.dart';
import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/exceptions.dart';
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
  return DateTime.timestamp().add(const Duration(minutes: 10));
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
    case Behavior.siphoner:
      return advanceSiphoner;
    case Behavior.miner:
      return advanceMiner;
    case Behavior.surveyor:
      return advanceSurveyor;
    case Behavior.minerHauler:
      return advanceMinerHauler;
    case Behavior.systemWatcher:
      return advanceSystemWatcher;
    case Behavior.charter:
      return advanceCharter;
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
  final state = await createBehaviorIfAbsent(db, ship.shipSymbol, () async {
    final credits = caches.agent.agent.credits;
    return centralCommand.getJobForShip(db, ship, credits);
  });

  final NavResult navResult;
  try {
    navResult = await continueNavigationIfNeeded(
      api,
      db,
      centralCommand,
      caches,
      ship,
      state,
      getNow: getNow,
    );
  } on JobException catch (e) {
    shipErr(ship, '$e');
    await db.deleteBehaviorState(ship.shipSymbol);
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
      await db.deleteBehaviorState(ship.shipSymbol);
    } else {
      // Otherwise update the behavior state.
      await db.setBehaviorState(state);
    }
    return waitUntil;
  } on JobException catch (error) {
    await centralCommand.behaviorTimeouts.disableBehaviorForShip(
      db,
      ship,
      error.message,
      error.timeout,
    );
  } on ApiException catch (e) {
    if (!isInsufficientCreditsException(e)) {
      rethrow;
    }
    await centralCommand.behaviorTimeouts.disableBehaviorForShip(
      db,
      ship,
      'Insufficient credits: ${e.message}',
      const Duration(minutes: 10),
    );
  }
  return null;
}
