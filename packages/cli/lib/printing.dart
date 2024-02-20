import 'package:cli/cache/market_prices.dart';
import 'package:cli/logger.dart';
import 'package:intl/intl.dart';
import 'package:types/types.dart';

/// Return a string describing the given [waypoint].
String waypointDescription(Waypoint waypoint) {
  final chartedString = waypoint.chart != null ? '' : 'uncharted - ';
  return '${waypoint.symbol} - ${waypoint.type} - $chartedString'
      "${waypoint.traits.map((w) => w.name).join(', ')}";
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
  TradeSymbol tradeSymbol,
  MarketTransactionTypeEnum type, {
  required int price,
  required int? median,
}) {
  const expectedWidth = 14;
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
void logMarketTransaction(
  Ship ship,
  MarketPriceSnapshot marketPrices,
  Agent agent,
  MarketTransaction transaction, {
  String? transactionEmoji,
}) {
  final median = marketPrices.medianPrice(
    transaction.tradeSymbolObject,
    transaction.type,
  );
  final priceDevianceString = stringForPriceDeviance(
    transaction.tradeSymbolObject,
    price: transaction.pricePerUnit,
    median: median,
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
    '🏦 ${creditsString(agent.credits)}',
  );
}

/// Log a shipyard transaction to the console.
void logShipyardTransaction(
  Ship ship,
  Agent agent,
  ShipyardTransaction t,
) {
  shipInfo(
      ship,
      'Purchased ${t.shipSymbol} for '
      '${creditsString(t.price)} -> '
      '🏦 ${creditsString(agent.credits)}');
}

/// Log a ship modification transaction to the console.
void logShipModificationTransaction(
  Ship ship,
  Agent agent,
  ShipModificationTransaction t,
) {
  shipInfo(
      ship,
      '🔧 ${t.tradeSymbol} on ${t.shipSymbol} for '
      '${creditsString(t.totalPrice)} -> '
      '🏦 ${creditsString(agent.credits)}');
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
  // TODO(eseidel): Use Ship.timeToArrival?
  final arrival = ship.nav.route.arrival;
  final now = getNow();
  final remaining = arrival.difference(now);
  final coloredRemaining = remaining.inHours > 1
      ? red.wrap(approximateDuration(remaining))!
      : approximateDuration(remaining);
  shipInfo(
    ship,
    // Extra space after emoji is needed for windows powershell.
    '✈️  to ${ship.waypointSymbol.sectorLocalName}, $coloredRemaining left',
  );
  return arrival;
}

String _rounded(int whole, int part, int units, String suffix) {
  var absWhole = whole.abs();
  final partial = part / units;
  final sign = whole.sign;
  if (partial >= 0.5) {
    absWhole += 1;
  }
  return '${sign * absWhole}$suffix';
}

/// Create an approximate string for the given [duration].
String approximateDuration(Duration duration) {
  final d = duration; // Save some typing.
  if (d.inDays.abs() >= 365) {
    return '${(d.inDays / 365).round()}y';
  } else if (d.inDays.abs() >= 7) {
    return '${(d.inDays / 7).round()}w';
  } else if (d.inDays.abs() > 0) {
    final absDays = d.inDays.abs();
    final absHours = d.inHours.abs() - (absDays * 24);
    return _rounded(d.inDays, absHours, 24, 'd');
  } else if (d.inHours.abs() > 0) {
    final absHours = d.inHours.abs();
    final absMinutes = d.inMinutes.abs() - (absHours * 60);
    return _rounded(d.inHours, absMinutes, 60, 'h');
  } else if (d.inMinutes.abs() > 0) {
    final absMinutes = d.inMinutes.abs();
    final absSeconds = d.inSeconds.abs() - (absMinutes * 60);
    return _rounded(d.inMinutes, absSeconds, 60, 'm');
  } else if (d.inSeconds.abs() > 0) {
    final absSeconds = d.inSeconds.abs();
    final absMilliseconds = d.inMilliseconds.abs() - (absSeconds * 1000);
    return _rounded(d.inSeconds, absMilliseconds, 1000, 's');
  } else {
    return '${d.inMilliseconds}ms';
  }
}

/// Returns a string describing the given [cargo].
String cargoDescription(ShipCargo cargo) {
  return cargo.inventory.map((e) => '${e.units} ${e.name}').join(', ');
}

/// Log a warning if [cooldown] is not [expected].
void verifyCooldown(Ship ship, String label, int expected, Cooldown cooldown) {
  if (cooldown.totalSeconds != expected) {
    shipWarn(
        ship,
        '$label expected $expected second cooldown, '
        'got ${cooldown.totalSeconds}.');
  }
}

/// Return a string describing the given [construction] progress.
String describeConstructionProgress(Construction? construction) {
  if (construction == null) {
    return 'null';
  }
  if (construction.isComplete) {
    return 'complete';
  }
  final materials = construction.materials;
  final buffer = StringBuffer();
  for (final material in materials) {
    if (material.isFulfilled) {
      continue;
    }
    if (buffer.isNotEmpty) {
      buffer.write(', ');
    }
    buffer.write('${material.tradeSymbol}: '
        '${material.fulfilled} / ${material.required_}');
  }
  return buffer.toString();
}

/// Returns a string representing the current navigation status of the ship.
String describeShipNav(ShipNav nav) {
  final waypoint = nav.waypointSymbolObject.sectorLocalName;
  switch (nav.status) {
    case ShipNavStatus.DOCKED:
      return 'Docked at $waypoint';
    case ShipNavStatus.IN_ORBIT:
      return 'Orbiting $waypoint';
    case ShipNavStatus.IN_TRANSIT:
      return 'Transit to $waypoint';
  }
  return 'Unknown';
}
