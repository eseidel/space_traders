import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

ShipMountSymbolEnum? _pickMountFromAvailable(
  MountSymbolSet available,
  MountSymbolSet needed,
) {
  // We could do something more sophisticated here.
  return needed.firstWhereOrNull((mount) => available[mount] > 0);
}

/// Init the change-mounts job.
Future<JobResult> _initMountFromDelivery(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final hqSystem = caches.agent.headquartersSymbol.systemSymbol;
  final hqWaypoints = await caches.waypoints.waypointsInSystem(hqSystem);
  final shipyard = assertNotNull(
    hqWaypoints.firstWhereOrNull((w) => w.hasShipyard),
    'No shipyard in $hqSystem',
    const Duration(days: 1),
  );
  final shipyardSymbol = shipyard.waypointSymbol;

  final template = assertNotNull(
    centralCommand.templateForShip(ship),
    'No template.',
    const Duration(hours: 1),
  );
  final needed = mountsToAddToShip(ship, template);
  jobAssert(needed.isNotEmpty, 'No mounts needed.', const Duration(hours: 1));

  final available = centralCommand.unclaimedMountsAt(shipyardSymbol);
  // If there is a mount ready for us to claim, claim it?
  // Decide on the mount and "claim" it by saving it in our state.
  final toClaim = assertNotNull(
    _pickMountFromAvailable(available, needed),
    'No unclaimed mounts at $shipyardSymbol.',
    const Duration(minutes: 10),
  );
  shipInfo(ship, 'Claiming mount: $toClaim.');
  state
    ..pickupJob = PickupJob(
      tradeSymbol: tradeSymbolForMountSymbol(toClaim),
      waypointSymbol: shipyardSymbol,
    )
    ..mountJob = MountJob(
      mountSymbol: toClaim,
      shipyardSymbol: shipyardSymbol,
    );
  return JobResult.complete();
}

/// Pickup the mount from the delivery ship.
Future<JobResult> doPickupJob(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final pickupJob = assertNotNull(
    state.pickupJob,
    'No pickup job',
    const Duration(hours: 1),
  );
  final pickupLocation = pickupJob.waypointSymbol;
  if (ship.waypointSymbol != pickupLocation) {
    final waitUntil = await beingNewRouteAndLog(
      api,
      ship,
      state,
      caches.ships,
      caches.systems,
      caches.routePlanner,
      centralCommand,
      pickupLocation,
    );
    return JobResult.wait(waitUntil);
  }

  final tradeSymbol = pickupJob.tradeSymbol;
  final deliveryShip = assertNotNull(
    centralCommand.getDeliveryShip(ship.shipSymbol, tradeSymbol),
    'No delivery ship for $tradeSymbol.',
    const Duration(minutes: 10),
  );

  // We could match the docking status instead.
  if (!deliveryShip.isDocked) {
    shipErr(ship, 'Delivery ship undocked during change mount, docking it.');
    // Terrible hack.
    await dockIfNeeded(api, caches.ships, deliveryShip);
  }

  await dockIfNeeded(api, caches.ships, ship);

  if (ship.countUnits(tradeSymbol) < 1) {
    try {
      // Get it from the delivery ship.
      await transferCargoAndLog(
        api,
        caches.ships,
        from: deliveryShip,
        to: ship,
        tradeSymbol: tradeSymbol,
        units: 1,
      );
    } on ApiException catch (e) {
      shipErr(ship, 'Failed to transfer mount: $e');
      jobAssert(
        false,
        'Failed to transfer mount.',
        const Duration(minutes: 10),
      );
    }
  }
  return JobResult.complete();
}

/// Actually change the mounts on the ship.
Future<JobResult> doMountJob(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final mountJob = assertNotNull(
    state.mountJob,
    'No mount job',
    const Duration(hours: 1),
  );

  final template = assertNotNull(
    centralCommand.templateForShip(ship),
    'No template.',
    const Duration(hours: 1),
  );

  final mountLocation = mountJob.shipyardSymbol;
  if (ship.waypointSymbol != mountLocation) {
    final waitUntil = await beingNewRouteAndLog(
      api,
      ship,
      state,
      caches.ships,
      caches.systems,
      caches.routePlanner,
      centralCommand,
      mountLocation,
    );
    return JobResult.wait(waitUntil);
  }

  // TODO(eseidel): This should only remove mounts if we absolutely need to.
  // This could end up removing mounts before we need to.
  final toRemove = mountsToRemoveFromShip(ship, template);
  if (toRemove.isNotEmpty) {
    // Unmount existing mounts if needed.
    for (final mount in toRemove) {
      await removeMountAndLog(
        api,
        db,
        caches.agent,
        caches.ships,
        ship,
        mount,
      );
    }
  }

  // 🛸#6  🔧 MOUNT_MINING_LASER_II on ESEIDEL-6 for 3,600c -> 🏦 89,172c
  // Mount the new mount.
  await installMountAndLog(
    api,
    db,
    caches.agent,
    caches.ships,
    ship,
    mountJob.mountSymbol,
  );
  // We're done.
  state.isComplete = true;
  jobAssert(false, 'Mounting complete!', const Duration(hours: 1));
  return JobResult.complete();
}

/// Advance the behavior of the given ship.
final advanceMountFromDelivery = const MultiJob('Mount from Delivery', [
  _initMountFromDelivery,
  doPickupJob,
  doMountJob,
]).run;
