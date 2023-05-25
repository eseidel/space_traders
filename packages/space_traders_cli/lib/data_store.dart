import 'dart:async';

import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/behavior/behavior.dart';

/// A simple data store that uses Sembast to store data in a JSON file.
class DataStore {
  /// Creates a new data store that will store data in the given [path].
  DataStore({this.path = 'datastore.json'});

  /// The database that stores the data.
  late Database db;

  /// The path to the database.
  final String path;

  /// Initializes the data store.
  Future<void> open() async {
    db = await databaseFactoryIo.openDatabase(path);
  }

  /// closes the data store.
  Future<void> close() {
    return db.close();
  }
}

/// A survey of a single location.
class SurveySet {
  /// Creates a new survey set.
  const SurveySet({required this.waypointSymbol, required this.surveys});

  /// Creates a survey set from JSON.
  factory SurveySet.fromJson(Map<String, dynamic> json) {
    final surveys = (json['surveys'] as List<dynamic>)
        .map((s) => Survey.fromJson(s as Map<String, dynamic>)!)
        .toList();
    return SurveySet(
      waypointSymbol: json['waypointSymbol'] as String,
      surveys: surveys,
    );
  }

  /// The symbol of the location.
  final String waypointSymbol;

  /// The surveys of the location.
  final List<Survey> surveys;

  // This is a bit conservative, but we want to avoid the race of we think
  // the survey is still valid, but the server disagrees.
  /// Returns true if any of the surveys will expire in the next minute.
  bool expiresSoon() {
    final oneMinuteFromNow = DateTime.now().add(const Duration(seconds: 60));
    return surveys.any((s) => s.expiration.isBefore(oneMinuteFromNow));
  }

  // Hack around OpenAPI not generating a recursive toJson.
  Map<String, dynamic> _surveyToJson(Survey survey) {
    final json = survey.toJson();
    json['deposits'] = survey.deposits.map((d) => d.toJson()).toList();
    json['size'] = survey.size.toJson();
    return json;
  }

  /// Converts the survey set to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'waypointSymbol': waypointSymbol,
      'surveys': surveys.map(_surveyToJson).toList(),
    };
  }
}

/// Loads the most recent survey result from the data store if still valid
/// otherwise returns null.  Currently valid means "won't expire
/// in the next minute".
Future<SurveySet?> loadSurveySet(DataStore db, String waypointSymbol) async {
  final store = stringMapStoreFactory.store('surveys');
  final record = store.record(waypointSymbol);
  final value = await record.get(db.db);
  if (value == null) {
    return null;
  }
  final surveySet = SurveySet.fromJson(value);
  if (surveySet.expiresSoon()) {
    await record.delete(db.db);
    return null;
  }
  return surveySet;
}

/// Saves the given [surveySet] to the data store.
Future<void> saveSurveySet(DataStore db, SurveySet surveySet) async {
  final store = stringMapStoreFactory.store('surveys');
  await store.record(surveySet.waypointSymbol).put(db.db, surveySet.toJson());
}

/// Deletes the survey set for the given [waypointSymbol] from the data store.
Future<void> deleteSurveySet(DataStore db, String waypointSymbol) async {
  final store = stringMapStoreFactory.store('surveys');
  await store.record(waypointSymbol).delete(db.db);
}

/// Saves the passed [behaviorState] to the data store.
Future<void> saveBehaviorState(
  DataStore db,
  String shipId,
  BehaviorState behaviorState,
) async {
  final store = stringMapStoreFactory.store('behavior');
  await store.record(shipId).put(db.db, behaviorState.toJson());
}

/// Saves the passed [behaviorTimeouts] to the data store.
Future<void> saveBehaviorTimeouts(
  DataStore db,
  Map<Behavior, DateTime> behaviorTimeouts,
) {
  final store = stringMapStoreFactory.store('behavior');
  final jsonMap = behaviorTimeouts
      .map((k, v) => MapEntry(k.toJson(), v.toUtc().toIso8601String()));
  return store.record('timeout').put(db.db, jsonMap);
}

/// Loads the behavior timeouts from the data store.
Future<Map<Behavior, DateTime>?> loadBehaviorTimeouts(DataStore db) async {
  final store = stringMapStoreFactory.store('behavior');
  final jsonMap = await store.record('timeout').get(db.db);
  if (jsonMap == null) {
    return null;
  }
  return jsonMap.map(
    (k, v) => MapEntry(
      Behavior.fromJson(k),
      DateTime.parse(v! as String),
    ),
  );
}

/// Loads the behavior state for the given [shipId] from the data store.
Future<BehaviorState?> loadBehaviorState(DataStore db, String shipId) async {
  final store = stringMapStoreFactory.store('behavior');
  final record = store.record(shipId);
  final value = await record.get(db.db);
  if (value == null) {
    return null;
  }
  return BehaviorState.fromJson(value);
}

/// Deletes the behavior state for the given [shipId] from the data store.
Future<void> deleteBehaviorState(DataStore db, String shipId) async {
  final store = stringMapStoreFactory.store('behavior');
  await store.record(shipId).delete(db.db);
}
