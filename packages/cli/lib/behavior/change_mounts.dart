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

/// Returns ShipCargoItems for mounts in our cargo if any.
/// Used for getting rid of extra mounts at the end of a change-mounts job.
Iterable<ShipCargoItem> mountsInCargo(Ship ship) sync* {
  for (final cargoItem in ship.cargo.inventory) {
    final isMount = mountSymbolForTradeSymbol(cargoItem.tradeSymbol) != null;
    if (isMount) {
      yield cargoItem;
    }
  }
}

/// Change mounts on a ship.
Future<DateTime?> advanceChangeMounts(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  BehaviorState state,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final toMount = state.mountToAdd;

  // Re-validate every loop in case resuming from error.
  final template = assertNotNull(
    centralCommand.templateForShip(ship),
    'No template.',
    const Duration(hours: 1),
  );
  final needed = mountsToAddToShip(ship, template);
  jobAssert(needed.isNotEmpty, 'No mounts needed.', const Duration(hours: 1));

  // We've already started a change-mount job, continue.
  if (toMount != null) {
    shipInfo(ship, 'Changing mounts. Mounting $toMount.');
    final currentWaypoint =
        await caches.waypoints.waypoint(ship.waypointSymbol);
    if (!currentWaypoint.hasShipyard) {
      shipErr(ship, 'Unexpectedly off course during change mount.');
      state.isComplete = true;
      return null;
    }

    final tradeSymbol = tradeSymbolForMountSymbol(toMount);
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
      toMount,
    );

    // Give the delivery ship our extra mount if we have one.
    final extraMounts = mountsInCargo(ship).toList();
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
    centralCommand.disableBehaviorForShip(
      ship,
      'Mounting complete.',
      const Duration(hours: 1),
    );
    return null;
  }

  final hqSystem = caches.agent.headquartersSymbol.systemSymbol;
  final hqWaypoints = await caches.waypoints.waypointsInSystem(hqSystem);
  final shipyard = assertNotNull(
    hqWaypoints.firstWhereOrNull((w) => w.hasShipyard),
    'No shipyard in $hqSystem',
    const Duration(days: 1),
  );
  final shipyardSymbol = shipyard.waypointSymbol;

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

  // Go to the shipyard.
  final waitUntil = beingNewRouteAndLog(
    api,
    ship,
    state,
    caches.ships,
    caches.systems,
    caches.routePlanner,
    centralCommand,
    shipyardSymbol,
  );
  return waitUntil;
}
