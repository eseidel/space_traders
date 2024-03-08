import 'package:cli/caches.dart';
import 'package:cli/cli.dart';

// count the number of idle behaviors by FleetRole.
Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final ships = await ShipSnapshot.load(db);
  final behaviors = await BehaviorSnapshot.load(db);
  final idleByRole = <FleetRole, int>{};
  for (final behavior in behaviors.states) {
    if (behavior.behavior == Behavior.idle) {
      final role = ships[behavior.shipSymbol].fleetRole;
      idleByRole[role] = (idleByRole[role] ?? 0) + 1;
    }
  }

  for (final role in FleetRole.values) {
    final count = idleByRole[role] ?? 0;
    if (count > 0) {
      logger.info('${role.name}: $count');
    }
  }
  if (idleByRole.values.every((count) => count == 0)) {
    logger.info('No idle ships found.');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
