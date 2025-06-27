enum PetStatusProp {
  available._('available'),
  pending._('pending'),
  sold._('sold');

  const PetStatusProp._(this.value);

  factory PetStatusProp.fromJson(String json) {
    return PetStatusProp.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException('Unknown PetStatusProp value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static PetStatusProp? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return PetStatusProp.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
