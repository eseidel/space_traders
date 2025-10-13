/// The size of the deposit. This value indicates how much can be extracted from
/// the survey before it is exhausted.
enum SurveySize {
  SMALL._('SMALL'),
  MODERATE._('MODERATE'),
  LARGE._('LARGE');

  const SurveySize._(this.value);

  /// Creates a SurveySize from a json string.
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

  /// The value of the enum, as a string.  This is the exact value
  /// from the OpenAPI spec and will be used for network transport.
  final String value;

  /// Converts the enum to a json string.
  String toJson() => value;

  /// Returns the string value of the enum.
  @override
  String toString() => value;
}
