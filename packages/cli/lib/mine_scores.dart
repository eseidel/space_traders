import 'package:cli/cache/caches.dart';
import 'package:collection/collection.dart';
import 'package:types/types.dart';

/// Returns the TradeSymbols extractable by the given mount.
Set<TradeSymbol> extractableByMount(ShipMount mount) {
  // Surveyors have a .deposits field, but other mounts do not.
  if (kLaserMountSymbols.contains(mount.symbol)) {
    return {
      TradeSymbol.ALUMINUM_ORE,
      TradeSymbol.COPPER_ORE,
      TradeSymbol.IRON_ORE,
      TradeSymbol.PLATINUM_ORE,
      TradeSymbol.GOLD_ORE,
      TradeSymbol.SILVER_ORE,
      TradeSymbol.URANITE_ORE,
      TradeSymbol.MERITIUM_ORE,
      TradeSymbol.ICE_WATER,
      TradeSymbol.AMMONIA_ICE,
      TradeSymbol.SILICON_CRYSTALS,
      TradeSymbol.QUARTZ_SAND,
      TradeSymbol.PRECIOUS_STONES,
    };
  }
  if (kSiphonMountSymbols.contains(mount.symbol)) {
    return {
      TradeSymbol.LIQUID_HYDROGEN,
      TradeSymbol.LIQUID_NITROGEN,
      TradeSymbol.HYDROCARBON,
    };
  }
  return {};
}

/// Returns TradeSymbols expected from mining at a given WaypointType and
/// WaypointTraits.
Set<TradeSymbol> expectedGoodsForWaypoint(
  WaypointType waypointType,
  Set<WaypointTraitSymbol> waypointTraits, {
  Set<ShipMount>? extractionMounts,
}) {
  // Reportedly SpaceAdmiral has said that Astroid implies MINERAL_DEPOSITS:
  // https://discord.com/channels/792864705139048469/792864705139048472/1178507596433465446
  var goods = waypointTraits
      .map((t) => tradeSymbolsByTrait[t] ?? [])
      .expand((e) => e)
      .toSet();
  // Should we restrict by survey mounts too?
  if (extractionMounts != null) {
    final extractableSymbols =
        extractionMounts.map(extractableByMount).reduce((a, b) => a.union(b));
    goods = goods.intersection(extractableSymbols);
  }
  return goods;
}

/// Evaluate a Mine and Market pairing
class MineScore {
  /// Creates a new MineAndSell.
  MineScore({
    required this.mine,
    required this.market,
    required this.mineTraits,
    required this.distanceBetweenMineAndMarket,
    required this.tradedGoods,
  });

  /// The symbol of the mine.
  final WaypointSymbol mine;

  /// The traits of the mine.
  final List<WaypointTraitSymbol> mineTraits;

  /// The symbol of the market.
  final WaypointSymbol market;

  /// Goods traded at the market.
  final Set<TradeSymbol> tradedGoods;

  /// The distance between the mine and the market.
  final int distanceBetweenMineAndMarket;

  /// The names of the traits of the mine.
  List<String> get mineTraitNames {
    return mineTraits.map((t) => t.value.replaceAll('_DEPOSITS', '')).toList();
  }

  /// Goods produced at the mine.
  Set<TradeSymbol> get producedGoods {
    return expectedGoodsForWaypoint(
      // Should cache the WaypointType and use it here.
      WaypointType.ASTEROID,
      mineTraits.toSet(),
    );
  }

  /// True if the market trades all goods produced at the mine.
  bool get marketTradesAllProducedGoods {
    return producedGoods.every(tradedGoods.contains);
  }

  /// Goods produced at the mine which are not traded at the market.
  Set<TradeSymbol> get goodsMissingFromMarket {
    return producedGoods.difference(tradedGoods);
  }

  /// The score of this MineAndSell. Lower is better.
  int get score {
    // TODO(eseidel): Score should adjust based on "stripped" trate for mine
    // as well as the average value of goods at the market.
    return distanceBetweenMineAndMarket;
  }
}

/// Evaluate all possible Mine and Market pairings for a given system.
Future<List<MineScore>> evaluateWaypointsForMining(
  WaypointCache waypointCache,
  MarketListingCache marketListings,
  SystemSymbol systemSymbol,
) async {
  final waypoints = await waypointCache.waypointsInSystem(systemSymbol);
  final marketWaypoints = waypoints.where((w) => w.hasMarketplace);
  final mines = waypoints.where((w) => w.canBeMined);
  final mineAndSells = <MineScore>[];
  for (final mine in mines) {
    for (final marketWaypoint in marketWaypoints) {
      final distance = mine.distanceTo(marketWaypoint);
      final mineTraits =
          mine.traits.map((t) => t.symbol).where(isMinableTrait).toList();
      final market =
          marketListings.marketListingForSymbol(marketWaypoint.waypointSymbol);
      final marketGoods = market?.tradeSymbols.toSet() ?? {};
      mineAndSells.add(
        MineScore(
          mine: mine.waypointSymbol,
          mineTraits: mineTraits,
          market: marketWaypoint.waypointSymbol,
          tradedGoods: marketGoods,
          distanceBetweenMineAndMarket: distance.ceil(),
        ),
      );
    }
  }
  mineAndSells.sortBy<num>((m) => m.score);
  return mineAndSells;
}

