import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:space_traders_cli/api.dart';

/// Record of a historcial survey.
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
      survey: Survey.fromJson(json['survey'] as Map<String, dynamic>)!,
      exhausted: json['exhausted'] as bool,
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

  /// Create a copy of this HistoricalSurvey with the given fields replaced.
  HistoricalSurvey copyWith({
    DateTime? timestamp,
    Survey? survey,
    bool? exhausted,
  }) {
    return HistoricalSurvey(
      timestamp: timestamp ?? this.timestamp,
      survey: survey ?? this.survey,
      exhausted: exhausted ?? this.exhausted,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    final surveyJson = survey.toJson();
    // Hack around openapi codegen not having recursive toJson.
    surveyJson['size'] = survey.size.toJson();
    surveyJson['deposits'] = survey.deposits.map((e) => e.toJson()).toList();
    return {
      'timestamp': timestamp.toUtc().toIso8601String(),
      'survey': surveyJson,
      'exhausted': exhausted,
    };
  }
}

/// The data store for historical surveys.
class SurveyData {
  /// Create a SurveyData.
  SurveyData({
    required List<HistoricalSurvey> surveys,
    required FileSystem fs,
    String cacheFilePath = defaultCacheFilePath,
  })  : _surveys = surveys,
        _fs = fs,
        _cacheFilePath = cacheFilePath;

  final List<HistoricalSurvey> _surveys;
  final FileSystem _fs;
  final String _cacheFilePath;

  /// The default path to the cache file.
  static const String defaultCacheFilePath = 'surveys.json';

  /// The surveys.
  @visibleForTesting
  List<HistoricalSurvey> get surveys => _surveys;

  static List<HistoricalSurvey> _parseSurveys(String json) {
    final parsed = jsonDecode(json) as List<dynamic>;
    return parsed
        .map<HistoricalSurvey>(
          (e) => HistoricalSurvey.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  /// Load the store.
  static Future<SurveyData> load(
    FileSystem fs, {
    String? cacheFilePath,
  }) async {
    final filePath = cacheFilePath ?? defaultCacheFilePath;
    final surveysFile = fs.file(filePath);
    if (surveysFile.existsSync()) {
      return SurveyData(
        surveys: _parseSurveys(await surveysFile.readAsString()),
        fs: fs,
        cacheFilePath: filePath,
      );
    }
    return SurveyData(
      surveys: [],
      fs: fs,
      cacheFilePath: filePath,
    );
  }

  /// Save the store.
  Future<void> save() async {
    final surveysFile = _fs.file(_cacheFilePath);
    await surveysFile.writeAsString(jsonEncode(_surveys));
  }

  /// Add a survey to the store.
  Future<void> addSurveys(Iterable<HistoricalSurvey> survey) async {
    _surveys.addAll(survey);
    await save();
  }

  /// Return the most recent surveys.
  Iterable<HistoricalSurvey> recentSurveysAtWaypoint({
    required int count,
    required String waypointSymbol,
  }) {
    return _surveys
        .where((e) => e.survey.symbol == waypointSymbol)
        .sortedBy((e) => e.timestamp)
        .reversed
        .take(count);
  }

  /// Record the given surveys.
  Future<void> recordSurveys(List<Survey> surveys) {
    final now = DateTime.now().toUtc();
    final historicalSurveys = surveys.map((e) {
      return HistoricalSurvey(
        timestamp: now,
        survey: e,
        exhausted: false,
      );
    }).toList();
    return addSurveys(historicalSurveys);
  }

  /// Mark the given survey as exhausted.
  Future<void> markSurveyExhausted(Survey survey) async {
    // Careful, "signature" is unique to the survey, but "symbol" is
    // the waypoint symbol.
    final index =
        _surveys.indexWhere((e) => e.survey.signature == survey.signature);
    if (index == -1) {
      throw ArgumentError('Survey not found: $survey');
    }
    _surveys[index] = _surveys[index].copyWith(exhausted: true);
    await save();
  }

  /// Return the percentile for the given estimated value.
  // int? percentileFor(int estimatedValue) {
  //   final recent = recentSurveys();
  //   if (recent.isEmpty) {
  //     return null;
  //   }
  //   final values = recent.map((e) => e.estimatedValue).toList()..sort();
  //   final index = values.indexWhere((e) => e > estimatedValue);
  //   if (index == -1) {
  //     return 100;
  //   }
  //   return (index / values.length * 100).round();
  // }
}
