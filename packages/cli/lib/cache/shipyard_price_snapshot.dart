import 'dart:math';

import 'package:cli/cache/price_snapshot.dart';
import 'package:cli/cache/shipyard_listing_snapshot.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:cli/logger.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:types/config.dart';
import 'package:types/types.dart';

/// A collection of price records.
class ShipyardPriceSnapshot extends PriceSnapshot<ShipType, ShipyardPrice> {
  /// Create a new price data collection.
  ShipyardPriceSnapshot(super.records);

  /// Load the price data from the cache.
  static Future<ShipyardPriceSnapshot> load(Database db) async {
    final prices = await db.allShipyardPrices();
    return ShipyardPriceSnapshot(prices.toList());
  }

  /// Get the median purchase price for a [ShipType].
  int? medianPurchasePrice(ShipType shipType) =>
      _purchasePriceAtPercentile(shipType, 50);

  /// Get the percentile purchase price for a [ShipType].
  /// [percentile] must be between 0 and 100.
  int? _purchasePriceAtPercentile(ShipType shipType, int percentile) {
    if (percentile > 100 || percentile < 0) {
      throw ArgumentError.value(
        percentile,
        'percentile',
        'Percentile must be between 0 and 100',
      );
    }
    final pricesForSymbol = purchasePricesFor(shipType);
    if (pricesForSymbol.isEmpty) {
      return null;
    }
    // Sort the prices in ascending order.
    final pricesForSymbolSorted =
        pricesForSymbol.toList()..sortedBy<num>((s) => s.purchasePrice);
    // Make sure that 100th percentile doesn't go out of bounds.
    final index = min(
      pricesForSymbolSorted.length * percentile ~/ 100,
      pricesForSymbolSorted.length - 1,
    );
    return pricesForSymbolSorted[index].purchasePrice;
  }

  /// Returns all known purchase prices for a [ShipType], optionally restricted
  /// to a specific waypoint.
  Iterable<ShipyardPrice> purchasePricesFor(
    ShipType shipType, {
    WaypointSymbol? shipyardSymbol,
  }) {
    final filter =
        shipyardSymbol == null
            ? (ShipyardPrice e) => e.shipType == shipType && e.purchasePrice > 0
            : (ShipyardPrice e) =>
                e.shipType == shipType &&
                e.purchasePrice > 0 &&
                e.waypointSymbol == shipyardSymbol;
    return prices.where(filter);
  }

  /// The most recent price can be purchased from the shipyard.
  /// [shipyardSymbol] is the symbol for the market.
  /// [shipType] is the ShipType to check.
  /// [maxAge] is the maximum age of the price in the cache.
  int? recentPurchasePrice({
    required WaypointSymbol shipyardSymbol,
    required ShipType shipType,
    Duration maxAge = defaultMaxAge,
    DateTime Function() getNow = defaultGetNow,
  }) {
    final pricesForSymbol = purchasePricesFor(
      shipType,
      shipyardSymbol: shipyardSymbol,
    );
    if (pricesForSymbol.isEmpty) {
      return null;
    }
    final pricesForSymbolSorted =
        pricesForSymbol.toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (pricesForSymbolSorted.last.timestamp.difference(getNow()) > maxAge) {
      return null;
    }
    return pricesForSymbolSorted.last.purchasePrice;
  }
}

/// Record shipyard data and log the result.
void recordShipyardDataAndLog(
  Database db,
  StaticCaches staticCaches,
  Shipyard shipyard,
  Ship ship,
) {
  recordShipyardPrices(db, shipyard);
  recordShipyardShips(staticCaches, shipyard.ships);
  recordShipyardListing(db, shipyard);
  // Powershell needs an extra space after the emoji.
  shipDetail(ship, '✍️  shipyard data @ ${shipyard.symbol}');
}

/// Record shipyard prices.
void recordShipyardPrices(
  Database db,
  Shipyard shipyard, {
  DateTime Function() getNow = defaultGetNow,
}) {
  final prices =
      shipyard.ships
          .map(
            (s) => ShipyardPrice.fromShipyardShip(
              s,
              shipyard.waypointSymbol,
              getNow: getNow,
            ),
          )
          .toList();
  if (prices.isEmpty) {
    logger.warn('No prices for ${shipyard.symbol}!');
  }
  for (final price in prices) {
    db.upsertShipyardPrice(price);
  }
}
