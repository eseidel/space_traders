class GetStatus200ResponseLeaderboardsMostSubmittedChartsInner {
  GetStatus200ResponseLeaderboardsMostSubmittedChartsInner({
    required this.agentSymbol,
    required this.chartCount,
  });

  factory GetStatus200ResponseLeaderboardsMostSubmittedChartsInner.fromJson(
    dynamic jsonArg,
  ) {
    final json = jsonArg as Map<String, dynamic>;
    return GetStatus200ResponseLeaderboardsMostSubmittedChartsInner(
      agentSymbol: json['agentSymbol'] as String,
      chartCount: json['chartCount'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetStatus200ResponseLeaderboardsMostSubmittedChartsInner?
  maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetStatus200ResponseLeaderboardsMostSubmittedChartsInner.fromJson(
      json,
    );
  }

  String agentSymbol;
  int chartCount;

  Map<String, dynamic> toJson() {
    return {'agentSymbol': agentSymbol, 'chartCount': chartCount};
  }
}
