// Goes to the location it's been told to.
// Waits until full.
// Sells goods for the best price it can.

import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/miner.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// Go wait to be filled by miners.
Future<JobResult> goWaitForGoods(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final mineJob =
      assertNotNull(state.mineJob, 'No mine job.', const Duration(hours: 1));
  final mineSymbol = mineJob.mine;

  if (ship.waypointSymbol != mineSymbol) {
    final waitTime = await beingNewRouteAndLog(
      api,
      db,
      centralCommand,
      caches,
      ship,
      state,
      mineSymbol,
    );
    return JobResult.wait(waitTime);
  }

  // Transfering goods requires being the same orbit state.
  await undockIfNeeded(api, caches.ships, ship);

  // If we're not yet full, go to sleep for a minute.
  if (ship.cargo.availableSpace > 0) {
    return JobResult.wait(getNow().add(const Duration(minutes: 1)));
  }
  return JobResult.complete();
}

/// Init the MineJob for the miner hauler.
Future<JobResult> _initMineJob(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final mineJob = await centralCommand.mineJobForShip(
    caches.waypoints,
    caches.marketListings,
    caches.agent,
    ship,
  );
  state.mineJob = mineJob;
  return JobResult.complete();
}

/// Advance the miner hauler.
final advanceMinerHauler = const MultiJob('MinerHauler', [
  _initMineJob,
  emptyCargoIfNeededForMining,
  goWaitForGoods,
  sellCargoIfNeeded,
]).run;