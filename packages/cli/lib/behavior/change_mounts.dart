import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/deliver.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/printing.dart';
import 'package:collection/collection.dart';
import 'package:more/collection.dart';

ShipMountSymbolEnum? _pickMountFromAvailable(
  Multiset<ShipMountSymbolEnum> available,
  Multiset<ShipMountSymbolEnum> needed,
) {
  // We could do something more sophisticated here.
  return needed.firstWhereOrNull((mount) => available[mount] > 0);
}

/// Remove mount from a ship's mount list (but not cargo).
Future<RemoveMount201ResponseData> removeMount(
  Api api,
  AgentCache agentCache,
  ShipCache shipCache,
  TransactionLog transactionLog,
  Ship ship,
  ShipMountSymbolEnum tradeSymbol,
) async {
  final response = await api.fleet.removeMount(
    ship.symbol,
    removeMountRequest: RemoveMountRequest(symbol: tradeSymbol.value),
  );
  final data = response!.data;
  agentCache.agent = data.agent;
  ship
    ..cargo = data.cargo
    ..mounts = data.mounts;
  await shipCache.updateShip(ship);
  logShipModificationTransaction(ship, agentCache.agent, data.transaction);
  final transaction = Transaction.fromShipModificationTransaction(
    data.transaction,
    agentCache.agent.credits,
  );
  transactionLog.log(transaction);
  return data;
}

/// Install a mount on a ship from its cargo.
Future<InstallMount201ResponseData> installMount(
  Api api,
  AgentCache agentCache,
  ShipCache shipCache,
  TransactionLog transactionLog,
  Ship ship,
  ShipMountSymbolEnum tradeSymbol,
) async {
  final response = await api.fleet.installMount(
    ship.symbol,
    installMountRequest: InstallMountRequest(symbol: tradeSymbol.value),
  );
  final data = response!.data;
  agentCache.agent = data.agent;
  ship
    ..cargo = data.cargo
    ..mounts = data.mounts;
  await shipCache.updateShip(ship);
  logShipModificationTransaction(ship, agentCache.agent, data.transaction);
  final transaction = Transaction.fromShipModificationTransaction(
    data.transaction,
    agentCache.agent.credits,
  );
  transactionLog.log(transaction);
  return data;
}

/// Transfer cargo between two ships.
Future<Jettison200ResponseData> transferCargo(
  Api api,
  ShipCache cache, {
  required Ship from,
  required Ship to,
  required TradeSymbol tradeSymbol,
  required int units,
}) async {
  final request = TransferCargoRequest(
    shipSymbol: to.symbol,
    tradeSymbol: tradeSymbol,
    units: 1,
  );
  final response = await api.fleet.transferCargo(
    from.symbol,
    transferCargoRequest: request,
  );
  // On failure:
  // ApiException 400: {"error":{"message":
  // "Failed to update ship cargo. Ship ESEIDEL-1 cargo does not contain 1
  // unit(s) of MOUNT_MINING_LASER_II. Ship has 0 unit(s) of
  // MOUNT_MINING_LASER_II.","code":4219,"data":{"shipSymbol":"ESEIDEL-1",
  // "tradeSymbol":"MOUNT_MINING_LASER_II","cargoUnits":0,"unitsToRemove":1}}}

  final data = response!.data;
  from.cargo = data.cargo;
  to.updateCacheWithAddedCargo(tradeSymbol, units);
  await cache.updateShip(from);
  await cache.updateShip(to);
  return data;
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

  shipInfo(ship, 'Changing mounts. Mounting $toMount.');

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

  // We've already started a change-mount job, continue.
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
      shipErr(ship, 'Delivery ship undocked during change mount, docking it.');
      // Terrible hack.
      await dockIfNeeded(api, fromShip);
      // centralCommand.completeBehavior(ship.shipSymbol);
      // return null;
    }

    await dockIfNeeded(api, ship);

    if (ship.countUnits(tradeSymbol) < 1) {
      // Get it from the delivery ship.
      await transferCargo(
        api,
        caches.ships,
        from: fromShip,
        to: ship,
        tradeSymbol: tradeSymbol,
        units: 1,
      );
    }

    // Unmount existing mounts if needed.
    // const toBeRemoved = TradeSymbol.MOUNT_MINING_LASER_I;
    // await api.fleet.removeMount(
    //   ship.symbol,
    //   removeMountRequest: RemoveMountRequest(symbol: toBeRemoved.value),
    // );

    // Mount the new mount.
    await installMount(
      api,
      caches.agent,
      caches.ships,
      caches.transactions,
      ship,
      toMount,
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
