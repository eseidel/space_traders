import 'package:cli/cli.dart';
import 'package:cli/config.dart';
import 'package:collection/collection.dart';
import 'package:types/price.dart';
import 'package:types/types.dart';

/// A collection of price records.
// Could consider sharding this by system if it gets too big.
class PriceSnapshot<Symbol extends Object, Record extends PriceBase<Symbol>> {
  /// Create a new price data collection.
  PriceSnapshot(this.prices);

  /// The price records.
  final List<Record> prices;

  /// WaypointSymbols for all markets in the cache.
  Set<WaypointSymbol> get waypointSymbols =>
      prices.map((e) => e.waypointSymbol).toSet();

  /// Waypoints with price data within the given system.
  Iterable<WaypointSymbol> waypointSymbolsInSystem(SystemSymbol systemSymbol) =>
      waypointSymbols.where((s) => s.hasSystem(systemSymbol));

  /// Get the count of unique waypoints.
  int get waypointCount => waypointSymbols.length;

  /// Returns the age of the cache for a given shipyard.
  Duration? cacheAgeFor(
    WaypointSymbol waypointSymbol, {
    DateTime Function() getNow = defaultGetNow,
  }) {
    final atWaypoint =
        prices.where((e) => e.waypointSymbol == waypointSymbol).toList();
    if (atWaypoint.isEmpty) {
      return null;
    }
    final sortedPrices = atWaypoint.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return getNow().difference(sortedPrices.last.timestamp);
  }

  /// Returns the most recent price for a given trade good at a given market.
  Record? priceAt(
    WaypointSymbol waypointSymbol,
    Symbol symbol, {
    Duration maxAge = defaultMaxAge,
    DateTime Function() getNow = defaultGetNow,
  }) {
    final record = prices.firstWhereOrNull(
      (e) => e.symbol == symbol && e.waypointSymbol == waypointSymbol,
    );
    if (record == null) {
      return null;
    }
    if (getNow().difference(record.timestamp) > maxAge) {
      return null;
    }
    return record;
  }

  /// Returns all known prices for a good, optionally restricted to a specific
  /// waypoint.
  Iterable<Record> pricesFor(Symbol symbol) =>
      prices.where((e) => e.symbol == symbol);
}
