enum ShipNavStatus {
  inTransit._('IN_TRANSIT'),
  inOrbit._('IN_ORBIT'),
  docked._('DOCKED');

  const ShipNavStatus._(this.value);

  factory ShipNavStatus.fromJson(String json) {
    return ShipNavStatus.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException('Unknown ShipNavStatus value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipNavStatus? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ShipNavStatus.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
