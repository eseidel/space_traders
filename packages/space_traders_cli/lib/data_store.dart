import 'dart:async';

import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
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
