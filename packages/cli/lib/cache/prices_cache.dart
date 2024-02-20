import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:types/price.dart';
import 'package:types/types.dart';

/// A collection of price records.
// Could consider sharding this by system if it gets too big.
// TODO(eseidel): rename PricesSnapshot
class PricesCache<Symbol extends Object, Record extends PriceBase<Symbol>> {
  /// Create a new price data collection.
  PricesCache(this.prices);

  /// The price records.
  final List<Record> prices;

  /// The length of the price data.
  int get count => prices.length;

  /// WaypointSymbols for all markets in the cache.
  Set<WaypointSymbol> get waypointSymbols =>
      prices.map((e) => e.waypointSymbol).toSet();

  /// Waypoints with price data within the given system.
  Iterable<WaypointSymbol> waypointSymbolsInSystem(SystemSymbol systemSymbol) =>
      waypointSymbols.where((s) => s.hasSystem(systemSymbol));

  /// Get the count of unique waypoints.
  int get waypointCount => waypointSymbols.length;

  /// Hook for subclasses when a price has changed.
  @protected
  void priceChanged({required Record oldPrice, required Record newPrice}) {}

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
    return DateTime.timestamp().difference(sortedPrices.last.timestamp);
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
