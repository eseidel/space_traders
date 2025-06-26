import 'package:meta/meta.dart';

@immutable
class GetStatus200ResponseLeaderboardsPropMostCreditsPropInner {
  const GetStatus200ResponseLeaderboardsPropMostCreditsPropInner({
    required this.agentSymbol,
    required this.credits,
  });

  factory GetStatus200ResponseLeaderboardsPropMostCreditsPropInner.fromJson(
    Map<String, dynamic> json,
  ) {
    return GetStatus200ResponseLeaderboardsPropMostCreditsPropInner(
      agentSymbol: json['agentSymbol'] as String,
      credits: json['credits'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetStatus200ResponseLeaderboardsPropMostCreditsPropInner?
  maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetStatus200ResponseLeaderboardsPropMostCreditsPropInner.fromJson(
      json,
    );
  }

  final String agentSymbol;
  final int credits;

  Map<String, dynamic> toJson() {
    return {'agentSymbol': agentSymbol, 'credits': credits};
  }

  @override
  int get hashCode => Object.hashAll([agentSymbol, credits]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetStatus200ResponseLeaderboardsPropMostCreditsPropInner &&
        agentSymbol == other.agentSymbol &&
        credits == other.credits;
  }
}
