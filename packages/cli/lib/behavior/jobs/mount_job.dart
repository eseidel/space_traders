import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

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
      db,
      centralCommand,
      caches,
      ship,
      state,
      mountLocation,
    );
    return JobResult.wait(waitUntil);
  }

  // We must be docked at the shipyard to mount.
  await dockIfNeeded(api, caches.ships, ship);

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

  final needed = mountsToAddToShip(ship, template);
  jobAssert(
    needed.contains(mountJob.mountSymbol),
    'Ship does not need ${mountJob.mountSymbol}?',
    const Duration(minutes: 10),
  );

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
  // Add the new mount to our static_data cache in case it's new to us.
  recordShip(caches.static, ship);
  // We're done.
  state.isComplete = true;
  shipInfo(ship, 'Mounted ${mountJob.mountSymbol}.');
  return JobResult.complete();
}
