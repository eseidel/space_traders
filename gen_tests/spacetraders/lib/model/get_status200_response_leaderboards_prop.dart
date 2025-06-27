import 'package:meta/meta.dart';
import 'package:spacetraders/model/get_status200_response_leaderboards_prop_most_credits_prop_inner.dart';
import 'package:spacetraders/model/get_status200_response_leaderboards_prop_most_submitted_charts_prop_inner.dart';
import 'package:spacetraders/model_helpers.dart';

@immutable
class GetStatus200ResponseLeaderboardsProp {
  const GetStatus200ResponseLeaderboardsProp({
    List<GetStatus200ResponseLeaderboardsPropMostCreditsPropInner>? mostCredits,
    List<GetStatus200ResponseLeaderboardsPropMostSubmittedChartsPropInner>?
    mostSubmittedCharts,
  }) : mostCredits = mostCredits ?? const [],
       mostSubmittedCharts = mostSubmittedCharts ?? const [];

  factory GetStatus200ResponseLeaderboardsProp.fromJson(
    Map<String, dynamic> json,
  ) {
    return GetStatus200ResponseLeaderboardsProp(
      mostCredits: (json['mostCredits'] as List)
          .map<GetStatus200ResponseLeaderboardsPropMostCreditsPropInner>(
            (e) =>
                GetStatus200ResponseLeaderboardsPropMostCreditsPropInner.fromJson(
                  e as Map<String, dynamic>,
                ),
          )
          .toList(),
      mostSubmittedCharts: (json['mostSubmittedCharts'] as List)
          .map<
            GetStatus200ResponseLeaderboardsPropMostSubmittedChartsPropInner
          >(
            (e) =>
                GetStatus200ResponseLeaderboardsPropMostSubmittedChartsPropInner.fromJson(
                  e as Map<String, dynamic>,
                ),
          )
          .toList(),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetStatus200ResponseLeaderboardsProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return GetStatus200ResponseLeaderboardsProp.fromJson(json);
  }

  final List<GetStatus200ResponseLeaderboardsPropMostCreditsPropInner>
  mostCredits;
  final List<GetStatus200ResponseLeaderboardsPropMostSubmittedChartsPropInner>
  mostSubmittedCharts;

  Map<String, dynamic> toJson() {
    return {
      'mostCredits': mostCredits.map((e) => e.toJson()).toList(),
      'mostSubmittedCharts': mostSubmittedCharts
          .map((e) => e.toJson())
          .toList(),
    };
  }

  @override
  int get hashCode => Object.hashAll([mostCredits, mostSubmittedCharts]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetStatus200ResponseLeaderboardsProp &&
        listsEqual(mostCredits, other.mostCredits) &&
        listsEqual(mostSubmittedCharts, other.mostSubmittedCharts);
  }
}