/// Evaluate a siphon location and Market pairing
class SiphonScore {
  /// Creates a new SiphonScore.
  SiphonScore({
    required this.target,
    required this.market,
    required this.producedGoods,
    required this.distanceBetween,
    required this.marketGoods,
  });

  /// The symbol of the siphon location.
  final WaypointSymbol target;

  /// The symbol of the market.
  final WaypointSymbol market;

  /// Goods produced at the target.
  final Set<TradeSymbol> producedGoods;

  /// Goods traded at the market.
  final Set<TradeSymbol> marketGoods;

  /// The distance between the target and the market.
  final int distanceBetween;

  /// True if the market trades all goods produced at the mine.
  bool get marketTradesAllProducedGoods {
    return producedGoods.every(marketGoods.contains);
  }

  /// Goods produced at the target which are not traded at the market.
  Set<TradeSymbol> get goodsMissingFromMarket {
    return producedGoods.difference(marketGoods);
  }

  /// The score. Lower is better.
  int get score => distanceBetween;
}

/// Evaluate all possible siphon location and Market pairings for a system.
Future<List<SiphonScore>> evaluateWaypointsForSiphoning(
  WaypointCache waypointCache,
  MarketListingCache marketListings,
  SystemSymbol systemSymbol,
) async {
  final waypoints = await waypointCache.waypointsInSystem(systemSymbol);
  final marketWaypoints = waypoints.where((w) => w.hasMarketplace);
  final targets = waypoints.where((w) => w.canBeSiphoned);
  final scores = <SiphonScore>[];
  for (final target in targets) {
    for (final marketWaypoint in marketWaypoints) {
      final distance = target.distanceTo(marketWaypoint);
      final producedGoods = {TradeSymbol.HYDROCARBON};
      final market =
          marketListings.marketListingForSymbol(marketWaypoint.waypointSymbol);
      final marketGoods = market?.tradeSymbols.toSet() ?? {};
      scores.add(
        SiphonScore(
          target: target.waypointSymbol,
          producedGoods: producedGoods,
          market: marketWaypoint.waypointSymbol,
          marketGoods: marketGoods,
          distanceBetween: distance.ceil(),
        ),
      );
    }
  }
  scores.sortBy<num>((m) => m.score);
  return scores;
}

/// TradeSymbols available for extraction based on WaypointTraits.
/// This is unlikely to be a correct/complete list.
/// This was created by reading the WaypointTrait descriptions.
final tradeSymbolsByTrait = {
  WaypointTraitSymbol.COMMON_METAL_DEPOSITS: [
    // Listed in trait descriptions:
    TradeSymbol.ALUMINUM_ORE,
    TradeSymbol.COPPER_ORE,
    TradeSymbol.IRON_ORE,
    // Seen in game:
    TradeSymbol.ICE_WATER,
    TradeSymbol.SILICON_CRYSTALS,
    TradeSymbol.QUARTZ_SAND,
  ],
  WaypointTraitSymbol.MINERAL_DEPOSITS: [
    // Listed in trait descriptions:
    TradeSymbol.SILICON_CRYSTALS,
    TradeSymbol.QUARTZ_SAND,
    // Seen in game:
    TradeSymbol.AMMONIA_ICE,
    TradeSymbol.ICE_WATER,
    TradeSymbol.IRON_ORE,
    TradeSymbol.PRECIOUS_STONES,
  ],
  WaypointTraitSymbol.PRECIOUS_METAL_DEPOSITS: [
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
  ],
  WaypointTraitSymbol.RARE_METAL_DEPOSITS: [
    // Listed in trait descriptions:
    TradeSymbol.URANITE_ORE,
    TradeSymbol.MERITIUM_ORE,
  ],
  WaypointTraitSymbol.FROZEN: [
    // Listed in trait descriptions:
    TradeSymbol.ICE_WATER,
    TradeSymbol.AMMONIA_ICE,
  ],
  WaypointTraitSymbol.ICE_CRYSTALS: [
    // Listed in trait descriptions:
    TradeSymbol.ICE_WATER,
    TradeSymbol.AMMONIA_ICE,
    TradeSymbol.LIQUID_HYDROGEN,
    TradeSymbol.LIQUID_NITROGEN,
  ],
  WaypointTraitSymbol.EXPLOSIVE_GASES: [
    // Listed in trait descriptions:
    TradeSymbol.HYDROCARBON,
  ],
  WaypointTraitSymbol.SWAMP: [
    // Listed in trait descriptions:
    TradeSymbol.HYDROCARBON,
  ],
  WaypointTraitSymbol.STRONG_MAGNETOSPHERE: [
    // Listed in trait descriptions:
    TradeSymbol.EXOTIC_MATTER,
    TradeSymbol.GRAVITON_EMITTERS,
  ],
};
