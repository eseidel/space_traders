import 'dart:math';

import 'package:cli/cache/json_list_store.dart';
import 'package:cli/cache/prices_cache.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:cli/config.dart';
import 'package:cli/logger.dart';
import 'package:collection/collection.dart';
import 'package:file/file.dart';
import 'package:types/types.dart';

/// A collection of price records.
class ShipyardPrices extends PricesCache<ShipType, ShipyardPrice> {
  /// Create a new price data collection.
  ShipyardPrices(
    super.records, {
    required super.fs,
    super.path = defaultCacheFilePath,
  });

  /// Load the price data from the cache or from the url.
  factory ShipyardPrices.load(
    FileSystem fs, {
    String path = defaultCacheFilePath,
  }) {
    final prices = JsonListStore.loadRecords<ShipyardPrice>(
          fs,
          path,
          ShipyardPrice.fromJson,
        ) ??
        [];
    return ShipyardPrices(prices, fs: fs);
  }

  /// The default path to the cache file.
  static const String defaultCacheFilePath = 'data/shipyard_prices.json';

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
    final pricesForSymbolSorted = pricesForSymbol.toList()
      ..sortedBy<num>((s) => s.purchasePrice);
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
    final filter = shipyardSymbol == null
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
  }) {
    final pricesForSymbol = purchasePricesFor(
      shipType,
      shipyardSymbol: shipyardSymbol,
    );
    if (pricesForSymbol.isEmpty) {
      return null;
    }
    final pricesForSymbolSorted = pricesForSymbol.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (pricesForSymbolSorted.last.timestamp.difference(DateTime.timestamp()) >
        maxAge) {
      return null;
    }
    return pricesForSymbolSorted.last.purchasePrice;
  }
}

/// Record shipyard data and log the result.
void recordShipyardDataAndLog(
  StaticCaches staticCaches,
  ShipyardPrices shipyardPrices,
  Shipyard shipyard,
  Ship ship,
) {
  recordShipyardData(shipyardPrices, shipyard);
  recordShipyardShips(staticCaches, shipyard.ships);
  // Powershell needs an extra space after the emoji.
  shipInfo(ship, '✍️  shipyard data @ ${shipyard.symbol}');
}

/// Record shipyard data.
void recordShipyardData(
  ShipyardPrices shipyardPrices,
  Shipyard shipyard, {
  DateTime Function() getNow = defaultGetNow,
}) {
  final prices = shipyard.ships
      .map((s) => ShipyardPrice.fromShipyardShip(s, shipyard.waypointSymbol))
      .toList();
  if (prices.isEmpty) {
    logger.warn('No prices for ${shipyard.symbol}!');
  }
  shipyardPrices.addPrices(prices, getNow: getNow);
}
