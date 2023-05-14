import 'package:space_traders_api/api.dart';

extension WaypointUtils on Waypoint {
  bool hasTrait(WaypointTraitSymbolEnum trait) {
    return traits.any((t) => t.symbol == trait);
  }

  bool isType(WaypointType type) {
    return this.type == type;
  }

  bool get isAsteroidField => isType(WaypointType.ASTEROID_FIELD);
  bool get hasShipyard => hasTrait(WaypointTraitSymbolEnum.SHIPYARD);
  // bool get hasMarketplace => hasTrait(WaypointTraitSymbolEnum.MARKETPLACE);
}

extension ShipUtils on Ship {
  int get spaceAvailable => cargo.capacity - cargo.units;

  bool get isExcavator => registration.role == ShipRole.EXCAVATOR;

  bool get isInTransit => nav.status == ShipNavStatus.IN_TRANSIT;
  bool get isDocked => nav.status == ShipNavStatus.DOCKED;
  bool get isOrbiting => nav.status == ShipNavStatus.IN_ORBIT;

  int get averageCondition {
    int total = 0;
    total += engine.condition ?? 100;
    total += frame.condition ?? 100;
    total += reactor.condition ?? 100;
    return total ~/ 3;
  }

  String get navStatusString {
    switch (nav.status) {
      case ShipNavStatus.DOCKED:
        return "Docked at ${nav.waypointSymbol}";
      case ShipNavStatus.IN_ORBIT:
        return "Orbiting ${nav.waypointSymbol}";
      case ShipNavStatus.IN_TRANSIT:
        return "In transit to ${nav.waypointSymbol}";
      default:
        return "Unknown";
    }
  }
}

// extension ContractUtils on Contract {
//   bool needsItem(String tradeSymbol) => goodNeeded(tradeSymbol) != null;

//   ContractDeliverGood? goodNeeded(String tradeSymbol) {
//     return terms.deliver
//         .firstWhereOrNull((item) => item.tradeSymbol == tradeSymbol);
//   }
// }
