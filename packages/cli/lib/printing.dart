import 'package:cli/api.dart';
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
  MarketPrices data,
  TradeSymbol tradeSymbol,
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
void logMarketTransaction(
  Ship ship,
  MarketPrices marketPrices,
  Agent agent,
  MarketTransaction transaction, {
  String? transactionEmoji,
}) {
  final priceDevianceString = stringForPriceDeviance(
    marketPrices,
    transaction.tradeSymbolObject,
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
  final arrival = ship.nav.route.arrival;
  final now = getNow();
  final remaining = arrival.difference(now);
  shipInfo(
    ship,
    // Extra space after emoji is needed for windows powershell.
    '✈️  to ${ship.waypointSymbol}, '
    '${approximateDuration(remaining)} left',
  );
  return arrival;
}

// TODO(eseidel): This should round, e.g. 0:02:43.000000 should be 3m not 2m.
/// Create an approximate string for the given [duration].
String approximateDuration(Duration duration) {
  if (duration.inDays.abs() >= 365) {
    return '${(duration.inDays / 365).round()}y';
  } else if (duration.inDays.abs() >= 7) {
    return '${(duration.inDays / 7).round()}w';
  } else if (duration.inDays.abs() > 0) {
    return '${duration.inDays}d';
  } else if (duration.inHours.abs() > 0) {
    return '${duration.inHours}h';
  } else if (duration.inMinutes.abs() > 0) {
    return '${duration.inMinutes}m';
  } else if (duration.inSeconds.abs() > 0) {
    return '${duration.inSeconds}s';
  } else {
    return '${duration.inMilliseconds}ms';
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
