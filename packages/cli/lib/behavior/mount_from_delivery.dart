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

extension on Ship {
  /// Returns ShipCargoItems for mounts in our cargo if any.
  /// Used for getting rid of extra mounts at the end of a change-mounts job.
  Iterable<ShipCargoItem> mountsInCargo() sync* {
    for (final cargoItem in cargo.inventory) {
      final isMount = mountSymbolForTradeSymbol(cargoItem.tradeSymbol) != null;
      if (isMount) {
        yield cargoItem;
      }
    }
  }
}

/// Init the change-mounts job.
Future<JobResult> doInitJob(
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
  state.mountToAdd = toClaim;
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
  // TODO(eseidel): Pickup location should be saved in state.
  final hqSystem = caches.agent.headquartersSymbol.systemSymbol;
  final hqWaypoints = await caches.waypoints.waypointsInSystem(hqSystem);
  final shipyard = assertNotNull(
    hqWaypoints.firstWhereOrNull((w) => w.hasShipyard),
    'No shipyard in $hqSystem',
    const Duration(days: 1),
  );
  final shipyardSymbol = shipyard.waypointSymbol;

  if (ship.waypointSymbol != shipyardSymbol) {
    final waitUntil = await beingNewRouteAndLog(
      api,
      ship,
      state,
      caches.ships,
      caches.systems,
      caches.routePlanner,
      centralCommand,
      shipyardSymbol,
    );
    return JobResult.wait(waitUntil);
  }

  final tradeSymbol = tradeSymbolForMountSymbol(state.mountToAdd!);
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
Future<JobResult> doChangeMounts(
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
    state.mountToAdd!,
  );
  return JobResult.complete();
}

/// Give the delivery ship any extra mounts we have.
Future<JobResult> doGiveExtraMounts(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final tradeSymbol = tradeSymbolForMountSymbol(state.mountToAdd!);
  final deliveryShip = assertNotNull(
    centralCommand.getDeliveryShip(ship.shipSymbol, tradeSymbol),
    'No delivery ship for $tradeSymbol.',
    const Duration(minutes: 10),
  );

  // Give the delivery ship our extra mount if we have one.
  final extraMounts = ship.mountsInCargo();
  if (extraMounts.isNotEmpty) {
    // This could send more items than deliveryShip has space for.
    for (final cargoItem in extraMounts) {
      await transferCargoAndLog(
        api,
        caches.ships,
        from: ship,
        to: deliveryShip,
        tradeSymbol: cargoItem.tradeSymbol,
        units: cargoItem.units,
      );
    }
  }

  // We're done.
  state.isComplete = true;
  jobAssert(
    false,
    'Mounting complete!',
    const Duration(hours: 1),
  );
  return JobResult.complete();
}

/// Advance the behavior of the given ship.
final advanceMountFromDelivery = const MultiJob('Mount from Delivery', [
  doInitJob,
  doPickupJob,
  doChangeMounts,
  doGiveExtraMounts,
]).run;
