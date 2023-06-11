import 'dart:convert';

import 'package:file/file.dart';
import 'package:space_traders_api/api.dart';

/// Record of a historcial survey.
class ValuedSurvey {
  /// Create a HistoricalSurvey
  ValuedSurvey({
    required this.timestamp,
    required this.survey,
    required this.estimatedValue,
  });

  /// Create a HistoricalSurvey from JSON.
  factory ValuedSurvey.fromJson(Map<String, dynamic> json) {
    return ValuedSurvey(
      timestamp: DateTime.parse(json['timestamp'] as String),
      survey: Survey.fromJson(json['survey'] as Map<String, dynamic>)!,
      estimatedValue: json['estimatedValue'] as int,
    );
  }

  /// The timestamp of the survey.
  final DateTime timestamp;

  /// The survey.
  final Survey survey;

  /// The estimated value of the survey.
  final int estimatedValue;

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toUtc().toIso8601String(),
      'survey': survey.toJson(),
      'estimatedValue': estimatedValue,
    };
  }
}

/// The data store for historical surveys.
class SurveyData {
  /// Create a SurveyData.
  SurveyData({
    required List<ValuedSurvey> surveys,
    required FileSystem fs,
    String cacheFilePath = defaultCacheFilePath,
  })  : _surveys = surveys,
        _fs = fs,
        _cacheFilePath = cacheFilePath;

  final List<ValuedSurvey> _surveys;
  final FileSystem _fs;
  final String _cacheFilePath;

  /// The default path to the cache file.
  static const String defaultCacheFilePath = 'surveys.json';

  static List<ValuedSurvey> _parseSurveys(String json) {
    final parsed = jsonDecode(json) as List<dynamic>;
    return parsed
        .map<ValuedSurvey>(
          (e) => ValuedSurvey.fromJson(e as Map<String, dynamic>),
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
  Future<void> addSurveys(Iterable<ValuedSurvey> survey) async {
    _surveys.addAll(survey);
    await save();
  }

  /// Return the most recent surveys.
  List<ValuedSurvey> recentSurveys({int count = 10}) {
    if (_surveys.length < count) {
      return _surveys;
    }
    return _surveys.sublist(_surveys.length - count);
  }

  /// Return the percentile for the given estimated value.
  int? percentileFor(int estimatedValue) {
    final recent = recentSurveys();
    if (recent.isEmpty) {
      return null;
    }
    final values = recent.map((e) => e.estimatedValue).toList()..sort();
    final index = values.indexWhere((e) => e > estimatedValue);
    if (index == -1) {
      return 100;
    }
    return (index / values.length * 100).round();
  }
}
