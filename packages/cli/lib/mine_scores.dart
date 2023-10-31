import 'package:cli/cache/caches.dart';
import 'package:collection/collection.dart';
import 'package:types/types.dart';

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
  final List<WaypointTraitSymbolEnum> mineTraits;

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
    return mineTraits
        .map((t) => tradeSymbolsByTrait[t] ?? [])
        .expand((e) => e)
        .toSet();
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
    return distanceBetweenMineAndMarket;
  }
}

/// Evaluate all possible Mine and Market pairings for a given system.
Future<List<MineScore>> evaluateWaypointsForMining(
  WaypointCache waypointCache,
  MarketCache marketCache,
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
          await marketCache.marketForSymbol(marketWaypoint.waypointSymbol);
      final marketGoods = market?.tradeSymbols.toSet() ?? {};
      mineAndSells.add(
        MineScore(
          mine: mine.waypointSymbol,
          mineTraits: mineTraits,
          market: marketWaypoint.waypointSymbol,
          tradedGoods: marketGoods,
          distanceBetweenMineAndMarket: distance,
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
Future<List<SiphonScore>> evaluteWaypointsForSiphoning(
  WaypointCache waypointCache,
  MarketCache marketCache,
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
          await marketCache.marketForSymbol(marketWaypoint.waypointSymbol);
      final marketGoods = market?.tradeSymbols.toSet() ?? {};
      scores.add(
        SiphonScore(
          target: target.waypointSymbol,
          producedGoods: producedGoods,
          market: marketWaypoint.waypointSymbol,
          marketGoods: marketGoods,
          distanceBetween: distance,
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
  WaypointTraitSymbolEnum.COMMON_METAL_DEPOSITS: [
    TradeSymbol.IRON_ORE,
    TradeSymbol.COPPER_ORE,
    TradeSymbol.ALUMINUM_ORE,
  ],
  WaypointTraitSymbolEnum.MINERAL_DEPOSITS: [
    TradeSymbol.SILICON_CRYSTALS,
    TradeSymbol.QUARTZ_SAND,
  ],
  WaypointTraitSymbolEnum.PRECIOUS_METAL_DEPOSITS: [
    TradeSymbol.PLATINUM_ORE,
    TradeSymbol.GOLD_ORE,
    TradeSymbol.SILVER_ORE,
  ],
  WaypointTraitSymbolEnum.RARE_METAL_DEPOSITS: [
    TradeSymbol.URANITE_ORE,
    TradeSymbol.MERITIUM_ORE,
  ],
  WaypointTraitSymbolEnum.FROZEN: [
    TradeSymbol.ICE_WATER,
    TradeSymbol.AMMONIA_ICE,
  ],
  WaypointTraitSymbolEnum.ICE_CRYSTALS: [
    TradeSymbol.ICE_WATER,
    TradeSymbol.AMMONIA_ICE,
    TradeSymbol.LIQUID_HYDROGEN,
    TradeSymbol.LIQUID_NITROGEN,
  ],
  WaypointTraitSymbolEnum.EXPLOSIVE_GASES: [
    TradeSymbol.HYDROCARBON,
  ],
  WaypointTraitSymbolEnum.SWAMP: [
    TradeSymbol.HYDROCARBON,
  ],
  WaypointTraitSymbolEnum.STRONG_MAGNETOSPHERE: [
    TradeSymbol.EXOTIC_MATTER,
    TradeSymbol.GRAVITON_EMITTERS,
  ],
};
