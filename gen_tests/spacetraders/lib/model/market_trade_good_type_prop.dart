enum MarketTradeGoodTypeProp {
  export._('EXPORT'),
  import._('IMPORT'),
  exchange._('EXCHANGE');

  const MarketTradeGoodTypeProp._(this.value);

  factory MarketTradeGoodTypeProp.fromJson(String json) {
    return MarketTradeGoodTypeProp.values.firstWhere(
      (value) => value.value == json,
      orElse: () =>
          throw FormatException('Unknown MarketTradeGoodTypeProp value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static MarketTradeGoodTypeProp? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return MarketTradeGoodTypeProp.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
