enum SurveySize {
  small._('SMALL'),
  moderate._('MODERATE'),
  large._('LARGE');

  const SurveySize._(this.value);

  factory SurveySize.fromJson(String json) {
    return SurveySize.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException('Unknown SurveySize value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static SurveySize? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return SurveySize.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
