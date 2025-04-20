import 'package:json_annotation/json_annotation.dart';

part 'get_fleet_response.g.dart';

// void logShip(
//   SystemsCache systemsCache,
//   MarketPriceSnapshot marketPrices,
//   Ship ship,
//   BehaviorState? behavior,
// ) {
//   const indent = '   ';
//   final waypoint = systemsCache.waypoint(ship.waypointSymbol);
//   final cargoStatus =
//       ship.cargo.capacity == 0
//           ? ''
//           : '${ship.cargo.units}/${ship.cargo.capacity}';
//   logger.info(
//     '${ship.symbol.hexNumber} '
//     '${_behaviorOrTypeString(ship, behavior)} $cargoStatus',
//   );
//   if (ship.cargo.isNotEmpty) {
//     logger.info(
//       describeInventory(marketPrices, ship.cargo.inventory, indent: indent),
//     );
//   }
//   final routePlan = behavior?.routePlan;
//   if (routePlan != null) {
//     final timeLeft = ship.timeToArrival(routePlan);
//     final destination = routePlan.endSymbol.sectorLocalName;
//     final destinationType = systemsCache.waypoint(routePlan.endSymbol).type;
//     final arrival = approximateDuration(timeLeft);
//     logger.info(
//       '${indent}en route to $destination $destinationType '
//       'in $arrival',
//     );
//   } else {
//     logger.info('$indent${describeShipNav(ship.nav)} ${waypoint.type}');
//   }
//   final deal = behavior?.deal;
//   if (deal != null) {
//     logger.info('$indent${describeCostedDeal(deal)}');
//     final since = DateTime.timestamp().difference(deal.startTime);
//     logger.info('${indent}duration: ${approximateDuration(since)}');
//   }
// }

@JsonSerializable()
class PricedItem {
  PricedItem({
    required this.symbol,
    required this.pricePerUnit,
    required this.units,
    required this.totalPrice,
  });

  factory PricedItem.fromJson(Map<String, dynamic> json) =>
      _$PricedItemFromJson(json);
  String symbol;
  int pricePerUnit;
  int units;
  int totalPrice;

  Map<String, dynamic> toJson() => _$PricedItemToJson(this);
}

@JsonSerializable()
class Cargo {
  Cargo({required this.capacity, required this.units, required this.inventory});

  factory Cargo.fromJson(Map<String, dynamic> json) => _$CargoFromJson(json);
  int capacity;
  int units;
  List<PricedItem> inventory;

  Map<String, dynamic> toJson() => _$CargoToJson(this);
}

@JsonSerializable()
class RoutePlan {
  RoutePlan({required this.waypointSymbol, required this.timeToArrival});

  factory RoutePlan.fromJson(Map<String, dynamic> json) =>
      _$RoutePlanFromJson(json);
  String waypointSymbol;
  int timeToArrival;

  Map<String, dynamic> toJson() => _$RoutePlanToJson(this);
}

@JsonSerializable()
class FleetShip {
  FleetShip({required this.symbol, required this.route, required this.cargo});

  factory FleetShip.fromJson(Map<String, dynamic> json) =>
      _$FleetShipFromJson(json);
  String symbol;
  RoutePlan route;
  Cargo cargo;

  Map<String, dynamic> toJson() => _$FleetShipToJson(this);
}

@JsonSerializable()
class GetFleetResponse {
  GetFleetResponse({required this.ships});

  factory GetFleetResponse.fromJson(Map<String, dynamic> json) =>
      _$GetFleetResponseFromJson(json);

  List<FleetShip> ships;

  Map<String, dynamic> toJson() => _$GetFleetResponseToJson(this);
}
