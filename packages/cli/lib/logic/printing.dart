import 'package:cli/logger.dart';
import 'package:types/types.dart';

/// Return a string describing the given [waypoint].
String waypointDescription(Waypoint waypoint) {
  final chartedString = waypoint.chart != null ? '' : 'uncharted - ';
  return '${waypoint.symbol} - ${waypoint.type} - $chartedString'
      "${waypoint.traits.map((w) => w.name).join(', ')}";
}

/// Return a string describing the given [contract].
String contractDescription(
  Contract contract, {
  DateTime Function() getNow = defaultGetNow,
}) {
  final terms = contract.terms;
  var termsString = terms.deliver
      .map((d) {
        final unitsRemaining = d.unitsRequired - d.unitsFulfilled;
        final remainingString = d.unitsFulfilled == 0
            ? ''
            : '(${unitsRemaining.toString().padLeft(3)} remaining)';
        return '${d.unitsRequired} $remainingString '
            '${d.tradeSymbol} to ${d.destinationSymbol}';
      })
      .join(', ');
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
  MarketTransactionType type, {
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

  final lowColor = type == MarketTransactionType.SELL ? lightRed : lightGreen;
  final highColor = type == MarketTransactionType.SELL ? lightGreen : lightRed;

  if (diff < 0) {
    return lowColor.wrap('$percentOff% $creditsDiff')!;
  }
  return highColor.wrap('$percentOff% $creditsDiff')!;
}

/// Logs a transaction to the console.
void logMarketTransaction(
  Ship ship,
  Agent agent,
  MarketTransaction transaction, {
  required int? medianPrice,
  String? transactionEmoji,
}) {
  final priceDevianceString = stringForPriceDeviance(
    transaction.tradeSymbolObject,
    price: transaction.pricePerUnit,
    median: medianPrice,
    transaction.type,
  );
  final labelEmoji =
      transactionEmoji ??
      (transaction.type == MarketTransactionType.SELL ? '🤝' : '💸');
  // creditsSign shows which way our bank account moves.
  // When it was a sell, we got paid, so we add.
  final creditsSign = transaction.type == MarketTransactionType.SELL
      ? '+'
      : '-';
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
void logShipyardTransaction(Ship ship, Agent agent, ShipyardTransaction t) {
  shipInfo(
    ship,
    'Purchased ${t.shipSymbol} for '
    '${creditsString(t.price)} -> '
    '🏦 ${creditsString(agent.credits)}',
  );
}

/// Log a shipyard transaction to the console.
void logScrapTransaction(Ship ship, Agent agent, ScrapTransaction t) {
  shipInfo(
    ship,
    'Scrapped ${t.shipSymbol} for '
    '${creditsString(t.totalPrice)} -> '
    '🏦 ${creditsString(agent.credits)}',
  );
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
      'got ${cooldown.totalSeconds}.',
    );
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
    buffer.write(
      '${material.tradeSymbol}: '
      '${material.fulfilled} / ${material.required_}',
    );
  }
  return buffer.toString();
}

/// Returns a string representing the current navigation status of the ship.
String describeShipNav(
  ShipNav nav, {
  DateTime Function() getNow = defaultGetNow,
}) {
  final waypoint = nav.waypointSymbolObject.sectorLocalName;
  switch (nav.status) {
    case ShipNavStatus.DOCKED:
      return 'Docked at $waypoint';
    case ShipNavStatus.IN_ORBIT:
      final arrivalDuration = getNow().difference(nav.route.arrival);
      final arrivalString = approximateDuration(arrivalDuration);
      return 'Orbiting $waypoint since $arrivalString';
    case ShipNavStatus.IN_TRANSIT:
      final remainingDuration = nav.route.arrival.difference(getNow());
      final remainingString = approximateDuration(remainingDuration);
      return 'Transit to $waypoint in $remainingString';
  }
}

/// Log the counts.
void logCounts<T>(Counts<T> counts) {
  // Print the counts in order from most to least:
  final sorted = counts.counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in sorted) {
    logger.info('  ${entry.value}: ${entry.key}');
  }
}

/// Run a function and record time and request count and log if long.
Future<T> expectTime<T>(
  RequestCounts requestCounts,
  QueryCounts queryCounts,
  String name,
  Duration expected,
  Future<T> Function() fn,
) async {
  final result = await captureTimeAndRequests<T>(
    requestCounts,
    queryCounts,
    fn,
    onComplete: (Duration duration, int requestCount, QueryCounts queryCounts) {
      if (duration <= expected) {
        return;
      }
      final queryCount = queryCounts.total;
      final logFn = duration.inSeconds > expected.inSeconds * 2
          ? logger.err
          : logger.warn;
      logFn(
        '$name took too long ${duration.inMilliseconds}ms '
        '($requestCount requests, $queryCount queries)',
      );
      logCounts(queryCounts);
    },
  );
  return result;
}

/// Returns a string describing the construction status of the given
/// [record].
String constructionStatusString(ConstructionRecord? record) {
  if (record == null) {
    return 'unknown';
  }
  if (record.isUnderConstruction) {
    final progress = describeConstructionProgress(record.construction);
    return 'under construction ($progress)';
  }
  return 'ready';
}
