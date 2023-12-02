import 'package:cli/cache/caches.dart';
import 'package:collection/collection.dart';
import 'package:types/types.dart';

/// Returns the TradeSymbols extractable by the given mount.
Set<TradeSymbol> extractableSymbols(ExtractionType type) {
  // Surveyors have a .deposits field, but other mounts do not so we hard-code
  // based on extraction type.  All lasers and all siphons yield the same
  // symbols, just at different size loads.
  switch (type) {
    case ExtractionType.mine:
      return {
        TradeSymbol.ALUMINUM_ORE,
        TradeSymbol.AMMONIA_ICE,
        TradeSymbol.COPPER_ORE,
        TradeSymbol.GOLD_ORE,
        TradeSymbol.ICE_WATER,
        TradeSymbol.IRON_ORE,
        TradeSymbol.MERITIUM_ORE,
        TradeSymbol.PLATINUM_ORE,
        TradeSymbol.PRECIOUS_STONES,
        TradeSymbol.QUARTZ_SAND,
        TradeSymbol.SILICON_CRYSTALS,
        TradeSymbol.SILVER_ORE,
        TradeSymbol.URANITE_ORE,
      };
    case ExtractionType.siphon:
      return {
        TradeSymbol.HYDROCARBON,
        TradeSymbol.LIQUID_HYDROGEN,
        TradeSymbol.LIQUID_NITROGEN,
      };
  }
}

/// Returns TradeSymbols expected from mining at a given WaypointType and
/// WaypointTraits.
Set<TradeSymbol> expectedGoodsForWaypoint(
  WaypointType waypointType,
  Set<WaypointTraitSymbol> waypointTraits,
  ExtractionType extractionType,
) {
  // Reportedly SpaceAdmiral has said that Astroid implies MINERAL_DEPOSITS:
  // https://discord.com/channels/792864705139048469/792864705139048472/1178507596433465446
  final traitGoods =
      waypointTraits.map((t) => tradeSymbolsByTrait[t] ?? {}).expand((e) => e);
  final typeGoods = tradeSymbolsByType[waypointType] ?? {};
  final goods = traitGoods.toSet().union(typeGoods);
  // Should we restrict by survey mounts?
  return goods.intersection(extractableSymbols(extractionType));
}

/// Evaluate an extraction site and Market pairing
class ExtractionScore {
  /// Creates a new ExtractionScore.
  ExtractionScore({
    required this.source,
    required this.sourceType,
    required this.sourceTraits,
    required this.marketForGood,
    required this.deliveryDistance,
    required this.extractionType,
  });

  /// The symbol of the mine.
  final WaypointSymbol source;

  /// The WaypointType of the mine.
  final WaypointType sourceType;

  /// The traits of the mine.
  final Set<WaypointTraitSymbol> sourceTraits;

  /// Nearest import market for each good produced.
  final Map<TradeSymbol, WaypointSymbol> marketForGood;

  /// Round trip distance of delivering all goods.
  final int deliveryDistance;

  /// Method of extraction.
  final ExtractionType extractionType;

  /// The set of all markets used in this score.
  Set<WaypointSymbol> get markets {
    return marketForGood.values.toSet();
  }

  /// Goods produced at the mine.
  Set<TradeSymbol> get producedGoods {
    return expectedGoodsForWaypoint(
      sourceType,
      sourceTraits,
      extractionType,
    );
  }

  /// True if the markets trade all goods produced at the source.
  bool get marketsTradeAllProducedGoods {
    return producedGoods.length == marketForGood.length;
  }

  /// Goods produced at the mine which are not traded at the market.
  Set<TradeSymbol> get goodsMissingFromMarkets {
    return producedGoods.difference(marketForGood.keys.toSet());
  }

  /// The score of this MineAndSell. Lower is better.
  int get score {
    // TODO(eseidel): Score should adjust based on "stripped" trate for mine
    // as well as the average value of goods at the market.
    return deliveryDistance;
  }

  /// The names of the traits with boilderplate removed.
  List<String> get displayTraitNames {
    return sourceTraits
        .map((t) => t.value.replaceAll('_DEPOSITS', ''))
        .toList();
  }
}

/// Returns the nearest WaypointSymbol in the same system which matches the
/// given predicate.
WaypointSymbol? nearestTo(
  SystemsCache systemsCache,
  WaypointSymbol waypointSymbol,
  bool Function(SystemWaypoint) predicate,
) {
  final destination = systemsCache.waypoint(waypointSymbol);
  final candidates = systemsCache
      .waypointsInSystem(waypointSymbol.systemSymbol)
      .where(predicate)
      .toList()
    ..sort(
      (a, b) => a.distanceTo(destination).compareTo(b.distanceTo(destination)),
    );
  return candidates.firstOrNull?.waypointSymbol;
}

/// Given a start location and a set of goods, find the closest markets
/// which buy those goods.
Map<TradeSymbol, WaypointSymbol> findImportingMarketsForGoods(
  SystemsCache systemsCache,
  MarketListingCache marketListings,
  WaypointSymbol start,
  Set<TradeSymbol> goods,
) {
  final markets = <TradeSymbol, WaypointSymbol>{};
  for (final good in goods) {
    final market = nearestTo(systemsCache, start, (waypoint) {
      return marketListings[waypoint.waypointSymbol]
              // TODO(eseidel): This should only be imports.
              ?.tradeSymbols
              .contains(good) ??
          false;
    });
    if (market != null) {
      markets[good] = market;
    }
  }
  return markets;
}

