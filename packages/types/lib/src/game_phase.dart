import 'package:types/enum.dart';

/// Which game phase are we in.
enum GamePhase with EnumIndexOrdering {
  /// Initially just buying haulers and getting trading going.
  bootstrap,

  /// Focused on building the jumpgate.
  construction,

  /// Focused on exploring the galaxy to find better ships.
  exploration,

  /// Sell off all our ships and retire.
  selloff
}
