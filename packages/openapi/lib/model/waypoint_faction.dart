import 'package:openapi/model/faction_symbol.dart';

class WaypointFaction {
  WaypointFaction({required this.symbol});

  factory WaypointFaction.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return WaypointFaction(
      symbol: FactionSymbol.fromJson(json['symbol'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static WaypointFaction? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return WaypointFaction.fromJson(json);
  }

  FactionSymbol symbol;

  Map<String, dynamic> toJson() {
    return {'symbol': symbol.toJson()};
  }
}
