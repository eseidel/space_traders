enum FindPetsByStatusParameter0 {
  available._('available'),
  pending._('pending'),
  sold._('sold');

  const FindPetsByStatusParameter0._(this.value);

  factory FindPetsByStatusParameter0.fromJson(String json) {
    return FindPetsByStatusParameter0.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException(
        'Unknown FindPetsByStatusParameter0 value: $json',
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static FindPetsByStatusParameter0? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return FindPetsByStatusParameter0.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
