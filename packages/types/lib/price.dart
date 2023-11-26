import 'package:types/types.dart';

class PriceBase<Symbol> {
  /// Create a new price record.
  const PriceBase({
    required this.waypointSymbol,
    required this.symbol,
    required this.timestamp,
  });

  final WaypointSymbol waypointSymbol;
  final Symbol symbol;
  final DateTime timestamp;
}
