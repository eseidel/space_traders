class WaypointOrbital {
  WaypointOrbital({required this.symbol});

  factory WaypointOrbital.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return WaypointOrbital(symbol: json['symbol'] as String);
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static WaypointOrbital? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return WaypointOrbital.fromJson(json);
  }

  String symbol;

  Map<String, dynamic> toJson() {
    return {'symbol': symbol};
  }
}
