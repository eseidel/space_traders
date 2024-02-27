import 'dart:math';

import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/miner.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/net/exceptions.dart';
import 'package:cli/printing.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// Compute the cooldown time for an extraction by [ship].
int cooldownTimeForSiphon(Ship ship) {
  final power = powerUsedBySiphons(ship);
  return 60 + 10 * power;
}

/// Compute the maximum number of units we can expect from an siphon.
/// Not sure if this is correct, just matching extraction for now?
int maxSiphonedUnits(Ship ship) {
  var siphonStrength = 0;
  var variance = 0;
  for (final mount in ship.mounts) {
    if (kSiphonMountSymbols.contains(mount.symbol)) {
      final strength = mount.strength;
      // We could log here, this should never happen.
      if (strength == null) {
        continue;
      }
      siphonStrength += strength;
      variance += 5;
    }
  }
  return min(siphonStrength + variance, ship.cargo.capacity);
}

/// Tell [ship] to extract resources and log the result.
Future<JobResult> siphonAndLog(
  Api api,
  Database db,
  Ship ship,
  ShipSnapshot ships, {
  required DateTime Function() getNow,
}) async {
  // If we somehow got into a bad state, just complete this job and loop.
  jobAssert(
    ship.availableSpace >= maxSiphonedUnits(ship),
    'Not enough space (${ship.availableSpace}) to siphon '
    '(expecting ${maxSiphonedUnits(ship)})',
    const Duration(minutes: 1),
  );

  try {
    final response = await siphonResources(db, api, ship, ships);
    final yield_ = response.siphon.yield_;
    final cargo = response.cargo;
    final siphonStrength = siphonMountStrength(ship);
    await db.insertExtraction(
      ExtractionRecord(
        shipSymbol: ship.shipSymbol,
        waypointSymbol: ship.waypointSymbol,
        tradeSymbol: yield_.symbol,
        quantity: yield_.units,
        power: siphonStrength,
        surveySignature: null,
        timestamp: getNow(),
      ),
    );
    // Could use TradeSymbol.values.reduce() to find the longest symbol.
    shipDetail(
        ship,
        '🪠  ${yield_.units.toString().padLeft(2)} '
        '${yield_.symbol.value.padRight(18)} '
        '🛢️ ${cargo.units.toString().padLeft(2)}/${cargo.capacity}');

    verifyCooldown(
      ship,
      'Siphon',
      cooldownTimeForSiphon(ship),
      response.cooldown,
    );

    // If we still have space wait the cooldown and continue siphoning.
    if (ship.availableSpace >= maxSiphonedUnits(ship)) {
      return JobResult.wait(response.cooldown.expiration);
    }
    // Complete this job (go sell) if an extraction could overflow our cargo.
    return JobResult.complete();
  } on ApiException catch (e) {
    // https://discord.com/channels/792864705139048469/1168786078866604053
    if (isAPIExceptionWithCode(e, 4228)) {
      shipWarn(ship, 'Spurious cargo warning, retrying.');
      return JobResult.wait(null);
    }
    rethrow;
  }
}

/// Init the SiphonJob (aka MineJob).
Future<JobResult> _initSiphonJob(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final siphonJob = assertNotNull(
    await centralCommand.siphonJobForShip(
      db,
      caches.systems,
      caches.charting,
      caches.agent,
      ship,
    ),
    'Requires a siphon job.',
    const Duration(minutes: 10),
  );
  state.extractionJob = siphonJob;
  return JobResult.complete();
}

/// Execute the Siphon Job (MineJob).
Future<JobResult> doSiphonJob(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final siphonJob = assertNotNull(
    state.extractionJob,
    'No siphon job.',
    const Duration(hours: 1),
  );
  final targetSymbol = siphonJob.source;

  if (ship.waypointSymbol != targetSymbol) {
    final waitTime = await beingNewRouteAndLog(
      api,
      db,
      centralCommand,
      caches,
      ship,
      state,
      targetSymbol,
    );
    return JobResult.wait(waitTime);
  }

  jobAssert(
    await caches.waypoints.canBeSiphoned(ship.waypointSymbol),
    "${ship.waypointSymbol} can't be siphoned.",
    const Duration(hours: 1),
  );

  // Siphoning requires being undocked.
  await undockIfNeeded(db, api, caches.ships, ship);

  // We need to be off cooldown to continue.
  final expiration = ship.cooldown.expiration;
  if (expiration != null && expiration.isAfter(getNow())) {
    final duration = expiration.difference(getNow());
    shipDetail(ship, 'Waiting ${approximateDuration(duration)} on cooldown.');
    return JobResult.wait(expiration);
  }

  final result = await siphonAndLog(
    api,
    db,
    ship,
    caches.ships,
    getNow: getNow,
  );
  return result;
}

/// Attempt to empty cargo if needed, will navigate to a market if needed.
Future<JobResult> emptyCargoIfNeededForSiphoning(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  return emptyCargoIfNeeded(
    state,
    api,
    db,
    centralCommand,
    caches,
    ship,
    minSpaceNeeded: maxSiphonedUnits(ship),
    getNow: getNow,
  );
}

/// Advance the siphoner.
final advanceSiphoner = const MultiJob('Siphoner', [
  _initSiphonJob,
  emptyCargoIfNeededForSiphoning,
  doSiphonJob,
  transferOrSellCargo,
]).run;
