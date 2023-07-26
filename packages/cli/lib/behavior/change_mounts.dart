import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/deliver.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:collection/collection.dart';

ShipMountSymbolEnum? _pickMountFromAvailable(
  Map<ShipMountSymbolEnum, int> available,
  Map<ShipMountSymbolEnum, int> needed,
) {
  for (final mount in needed.keys) {
    final availableCount = available[mount] ?? 0;
    if (availableCount > 0) {
      return mount;
    }
  }
  return null;
}

/// Change mounts on a ship.
Future<DateTime?> advanceChangeMounts(
  Api api,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final toMount = centralCommand.getMountToAdd(ship.shipSymbol);

  if (toMount != null) {
    final currentWaypoint =
        await caches.waypoints.waypoint(ship.waypointSymbol);
    if (!currentWaypoint.hasShipyard) {
      shipErr(ship, 'Unexpectedly off course during change mount.');
      centralCommand.completeBehavior(ship.shipSymbol);
      return null;
    }

    final tradeSymbol = tradeSymbolForMountSymbol(toMount)!;
    final fromShip =
        centralCommand.getDeliveryShip(ship.shipSymbol, tradeSymbol);

    if (fromShip == null) {
      centralCommand.disableBehaviorForAll(
        ship,
        'No delivery ship for $tradeSymbol.',
        const Duration(minutes: 10),
      );
      return null;
    }

    // We could match the docking status instead.
    if (!fromShip.isDocked) {
      shipErr(ship, 'Delivery ship undocked during change mount.');
      centralCommand.completeBehavior(ship.shipSymbol);
      return null;
    }

    await dockIfNeeded(api, ship);

    // Get it from the delivery ship.
    final request = TransferCargoRequest(
      shipSymbol: ship.symbol,
      tradeSymbol: tradeSymbol,
      units: 1,
    );
    await api.fleet.transferCargo(
      fromShip.symbol,
      transferCargoRequest: request,
    );

    // Unmount existing mounts if needed.
    // const toBeRemoved = TradeSymbol.MOUNT_MINING_LASER_I;
    // await api.fleet.removeMount(
    //   ship.symbol,
    //   removeMountRequest: RemoveMountRequest(symbol: toBeRemoved.value),
    // );

    // Mount the new mount.
    await api.fleet.installMount(
      ship.symbol,
      installMountRequest: InstallMountRequest(symbol: tradeSymbol.value),
    );

    // Give the delivery ship our extra mount if we have one.

    // We're done.
    centralCommand.disableBehaviorForShip(
      ship,
      'Mounting complete.',
      const Duration(hours: 1),
    );
    return null;
  }

  // Do I need mounts?
  final template = centralCommand.templateForShip(ship);
  if (template == null) {
    centralCommand.disableBehaviorForShip(
      ship,
      'No template for ship.',
      const Duration(hours: 1),
    );
    return null;
  }

  final needed = mountsNeededForShip(ship, template);
  if (needed.isEmpty) {
    centralCommand.disableBehaviorForShip(
      ship,
      'No mounts needed.',
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
    caches.systems,
    caches.routePlanner,
    centralCommand,
    shipyardSymbol,
  );
  return waitUntil;
}
