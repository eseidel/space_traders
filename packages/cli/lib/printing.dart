import 'dart:convert';

import 'package:cli/api.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/logger.dart';
import 'package:intl/intl.dart';

/// The default implementation of getNow for production.
/// Used for tests for overriding the current time.
DateTime defaultGetNow() => DateTime.timestamp();

/// Return a string describing the given [waypoint].
String waypointDescription(Waypoint waypoint) {
  final chartedString = waypoint.chart != null ? '' : 'uncharted - ';
  return '${waypoint.symbol} - ${waypoint.type} - $chartedString'
      "${waypoint.traits.map((w) => w.name).join(', ')}";
}

/// Log a string describing the given [waypoints].
void printWaypoints(List<Waypoint> waypoints, {String indent = ''}) {
  for (final waypoint in waypoints) {
    final description = waypointDescription(waypoint);
    logger.info('$indent$description');
  }
}

/// Return a string describing the given [ship].
/// systemWaypoints is used to look up the waypoint for the ship's
/// waypointSymbol.
String shipDescription(Ship ship, SystemsCache systemsCache) {
  final waypoint = systemsCache.waypointFromSymbol(ship.nav.waypointSymbol);
  var string =
      '${ship.symbol} - ${ship.navStatusString} ${waypoint.type} ${ship.registration.role} ${ship.cargo.units}/${ship.cargo.capacity}';
  if (ship.crew.morale != 100) {
    string += ' (morale: ${ship.crew.morale})';
  }
  if (ship.averageCondition != 100) {
    string += ' (condition: ${ship.averageCondition})';
  }
  return string;
}

/// Log a string describing the given [ships].
void printShips(List<Ship> ships, SystemsCache systemsCache) {
  for (final ship in ships) {
    logger.info('  ${shipDescription(ship, systemsCache)}');
  }
}

/// Log the provided [json] as pretty-printed JSON (indented).
void prettyPrintJson(Map<String, dynamic> json) {
  const encoder = JsonEncoder.withIndent('  ');
  final prettyprint = encoder.convert(json);
  logger.info(prettyprint);
}

/// Log the given [ship]'s cargo.
void logCargo(Ship ship) {
  logger.info('Cargo:');
  for (final item in ship.cargo.inventory) {
    logger.info('  ${item.units.toString().padLeft(3)} ${item.name}');
  }
}

/// Format the given [credits] as a string.
String creditsString(int credits) {
  final creditsFormat = NumberFormat();
  return '${creditsFormat.format(credits)}c';
}

/// Return a string describing the given [contract].
String contractDescription(
  Contract contract, {
  DateTime Function() getNow = defaultGetNow,
}) {
  final terms = contract.terms;
  var termsString = terms.deliver.map((d) {
    final unitsRemaining = d.unitsRequired - d.unitsFulfilled;
    final remainingString = d.unitsFulfilled == 0
        ? ''
        : '(${unitsRemaining.toString().padLeft(3)} remaining)';
    return '${d.unitsRequired} $remainingString '
        '${d.tradeSymbol} to ${d.destinationSymbol}';
  }).join(', ');
  final timeRemaining = terms.deadline.difference(getNow());
  termsString += ' in ${approximateDuration(timeRemaining)}';
  termsString += ' for ${creditsString(terms.payment.onFulfilled)}';
  termsString += ' with ${creditsString(terms.payment.onAccepted)} upfront';
  return
      // '${contract.type} '
      // 'from ${contract.factionSymbol}, '
      'deliver $termsString';
}

/// Returns a string describing the price deviance of a given [price] from
/// the median price of a given [tradeSymbol].
String stringForPriceDeviance(
  MarketPrices data,
  String tradeSymbol,
  int price,
  MarketTransactionTypeEnum type,
) {
  const expectedWidth = 14;
  final median = type == MarketTransactionTypeEnum.SELL
      ? data.medianSellPrice(tradeSymbol)
      : data.medianPurchasePrice(tradeSymbol);
  if (median == null) {
    return '🤷'.padLeft(expectedWidth);
  }
  final diff = price - median;
  if (diff == 0) {
    // Extra space is needed for powershell. :(
    return '⚖️ '.padLeft(expectedWidth + 1);
  }
  final signString = diff < 0 ? '' : '+';
  final percentOff = '$signString${(diff / median * 100).round()}'.padLeft(4);
  final creditsDiff = '$signString${creditsString(diff)} per'.padLeft(8);

  final lowColor =
      type == MarketTransactionTypeEnum.SELL ? lightRed : lightGreen;
  final highColor =
      type == MarketTransactionTypeEnum.SELL ? lightGreen : lightRed;

  if (diff < 0) {
    return lowColor.wrap('$percentOff% $creditsDiff')!;
  }
  return highColor.wrap('$percentOff% $creditsDiff')!;
}

