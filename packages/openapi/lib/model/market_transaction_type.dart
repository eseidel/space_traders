/// The type of transaction.
enum MarketTransactionType {
  PURCHASE._('PURCHASE'),
  SELL._('SELL');

  const MarketTransactionType._(this.value);

  /// Creates a MarketTransactionType from a json string.
  factory MarketTransactionType.fromJson(String json) {
    return MarketTransactionType.values.firstWhere(
      (value) => value.value == json,
      orElse: () =>
          throw FormatException('Unknown MarketTransactionType value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static MarketTransactionType? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return MarketTransactionType.fromJson(json);
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
