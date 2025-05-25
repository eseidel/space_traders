class PublicAgent {
  PublicAgent({
    required this.symbol,
    required this.headquarters,
    required this.credits,
    required this.startingFaction,
    required this.shipCount,
  });

  factory PublicAgent.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return PublicAgent(
      symbol: json['symbol'] as String,
      headquarters: json['headquarters'] as String,
      credits: json['credits'] as int,
      startingFaction: json['startingFaction'] as String,
      shipCount: json['shipCount'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static PublicAgent? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return PublicAgent.fromJson(json);
  }

  String symbol;
  String headquarters;
  int credits;
  String startingFaction;
  int shipCount;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'headquarters': headquarters,
      'credits': credits,
      'startingFaction': startingFaction,
      'shipCount': shipCount,
    };
  }
}
