import 'package:types/types.dart';

class DealsNearbyResponse {
  DealsNearbyResponse({
    required this.deals,
    required this.shipType,
    required this.shipSpec,
    required this.startSymbol,
    required this.credits,
    required this.extraSellOpps,
    required this.tradeSymbolCount,
  });

  final List<NearbyDeal> deals;
  final ShipType shipType;
  final ShipSpec shipSpec;
  final WaypointSymbol startSymbol;
  final int credits;
  final List<SellOpp> extraSellOpps;
  final int tradeSymbolCount;
}

class NearbyDeal {
  NearbyDeal({required this.costed, required this.inProgress});

  final CostedDeal costed;
  final bool inProgress;

  Deal get deal => costed.deal;
}