/// Evaluate all possible source and Market pairings.
Future<List<ExtractionScore>> _evaluateWaypointsForExtraction(
  WaypointCache waypointCache,
  SystemsCache systemsCache,
  MarketListingCache marketListings,
  SystemSymbol systemSymbol,
  bool Function(Waypoint) sourcePredicate,
  ExtractionType extractionType,
) async {
  final sources = (await waypointCache.waypointsInSystem(systemSymbol))
      .where(sourcePredicate)
      .toList();
  final scores = <ExtractionScore>[];
  for (final source in sources) {
    final expectedGoods = expectedGoodsForWaypoint(
      source.type,
      source.traits.map((t) => t.symbol).toSet(),
      extractionType,
    );
    final sourceTraitSymbols = source.traits.map((t) => t.symbol).toSet();
    final marketForGood = findImportingMarketsForGoods(
      systemsCache,
      marketListings,
      source.waypointSymbol,
      expectedGoods,
    );
    final marketSymbols = marketForGood.values.toSet();
    final deliveryDistance = approximateRoundTripDistanceWithinSystem(
      systemsCache,
      source.waypointSymbol,
      marketSymbols,
    );
    scores.add(
      ExtractionScore(
        source: source.waypointSymbol,
        sourceType: source.type,
        sourceTraits: sourceTraitSymbols,
        marketForGood: marketForGood,
        deliveryDistance: deliveryDistance,
        extractionType: extractionType,
      ),
    );
  }
  scores.sortBy<num>((m) => m.score);
  return scores;
}

/// Evaluate all possible source and Market pairings for mining.
Future<List<ExtractionScore>> evaluateWaypointsForMining(
  WaypointCache waypointCache,
  SystemsCache systemsCache,
  MarketListingCache marketListings,
  SystemSymbol systemSymbol,
) async {
  return _evaluateWaypointsForExtraction(
    waypointCache,
    systemsCache,
    marketListings,
    systemSymbol,
    (w) => w.canBeMined,
    ExtractionType.mine,
  );
}

/// Evaluate all possible source and Market pairings for siphoning.
Future<List<ExtractionScore>> evaluateWaypointsForSiphoning(
  WaypointCache waypointCache,
  SystemsCache systemsCache,
  MarketListingCache marketListings,
  SystemSymbol systemSymbol,
) async {
  return _evaluateWaypointsForExtraction(
    waypointCache,
    systemsCache,
    marketListings,
    systemSymbol,
    (w) => w.canBeSiphoned,
    ExtractionType.siphon,
  );
}

/// Trade symbols for extraction based on waypoint type.
final tradeSymbolsByType = {
  WaypointType.GAS_GIANT: {
    TradeSymbol.HYDROCARBON,
    TradeSymbol.LIQUID_HYDROGEN,
    TradeSymbol.LIQUID_NITROGEN,
  },
};

/// TradeSymbols available for extraction based on WaypointTraits.
/// This is unlikely to be a correct/complete list.
/// This was created by reading the WaypointTrait descriptions.
final tradeSymbolsByTrait = {
  WaypointTraitSymbol.COMMON_METAL_DEPOSITS: {
    // Listed in trait descriptions:
    TradeSymbol.ALUMINUM_ORE,
    TradeSymbol.COPPER_ORE,
    TradeSymbol.IRON_ORE,
    // Seen in game:
    TradeSymbol.ICE_WATER,
    TradeSymbol.SILICON_CRYSTALS,
    TradeSymbol.QUARTZ_SAND,
  },
  WaypointTraitSymbol.MINERAL_DEPOSITS: {
    // Listed in trait descriptions:
    TradeSymbol.SILICON_CRYSTALS,
    TradeSymbol.QUARTZ_SAND,
    // Seen in game:
    TradeSymbol.AMMONIA_ICE,
    TradeSymbol.ICE_WATER,
    TradeSymbol.IRON_ORE,
    TradeSymbol.PRECIOUS_STONES,
  },
  WaypointTraitSymbol.PRECIOUS_METAL_DEPOSITS: {
    // Listed in trait descriptions:
    TradeSymbol.PLATINUM_ORE,
    TradeSymbol.GOLD_ORE,
    TradeSymbol.SILVER_ORE,
    // Seen in game:
    TradeSymbol.ALUMINUM_ORE,
    TradeSymbol.COPPER_ORE,
    TradeSymbol.ICE_WATER,
    TradeSymbol.QUARTZ_SAND,
    TradeSymbol.SILICON_CRYSTALS,
  },
  WaypointTraitSymbol.RARE_METAL_DEPOSITS: {
    // Listed in trait descriptions:
    TradeSymbol.URANITE_ORE,
    TradeSymbol.MERITIUM_ORE,
  },
  WaypointTraitSymbol.FROZEN: {
    // Listed in trait descriptions:
    TradeSymbol.ICE_WATER,
    TradeSymbol.AMMONIA_ICE,
  },
  WaypointTraitSymbol.ICE_CRYSTALS: {
    // Listed in trait descriptions:
    TradeSymbol.ICE_WATER,
    TradeSymbol.AMMONIA_ICE,
    TradeSymbol.LIQUID_HYDROGEN,
    TradeSymbol.LIQUID_NITROGEN,
  },
  WaypointTraitSymbol.EXPLOSIVE_GASES: {
    // Listed in trait descriptions:
    TradeSymbol.HYDROCARBON,
  },
  WaypointTraitSymbol.SWAMP: {
    // Listed in trait descriptions:
    TradeSymbol.HYDROCARBON,
  },
  WaypointTraitSymbol.STRONG_MAGNETOSPHERE: {
    // Listed in trait descriptions:
    TradeSymbol.EXOTIC_MATTER,
    TradeSymbol.GRAVITON_EMITTERS,
  },
};
