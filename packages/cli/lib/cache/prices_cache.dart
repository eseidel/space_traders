import 'package:cli/cache/json_list_store.dart';
import 'package:cli/logger.dart';
import 'package:collection/collection.dart';
import 'package:db/config.dart';
import 'package:meta/meta.dart';
import 'package:types/price.dart';
import 'package:types/types.dart';

/// A collection of price records.
// Could consider sharding this by system if it gets too big.
class PricesCache<Symbol extends Object, Record extends PriceBase<Symbol>>
    extends JsonListStore<Record> {
  /// Create a new price data collection.
  PricesCache(
    super.records, {
    required super.fs,
    required super.path,
  });

  /// WaypointSymbols for all markets in the cache.
  Set<WaypointSymbol> get waypointSymbols =>
      prices.map((e) => e.waypointSymbol).toSet();

  /// Waypoints with price data within the given system.
  Iterable<WaypointSymbol> waypointsWithPricesInSystem(
    SystemSymbol systemSymbol,
  ) =>
      waypointSymbols.where((s) => s.systemSymbol == systemSymbol);

  /// Get the count of unique waypoints.
  int get waypointCount => waypointSymbols.length;

  /// Get the raw pricing data.
  List<Record> get prices => records;

  /// Hook for subclasses when a price has changed.
  @protected
  void priceChanged({required Record oldPrice, required Record newPrice}) {}

  /// Add new prices to the price data.
  void addPrices(
    List<Record> newPrices, {
    DateTime Function() getNow = defaultGetNow,
  }) {
    for (final newPrice in newPrices) {
      // This doesn't account for existing duplicates.
      final index = prices.indexWhere(
        (element) =>
            element.waypointSymbol == newPrice.waypointSymbol &&
            element.symbol == newPrice.symbol,
      );

      if (getNow().isBefore(newPrice.timestamp)) {
        logger.warn('Bogus timestamp on price: ${newPrice.timestamp}');
        continue;
      }

      if (index >= 0) {
        // This date logic is necessary to make sure we don't replace
        // more recent local prices with older server data.
        final existingPrice = prices[index];
        if (newPrice.timestamp.isBefore(existingPrice.timestamp)) {
          continue;
        }
        priceChanged(oldPrice: existingPrice, newPrice: newPrice);
        // If the new price is newer than the existing price, replace it.
        prices[index] = newPrice;
      } else {
        prices.add(newPrice);
      }
    }
    save();
  }

  /// Returns true if there is recent market data for a given market.
  /// Does not check if the passed in market is a valid market.
  bool hasRecentData(
    WaypointSymbol marketSymbol, {
    Duration maxAge = defaultMaxAge,
    DateTime Function() getNow = defaultGetNow,
  }) {
    final pricesAtWaypoint =
        prices.where((e) => e.waypointSymbol == marketSymbol);
    if (pricesAtWaypoint.isEmpty) {
      return false;
    }
    final pricesAtWaypointSorted = pricesAtWaypoint.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return getNow().difference(pricesAtWaypointSorted.last.timestamp) < maxAge;
  }

  /// Returns the age of the cache for a given shipyard.
  Duration? cacheAgeFor(
    WaypointSymbol waypointSymbol, {
    DateTime Function() getNow = defaultGetNow,
  }) {
    final prices = pricesAt(waypointSymbol);
    if (prices.isEmpty) {
      return null;
    }
    final sortedPrices = prices.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return DateTime.now().difference(sortedPrices.last.timestamp);
  }

  /// Returns all known prices for a given shipyard.
  List<Record> pricesAt(WaypointSymbol waypointSymbol) {
    return prices.where((e) => e.waypointSymbol == waypointSymbol).toList();
  }

  /// Returns the most recent price for a given trade good at a given market.
  Record? priceAt(WaypointSymbol waypointSymbol, Symbol symbol) {
    return prices.firstWhereOrNull(
      (e) => e.symbol == symbol && e.waypointSymbol == waypointSymbol,
    );
  }

  /// Returns all known prices for a good, optionally restricted to a specific
  /// waypoint.
  Iterable<Record> pricesFor(
    Symbol symbol, {
    WaypointSymbol? waypointSymbol,
  }) {
    final matching = prices.where((e) => e.symbol == symbol);
    if (waypointSymbol == null) {
      return matching;
    }
    return matching.where((e) => e.waypointSymbol == waypointSymbol);
  }

  /// Returns true if there is a price for a given [Symbol],
  /// Used for detecting if we have access to a given good yet.
  bool havePriceFor(Symbol symbol) {
    return prices.any((p) => p.symbol == symbol);
  }
}
