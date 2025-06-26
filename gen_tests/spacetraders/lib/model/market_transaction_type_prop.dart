enum MarketTransactionTypeProp {
  purchase._('PURCHASE'),
  sell._('SELL');

  const MarketTransactionTypeProp._(this.value);

  factory MarketTransactionTypeProp.fromJson(String json) {
    return MarketTransactionTypeProp.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException(
        'Unknown MarketTransactionTypeProp value: $json',
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static MarketTransactionTypeProp? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return MarketTransactionTypeProp.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
