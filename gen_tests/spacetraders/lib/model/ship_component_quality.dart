extension type ShipComponentQuality(double value) {
  factory ShipComponentQuality.fromJson(num json) =>
      ShipComponentQuality(json.toDouble());

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipComponentQuality? maybeFromJson(double? json) {
    if (json == null) {
      return null;
    }
    return ShipComponentQuality.fromJson(json);
  }

  double toJson() => value;
}
