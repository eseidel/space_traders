import 'package:meta/meta.dart';
import 'package:types/api.dart';

/// A class to hold transaction data from construction delivery.
@immutable
class ConstructionDelivery {
  /// Deliver goods for construction.
  const ConstructionDelivery({
    required this.unitsDelivered,
    required this.tradeSymbol,
    required this.shipSymbol,
    required this.timestamp,
    required this.waypointSymbol,
  });

  /// The number of units delivered.
  final int unitsDelivered;

  /// The TradeSymbol of the units delivered.
  final TradeSymbol tradeSymbol;

  /// The ShipSymbol of the ship that performed the action.
  final ShipSymbol shipSymbol;

  /// The timestamp of the action.
  final DateTime timestamp;

  /// The location of the action.
  final WaypointSymbol waypointSymbol;
}
