import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/deliver.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:collection/collection.dart';
import 'package:more/collection.dart';

ShipMountSymbolEnum? _pickMountFromAvailable(
  Multiset<ShipMountSymbolEnum> available,
  Multiset<ShipMountSymbolEnum> needed,
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
  CentralCommand centralCommand,
  Caches caches,
  BehaviorState state,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final toMount = centralCommand.getMountToAdd(ship.shipSymbol);

  // Re-validate every loop in case resuming from error.
  final template = centralCommand.templateForShip(ship);
  if (template == null) {
    centralCommand.disableBehaviorForShip(
      ship,
      'No template for ship.',
      const Duration(hours: 1),
    );
    return null;
  }

  final needed = mountsToAddToShip(ship, template);
  if (needed.isEmpty) {
    centralCommand.disableBehaviorForShip(
      ship,
      'No mounts needed.',
      const Duration(hours: 1),
    );
    return null;
  }

  shipInfo(ship, 'Changing mounts. Mounting $toMount.');

  // We've already started a change-mount job, continue.
  if (toMount != null) {
    final currentWaypoint =
        await caches.waypoints.waypoint(ship.waypointSymbol);
    if (!currentWaypoint.hasShipyard) {
      shipErr(ship, 'Unexpectedly off course during change mount.');
      centralCommand.completeBehavior(ship.shipSymbol);
      return null;
    }

    final tradeSymbol = tradeSymbolForMountSymbol(toMount);
    final deliveryShip =
        centralCommand.getDeliveryShip(ship.shipSymbol, tradeSymbol);

    if (deliveryShip == null) {
      centralCommand.disableBehaviorForAll(
        ship,
        'No delivery ship for $tradeSymbol.',
        const Duration(minutes: 10),
      );
      return null;
    }

    // We could match the docking status instead.
    if (!deliveryShip.isDocked) {
      shipErr(ship, 'Delivery ship undocked during change mount, docking it.');
      // Terrible hack.
      await dockIfNeeded(api, caches.ships, deliveryShip);
      // centralCommand.completeBehavior(ship.shipSymbol);
      // return null;
    }

    await dockIfNeeded(api, caches.ships, ship);

    if (ship.countUnits(tradeSymbol) < 1) {
      // Get it from the delivery ship.
      await transferCargoAndLog(
        api,
        caches.ships,
        from: deliveryShip,
        to: ship,
        tradeSymbol: tradeSymbol,
        units: 1,
      );
    }

    // TODO(eseidel): This should only remove mounts if we absolutely need to.
    // This could end up removing mounts before we need to.
    final toRemove = mountsToRemoveFromShip(ship, template);
    if (toRemove.isNotEmpty) {
      // Unmount existing mounts if needed.
      for (final mount in toRemove) {
        await removeMountAndLog(
          api,
          caches.agent,
          caches.ships,
          caches.transactions,
          ship,
          mount,
        );
      }
    }

    // Mount the new mount.
    await installMountAndLog(
      api,
      caches.agent,
      caches.ships,
      caches.transactions,
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
  final shipyard = hqWaypoints.firstWhereOrNull((w) => w.hasShipyard);
  if (shipyard == null) {
    centralCommand.disableBehaviorForShip(
      ship,
      'No shipyard in $hqSystem',
      const Duration(days: 1),
    );
    return null;
  }
  final shipyardSymbol = shipyard.waypointSymbol;

  final available = centralCommand.unclaimedMountsAt(shipyardSymbol);
  // If there is a mount ready for us to claim, claim it?
  // Decide on the mount and "claim" it by saving it in our state.
  final toClaim = _pickMountFromAvailable(available, needed);
  if (toClaim == null) {
    centralCommand.disableBehaviorForShip(
      ship,
      'No unclaimed mounts available at shipyard.',
      const Duration(hours: 1),
    );
    return null;
  }
  centralCommand.claimMount(ship.shipSymbol, toClaim);

  // Go to the shipyard.
  final waitUntil = beingNewRouteAndLog(
    api,
    ship,
    caches.ships,
    caches.systems,
    caches.routePlanner,
    centralCommand,
    shipyardSymbol,
  );
  return waitUntil;
}