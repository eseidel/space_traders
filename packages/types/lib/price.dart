import 'package:equatable/equatable.dart';
import 'package:types/types.dart';

/// A price record.
abstract class PriceBase<Symbol extends Object> extends Equatable {
  /// Create a new price record.
  const PriceBase({
    required this.waypointSymbol,
    required this.symbol,
    required this.timestamp,
  });

  /// The waypoint where this price was recorded.
  final WaypointSymbol waypointSymbol;

  /// The symbol of the good.
  final Symbol symbol;

  /// The timestamp of the price.
  final DateTime timestamp;
}
