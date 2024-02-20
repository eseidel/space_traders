import 'package:db/db.dart';
import 'package:types/types.dart';

/// A cached of market listings.
class MarketListingSnapshot {
  /// Create a new MarketListingSnapshot.
  MarketListingSnapshot(Iterable<MarketListing> listings)
      : _listingBySymbol = Map.fromEntries(
          listings.map((l) => MapEntry(l.waypointSymbol, l)),
        );

  final Map<WaypointSymbol, MarketListing> _listingBySymbol;

  /// Load the MarketListingSnapshot from the database.
  static Future<MarketListingSnapshot> load(Database db) async {
    final listings = await db.allMarketListings();
    return MarketListingSnapshot(listings);
  }

  /// The WaypointSymbols.
  Iterable<WaypointSymbol> get waypointSymbols => _listingBySymbol.keys;

  /// The MarketListings.
  Iterable<MarketListing> get listings => _listingBySymbol.values;

  /// Fetch the MarketListings for the given SystemSymbol.
  Iterable<MarketListing> listingsInSystem(SystemSymbol systemSymbol) =>
      listings.where((l) => l.waypointSymbol.hasSystem(systemSymbol));

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

  /// Returns true if we know of a market which trades the given TradeSymbol.
  bool knowOfMarketWhichTrades(TradeSymbol tradeSymbol) =>
      listings.any((l) => l.allowsTradeOf(tradeSymbol));
}
