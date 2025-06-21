enum PetStatus {
  available._('available'),
  pending._('pending'),
  sold._('sold');

  const PetStatus._(this.value);

  factory PetStatus.fromJson(String json) {
    return PetStatus.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException('Unknown PetStatus value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static PetStatus? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return PetStatus.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
