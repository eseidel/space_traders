import 'package:types/types.dart';

/// Record of a historical survey.
// This can't be @immutable because Survey is not.
class HistoricalSurvey {
  /// Create a HistoricalSurvey
  HistoricalSurvey({
    required this.timestamp,
    required this.survey,
    required this.exhausted,
  });

  /// Create a HistoricalSurvey from JSON.
  factory HistoricalSurvey.fromJson(Map<String, dynamic> json) {
    return HistoricalSurvey(
      timestamp: DateTime.parse(json['timestamp'] as String),
      survey: Survey.fromJson(json['survey'] as Map<String, dynamic>),
      exhausted: json['exhausted'] as bool,
    );
  }

  /// Create a fallback value.
  factory HistoricalSurvey.fallbackValue() {
    return HistoricalSurvey(
      timestamp: DateTime.now(),
      survey: Survey(
        signature: 'signature',
        symbol: const WaypointSymbol.fallbackValue().waypoint,
        deposits: [SurveyDeposit(symbol: TradeSymbol.DIAMONDS)],
        expiration: DateTime.now(),
        size: SurveySize.SMALL,
      ),
      exhausted: false,
    );
  }

  /// The survey.
  final Survey survey;

  /// The timestamp of the survey.
  final DateTime timestamp;

  /// The survey is exhausted.
  // Unclear if this should be saved in this class or not, it's the
  // only mutable value.
  final bool exhausted;

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    final surveyJson = survey.toJson();
    // Hack around openapi codegen not having recursive toJson.
    surveyJson['size'] = survey.size.toJson();
    Json depositToJson(SurveyDeposit deposit) {
      final json = deposit.toJson();
      json['symbol'] = deposit.symbol.toJson();
      return json;
    }

    surveyJson['deposits'] = survey.deposits.map(depositToJson).toList();
    return {
      'timestamp': timestamp.toUtc().toIso8601String(),
      'survey': surveyJson,
      'exhausted': exhausted,
    };
  }
}
