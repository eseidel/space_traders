import 'dart:async';

import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/logger.dart';

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

/// Loads the most recent survey result from the data store if still valid
/// otherwise returns null.  Currently valid means "won't expire
/// in the next minute".
Future<Survey?> loadSurvey(DataStore db, String waypointSymbol) async {
  final store = stringMapStoreFactory.store('surveys');
  final record = await store.record(waypointSymbol).get(db.db);
  if (record == null) {
    return null;
  }
  final survey = Survey.fromJson(record);
  if (survey == null) {
    logger.warn('Unable to parse survey for $waypointSymbol');
    return null;
  }
  // This is a bit conservative, but we want to avoid the race of we think
  // the survey is still valid, but the server disagrees.
  final oneMinuteFromNow = DateTime.now().add(const Duration(seconds: 60));
  if (survey.expiration.isBefore(oneMinuteFromNow)) {
    return null;
  }
  return null;
}

// Future<void> saveSurvey(DataStore db, Survey survey) async {
//   final store = stringMapStoreFactory.store('surveys');
//   await store.put(db.db, survey.toJson(), survey.symbol);
// }
