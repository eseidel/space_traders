import 'dart:convert';

import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/third_party/compare.dart';

bool _jsonCompare(Ship actual, Ship expected) {
  final diff = findDifferenceBetweenStrings(
    jsonEncode(actual.toJson()),
    jsonEncode(expected.toJson()),
  );
  if (diff != null) {
    logger.info('Ship differs from expected: ${diff.which}');
    return false;
  }
  return true;
}

/// Log a warning if the purchased ship does not match the expected template.
// void verifyShipMatchesTemplate(Ship ship, ShipType shipType) {
//   final fromTemplate = makeShipForComparison(
//     type: shipType,
//     shipSymbol: ship.shipSymbol,
//     factionSymbol: ship.registration.factionSymbol,
//     origin: ship.nav.route.origin,
//     now: ship.nav.route.arrival,
//   );
// }

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final shipCache = ShipCache.loadCached(fs)!;
  final ships = shipCache.ships;
  for (final ship in ships) {
    final frameSymbol = ship.frame.symbol;
    final shipType = shipTypeFromFrame(frameSymbol);
    if (shipType == null) {
      logger.info('Unknown ship type for $frameSymbol');
      continue;
    }
    final exampleShip = makeShipForComparison(
      type: shipType,
      shipSymbol: ship.shipSymbol,
      factionSymbol: FactionSymbols.fromJson(ship.registration.factionSymbol)!,
      cooldown: ship.cooldown,
      nav: ship.nav,
      fuel: ship.fuel,
      cargo: ship.cargo,
      moduleSymbols: ship.modules.map((m) => m.symbol).toList(),
      mountSymbols: ship.mounts.map((m) => m.symbol).toList(),
    );
    if (exampleShip == null) {
      logger.info('Failed to make example ship for $shipType');
      continue;
    }
    _jsonCompare(ship, exampleShip);
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
