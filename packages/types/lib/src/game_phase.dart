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
  selloff;

  /// Create a GamePhase from json.
  static GamePhase fromJson(String json) {
    // TODO(eseidel): Remove on next reset.
    final value = json.startsWith('GamePhase.') ? json.substring(10) : json;
    return values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Invalid json for GamePhase'),
    );
  }

  /// Convert the GamePhase to json.
  String toJson() => name;
}
