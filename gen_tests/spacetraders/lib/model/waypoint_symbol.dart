extension type WaypointSymbol(String value) {
  factory WaypointSymbol.fromJson(String json) => WaypointSymbol(json);

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static WaypointSymbol? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return WaypointSymbol.fromJson(json);
  }

  String toJson() => value;
}
