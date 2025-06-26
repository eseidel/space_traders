import 'package:meta/meta.dart';

@immutable
class GetStatus200ResponseLeaderboardsPropMostSubmittedChartsPropInner {
  const GetStatus200ResponseLeaderboardsPropMostSubmittedChartsPropInner({
    required this.agentSymbol,
    required this.chartCount,
  });

  factory GetStatus200ResponseLeaderboardsPropMostSubmittedChartsPropInner.fromJson(
    Map<String, dynamic> json,
  ) {
    return GetStatus200ResponseLeaderboardsPropMostSubmittedChartsPropInner(
      agentSymbol: json['agentSymbol'] as String,
      chartCount: json['chartCount'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetStatus200ResponseLeaderboardsPropMostSubmittedChartsPropInner?
  maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetStatus200ResponseLeaderboardsPropMostSubmittedChartsPropInner.fromJson(
      json,
    );
  }

  final String agentSymbol;
  final int chartCount;

  Map<String, dynamic> toJson() {
    return {'agentSymbol': agentSymbol, 'chartCount': chartCount};
  }

  @override
  int get hashCode => Object.hashAll([agentSymbol, chartCount]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other
            is GetStatus200ResponseLeaderboardsPropMostSubmittedChartsPropInner &&
        agentSymbol == other.agentSymbol &&
        chartCount == other.chartCount;
  }
}
