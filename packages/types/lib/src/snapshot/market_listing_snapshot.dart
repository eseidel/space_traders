import 'package:types/types.dart';

/// A cached of market listings.
class MarketListingSnapshot {
  /// Create a new MarketListingSnapshot.
  MarketListingSnapshot(Iterable<MarketListing> listings)
    : _listingBySymbol = Map.fromEntries(
        listings.map((l) => MapEntry(l.waypointSymbol, l)),
      );

  final Map<WaypointSymbol, MarketListing> _listingBySymbol;

  /// The WaypointSymbols.
  Iterable<WaypointSymbol> get waypointSymbols => _listingBySymbol.keys;

  /// The MarketListings.
  Iterable<MarketListing> get listings => _listingBySymbol.values;

  /// Fetch the MarketListings for the given SystemSymbol.
  Iterable<MarketListing> _inSystem(SystemSymbol systemSymbol) =>
      listings.where((l) => l.waypointSymbol.system == systemSymbol);

  /// Count the number of MarketListings in the given SystemSymbol.
  int countInSystem(SystemSymbol systemSymbol) =>
      _inSystem(systemSymbol).length;

  /// Fetch the MarketListing for the given WaypointSymbol.
  MarketListing? operator [](WaypointSymbol waypointSymbol) =>
      _listingBySymbol[waypointSymbol];

  /// Find systems with at least N markets.
  Set<SystemSymbol> systemsWithAtLeastNMarkets(int n) {
    final systemMarketCounts = <SystemSymbol, int>{};
    for (final waypointSymbol in waypointSymbols) {
      final systemSymbol = waypointSymbol.system;
      systemMarketCounts[systemSymbol] =
          (systemMarketCounts[systemSymbol] ?? 0) + 1;
    }
    return systemMarketCounts.entries
        .where((e) => e.value >= n)
        .map((e) => e.key)
        .toSet();
  }

  /// Returns all MarketListings which export the given TradeSymbol in
  /// the given SystemSymbol.
  /// Unlike the MarketListingStore version which returns WaypointSymbols.
  Iterable<MarketListing> whichExportsInSystem(
    SystemSymbol system,
    TradeSymbol tradeSymbol,
  ) {
    return listings.where(
      (l) =>
          l.waypointSymbol.system == system && l.exports.contains(tradeSymbol),
    );
  }

  /// Returns true if we know of a market which trades the given TradeSymbol.
  bool knowOfMarketWhichTrades(TradeSymbol tradeSymbol) =>
      listings.any((l) => l.allowsTradeOf(tradeSymbol));
}
