import 'package:cli/cli.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli/nav/navigation.dart';

void main(List<String> args) async {
  await runOffline(args, command);
}

String plural(int count, String singular, [String plural = 's']) {
  return '$count ${count == 1 ? singular : singular + plural}';
}

Future<void> command(Database db, ArgResults argResults) async {
  final charterStates = await db.behaviors.ofType(Behavior.charter);
  final systemsCache = db.systems;
  final ships = await ShipSnapshot.load(db);

  logger.info('${plural(charterStates.length, 'charter')}:');
  for (final state in charterStates) {
    final shipSymbol = state.shipSymbol;
    final ship = ships[shipSymbol]!;
    final navString = describeShipNav(ship.nav);
    logger.info('${ship.emojiName} $navString');

    final routePlan = state.routePlan;
    if (routePlan != null) {
      final timeLeft = ship.timeToArrival(routePlan);
      final destination = routePlan.endSymbol.sectorLocalName;
      final destinationType = await systemsCache.waypointType(
        routePlan.endSymbol,
      );
      final arrival = approximateDuration(timeLeft);
      logger.info('  en route to $destination $destinationType in $arrival');
    }
  }
}
