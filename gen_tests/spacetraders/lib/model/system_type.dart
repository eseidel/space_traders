enum SystemType {
  neutronStar._('NEUTRON_STAR'),
  redStar._('RED_STAR'),
  orangeStar._('ORANGE_STAR'),
  blueStar._('BLUE_STAR'),
  youngStar._('YOUNG_STAR'),
  whiteDwarf._('WHITE_DWARF'),
  blackHole._('BLACK_HOLE'),
  hypergiant._('HYPERGIANT'),
  nebula._('NEBULA'),
  unstable._('UNSTABLE');

  const SystemType._(this.value);

  factory SystemType.fromJson(String json) {
    return SystemType.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException('Unknown SystemType value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static SystemType? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return SystemType.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
