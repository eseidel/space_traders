import 'package:cli/caches.dart';
import 'package:cli/cli.dart';

void main(List<String> args) async {
  await runOffline(args, command);
}

Map<SystemSymbol, List<Ship>> _shipsBySystem(List<Ship> ships) {
  final shipsBySystem = <SystemSymbol, List<Ship>>{};
  for (final ship in ships) {
    shipsBySystem.putIfAbsent(ship.systemSymbol, () => <Ship>[]).add(ship);
  }
  return shipsBySystem;
}

String _describeBehaviors(BehaviorSnapshot behaviors, List<Ship> ships) {
  final behaviorCounts = <Behavior?, int>{};
  for (final ship in ships) {
    final behavior = behaviors[ship.shipSymbol]?.behavior;
    behaviorCounts[behavior] = (behaviorCounts[behavior] ?? 0) + 1;
  }
  return behaviorCounts.entries.map((e) => '${e.key}: ${e.value}').join(', ');
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final ships = await ShipSnapshot.load(db);
  final behaviors = await BehaviorSnapshot.load(db);

  final bySystem = _shipsBySystem(ships.ships);
  for (final system in bySystem.keys) {
    final ships = bySystem[system]!;
    logger
      ..info('$system: ${describeShips(ships)}')
      ..info('      ${_describeBehaviors(behaviors, ships)}');
  }
}
