import 'dart:async';

import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

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
