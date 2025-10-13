/// The type of trade good (export, import, or exchange).
enum MarketTradeGoodType {
  EXPORT._('EXPORT'),
  IMPORT._('IMPORT'),
  EXCHANGE._('EXCHANGE');

  const MarketTradeGoodType._(this.value);

  /// Creates a MarketTradeGoodType from a json string.
  factory MarketTradeGoodType.fromJson(String json) {
    return MarketTradeGoodType.values.firstWhere(
      (value) => value.value == json,
      orElse: () =>
          throw FormatException('Unknown MarketTradeGoodType value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static MarketTradeGoodType? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return MarketTradeGoodType.fromJson(json);
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
