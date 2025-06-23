extension type ShipComponentCondition(double value) {
  factory ShipComponentCondition.fromJson(num json) =>
      ShipComponentCondition(json.toDouble());

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipComponentCondition? maybeFromJson(double? json) {
    if (json == null) {
      return null;
    }
    return ShipComponentCondition.fromJson(json);
  }

  double toJson() => value;
}