/// Logs a transaction to the console.
void logTransaction(
  Ship ship,
  MarketPrices marketPrices,
  Agent agent,
  MarketTransaction transaction, {
  String? transactionEmoji,
}) {
  final priceDevianceString = stringForPriceDeviance(
    marketPrices,
    transaction.tradeSymbol,
    transaction.pricePerUnit,
    transaction.type,
  );
  final labelEmoji = transactionEmoji ??
      (transaction.type == MarketTransactionTypeEnum.SELL ? '🤝' : '💸');
  // creditsSign shows which way our bank account moves.
  // When it was a sell, we got paid, so we add.
  final creditsSign =
      transaction.type == MarketTransactionTypeEnum.SELL ? '+' : '-';
  // Fuel commonly has a 3 digit price with a credit marker and sign
  // so we pad to 5.
  final totalPriceString =
      '$creditsSign${creditsString(transaction.totalPrice)}'.padLeft(7);
  shipInfo(
    ship,
    '$labelEmoji ${transaction.units.toString().padLeft(3)} '
    // Could use TradeSymbol.values.reduce() to find the longest symbol.
    '${transaction.tradeSymbol.padRight(18)} '
    '$priceDevianceString ${transaction.units.toString().padLeft(3)} x '
    // prices are commonly 5 digits + ',' and 'c' so we pad to 7.
    '${creditsString(transaction.pricePerUnit).padLeft(7)} = '
    '$totalPriceString -> '
    // Always want the 'c' after the credits.
    '🏦 ${creditsString(agent.credits)}',
  );
}

/// Generate a String for the given [duration].
String durationString(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
}

/// Logs the remaining transit time for [ship] and returns the arrival time.
DateTime logRemainingTransitTime(
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) {
  final arrival = ship.nav.route.arrival;
  final now = getNow();
  final flightTime = arrival.difference(now);
  shipInfo(
    ship,
    // Extra space after emoji is needed for windows powershell.
    '✈️  to ${ship.nav.waypointSymbol}, ${durationString(flightTime)} left',
  );
  return arrival;
}

/// Choose a ship from a list of ships
Future<Ship> chooseShip(
  Api api,
  SystemsCache systemsCache,
  List<Ship> ships,
) async {
  // Can't just return the result of chooseOne directly without triggering
  // a type error?
  final ship = logger.chooseOne(
    'Which ship?',
    choices: ships,
    display: (ship) => shipDescription(ship, systemsCache),
  );
  return ship;
}

/// Create an approximate string for the given [duration].
String approximateDuration(Duration duration) {
  if (duration.inDays >= 365) {
    return '${(duration.inDays / 365).round()}y';
  } else if (duration.inDays >= 7) {
    return '${(duration.inDays / 7).round()}w';
  } else if (duration.inDays > 0) {
    return '${duration.inDays}d';
  } else if (duration.inHours > 0) {
    return '${duration.inHours}h';
  } else if (duration.inMinutes > 0) {
    return '${duration.inMinutes}m';
  } else if (duration.inSeconds > 0) {
    return '${duration.inSeconds}s';
  } else {
    return '${duration.inMilliseconds}ms';
  }
}

/// Print the status of the server.
void printStatus(GetStatus200Response s) {
  final mostCreditsString = s.leaderboards.mostCredits
      .map(
        (e) => '${e.agentSymbol.padLeft(14)} '
            '${creditsString(e.credits).padLeft(14)}',
      )
      .join(', ');
  final mostChartsString = s.leaderboards.mostSubmittedCharts
      .map(
        (e) => '${e.agentSymbol.padLeft(14)} '
            '${e.chartCount.toString().padLeft(14)}',
      )
      .join(', ');
  final now = DateTime.now();
  final resetDate = DateTime.tryParse(s.resetDate)!;
  final sinceLastReset = approximateDuration(now.difference(resetDate));
  final nextResetDate = DateTime.tryParse(s.serverResets.next)!;
  final untilNextReset = approximateDuration(nextResetDate.difference(now));
  final statsParts = [
    '${s.stats.agents} agents',
    '${s.stats.ships} ships',
    '${s.stats.systems} systems',
    '${s.stats.waypoints} waypoints',
  ].map((e) => e.padLeft(20)).toList();

  logger
    ..info(
      'Stats: ${statsParts.join(' ')}',
    )
    ..info('Most Credits: $mostCreditsString')
    ..info('Most Charts:  $mostChartsString')
    ..info(
      'Last reset $sinceLastReset ago, '
      'next reset: $untilNextReset, '
      'cadence: ${s.serverResets.frequency}',
    );
  final knownAnnouncementTitles = ['Server Resets', 'Discord', 'Support Us'];
  for (final announcement in s.announcements) {
    if (knownAnnouncementTitles.contains(announcement.title)) {
      continue;
    }
    logger.info('Announcement: ${announcement.title}');
  }
}

/// Returns a string describing the given [cargo].
String cargoDescription(ShipCargo cargo) {
  return cargo.inventory.map((e) => '${e.units} ${e.name}').join(', ');
}
