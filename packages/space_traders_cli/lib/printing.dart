import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';

/// Return a string describing the given [waypoint].
String waypointDescription(Waypoint waypoint) {
  return '${waypoint.symbol} - ${waypoint.type} - '
      "${waypoint.traits.map((w) => w.name).join(', ')}";
}

/// Log a string describing the given [waypoints].
void printWaypoints(List<Waypoint> waypoints) {
  for (final waypoint in waypoints) {
    logger.info(waypointDescription(waypoint));
  }
}

/// Return a string describing the given [ship].
/// systemWaypoints is used to look up the waypoint for the ship's
/// waypointSymbol.
String shipDescription(Ship ship, List<Waypoint> systemWaypoints) {
  final waypoint = lookupWaypoint(ship.nav.waypointSymbol, systemWaypoints);
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
void printShips(List<Ship> ships, List<Waypoint> systemWaypoints) {
  for (final ship in ships) {
    logger.info('  ${shipDescription(ship, systemWaypoints)}');
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
String contractDescription(Contract contract) {
  final terms = contract.terms;
  var termsString = terms.deliver
      .map(
        (d) => '${d.unitsRequired} ${d.tradeSymbol} to ${d.destinationSymbol}',
      )
      .join(', ');
  termsString = 'by ${terms.deadline.toLocal()}';
  termsString = 'for ${creditsString(terms.payment.onFulfilled)}';
  termsString = 'with ${creditsString(terms.payment.onAccepted)} upfront';
  return '${contract.type} from ${contract.factionSymbol}, '
      'deliver $termsString';
}

/// Returns a string describing the price deviance of a given [price] from
/// the median price of a given [tradeSymbol].
String stringForPriceDeviance(
  PriceData data,
  String tradeSymbol,
  int price,
  MarketTransactionTypeEnum type,
) {
  final median = type == MarketTransactionTypeEnum.SELL
      ? data.medianSellPrice(tradeSymbol)
      : data.medianPurchasePrice(tradeSymbol);
  if (median == null) {
    return '🤷';
  }
  final diff = price - median;
  if (diff == 0) {
    return '👌';
  }
  final signString = diff < 0 ? '' : '+';
  final percentOff = '$signString${(diff / median * 100).round()}'.padLeft(3);
  final creditsDiff = '$signString${creditsString(diff)}'.padLeft(4);

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
  PriceData priceData,
  Agent agent,
  MarketTransaction transaction, {
  String? transactionEmoji,
}) {
  final priceDevianceString = stringForPriceDeviance(
    priceData,
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
      '$creditsSign${creditsString(transaction.totalPrice)}'.padLeft(5);
  shipInfo(
    ship,
    '$labelEmoji ${transaction.units.toString().padLeft(2)} '
    // Could use TradeSymbol.values.reduce() to find the longest symbol.
    '${transaction.tradeSymbol.padRight(18)} '
    '$priceDevianceString per, '
    '${transaction.units.toString().padLeft(2)} x '
    // Fuel is commonly 3 digits + 'c' so we pad to 4.
    '${creditsString(transaction.pricePerUnit).padLeft(4)} = '
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
