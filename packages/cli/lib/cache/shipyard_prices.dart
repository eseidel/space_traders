import 'dart:math';

import 'package:cli/cache/json_list_store.dart';
import 'package:cli/cache/market_prices.dart'; // just for maxAge.
import 'package:cli/logger.dart';
import 'package:collection/collection.dart';
import 'package:file/file.dart';
import 'package:types/types.dart';

/// A collection of price records.
// Could consider sharding this by system if it gets too big.
class ShipyardPrices extends JsonListStore<ShipyardPrice> {
  /// Create a new price data collection.
  ShipyardPrices(
    super.prices, {
    required super.fs,
    super.path = defaultCacheFilePath,
  });

  /// The default path to the cache file.
  static const String defaultCacheFilePath = 'data/shipyard_prices.json';

  // This might not actually be true!  I've never seen a 0 in the data.
  // These may contain 0s and duplicates, best to access it through one
  // of the accessors which knows how to filter.
  List<ShipyardPrice> get _prices => entries;

  /// Get the count of unique waypoints.
  int get waypointCount {
    final waypoints = <WaypointSymbol>{};
    for (final price in _prices) {
      waypoints.add(price.waypointSymbol);
    }
    return waypoints.length;
  }

  /// Get the raw pricing data.
  List<ShipyardPrice> get prices => _prices;

  /// Load the price data from the cache or from the url.
  // ignore: prefer_constructors_over_static_methods
  static ShipyardPrices load(
    FileSystem fs, {
    String path = defaultCacheFilePath,
  }) {
    final prices = JsonListStore.load<ShipyardPrice>(
          fs,
          path,
          ShipyardPrice.fromJson,
        ) ??
        [];
    return ShipyardPrices(prices, fs: fs);
  }

  /// Add new prices to the shipyard price data.
  void addPrices(List<ShipyardPrice> newPrices) {
    for (final newPrice in newPrices) {
      // This doesn't account for existing duplicates.
      final index = _prices.indexWhere(
        (element) =>
            element.waypointSymbol == newPrice.waypointSymbol &&
            element.shipType == newPrice.shipType,
      );

      if (index >= 0) {
        // This date logic is necessary to make sure we don't replace
        // more recent local prices with older server data.
        final existingPrice = _prices[index];
        if (DateTime.timestamp().isBefore(newPrice.timestamp)) {
          logger.warn('Bogus timestamp on price: ${newPrice.timestamp}');
          continue;
        }
        if (newPrice.timestamp.isBefore(existingPrice.timestamp)) {
          continue;
        }
        // If the new price is newer than the existing price, replace it.
        _prices[index] = newPrice;
      } else {
        _prices.add(newPrice);
      }
    }
    save();
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
    return _prices.where(filter);
  }

  /// Returns true if there is recent market data for a given market.
  /// Does not check if the passed in market is a valid market.
  bool hasRecentShipyardData(
    WaypointSymbol marketSymbol, {
    Duration maxAge = defaultMaxAge,
  }) {
    final pricesForMarket =
        _prices.where((e) => e.waypointSymbol == marketSymbol);
    if (pricesForMarket.isEmpty) {
      return false;
    }
    final pricesForMarketSorted = pricesForMarket.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return DateTime.timestamp()
            .difference(pricesForMarketSorted.last.timestamp) <
        maxAge;
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

  /// Returns all known prices for a given shipyard.
  List<ShipyardPrice> pricesAtShipyard(WaypointSymbol shipyardSymbol) {
    return _prices.where((e) => e.waypointSymbol == shipyardSymbol).toList();
  }

  /// Returns all known prices for a ship type,
  /// optionally restricted to a specific waypoint.
  Iterable<ShipyardPrice> pricesFor(
    ShipType shipType, {
    WaypointSymbol? shipyardSymbol,
  }) {
    final prices = _prices.where((e) => e.shipType == shipType);
    if (shipyardSymbol == null) {
      return prices;
    }
    return prices.where((e) => e.waypointSymbol == shipyardSymbol);
  }
}

/// Record shipyard data and log the result.
void recordShipyardDataAndLog(
  ShipyardPrices shipyardPrices,
  Shipyard shipyard,
  Ship ship,
) {
  recordShipyardData(shipyardPrices, shipyard);
  // Powershell needs an extra space after the emoji.
  shipInfo(ship, '✍️  shipyard data @ ${shipyard.symbol}');
}

/// Record shipyard data.
void recordShipyardData(
  ShipyardPrices shipyardPrices,
  Shipyard shipyard,
) {
  final prices = shipyard.ships
      .map((s) => ShipyardPrice.fromShipyardShip(s, shipyard.waypointSymbol))
      .toList();
  if (prices.isEmpty) {
    logger.warn('No prices for ${shipyard.symbol}!');
  }
  shipyardPrices.addPrices(prices);
}
