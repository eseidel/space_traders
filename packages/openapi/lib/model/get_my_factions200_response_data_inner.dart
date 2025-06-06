class GetMyFactions200ResponseDataInner {
  GetMyFactions200ResponseDataInner({
    required this.symbol,
    required this.reputation,
  });

  factory GetMyFactions200ResponseDataInner.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetMyFactions200ResponseDataInner(
      symbol: json['symbol'] as String,
      reputation: json['reputation'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetMyFactions200ResponseDataInner? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return GetMyFactions200ResponseDataInner.fromJson(json);
  }

  String symbol;
  int reputation;

  Map<String, dynamic> toJson() {
    return {'symbol': symbol, 'reputation': reputation};
  }

  @override
  int get hashCode => Object.hash(symbol, reputation);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetMyFactions200ResponseDataInner &&
        symbol == other.symbol &&
        reputation == other.reputation;
  }
}
