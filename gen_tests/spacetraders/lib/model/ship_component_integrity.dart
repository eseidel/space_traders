extension type ShipComponentIntegrity(double value) {
  factory ShipComponentIntegrity.fromJson(num json) =>
      ShipComponentIntegrity(json.toDouble());

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipComponentIntegrity? maybeFromJson(double? json) {
    if (json == null) {
      return null;
    }
    return ShipComponentIntegrity.fromJson(json);
  }

  double toJson() => value;
}
