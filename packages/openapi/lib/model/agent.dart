class Agent {
  Agent({
    required this.accountId,
    required this.symbol,
    required this.headquarters,
    required this.credits,
    required this.startingFaction,
    required this.shipCount,
  });

  factory Agent.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return Agent(
      accountId: json['accountId'] as String,
      symbol: json['symbol'] as String,
      headquarters: json['headquarters'] as String,
      credits: json['credits'] as int,
      startingFaction: json['startingFaction'] as String,
      shipCount: json['shipCount'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static Agent? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Agent.fromJson(json);
  }

  String accountId;
  String symbol;
  String headquarters;
  int credits;
  String startingFaction;
  int shipCount;

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'symbol': symbol,
      'headquarters': headquarters,
      'credits': credits,
      'startingFaction': startingFaction,
      'shipCount': shipCount,
    };
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    symbol,
    headquarters,
    credits,
    startingFaction,
    shipCount,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Agent &&
        accountId == other.accountId &&
        symbol == other.symbol &&
        headquarters == other.headquarters &&
        credits == other.credits &&
        startingFaction == other.startingFaction &&
        shipCount == other.shipCount;
  }
}
