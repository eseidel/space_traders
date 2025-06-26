enum ShipCrewRotationProp {
  strict._('STRICT'),
  relaxed._('RELAXED');

  const ShipCrewRotationProp._(this.value);

  factory ShipCrewRotationProp.fromJson(String json) {
    return ShipCrewRotationProp.values.firstWhere(
      (value) => value.value == json,
      orElse: () =>
          throw FormatException('Unknown ShipCrewRotationProp value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipCrewRotationProp? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ShipCrewRotationProp.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
