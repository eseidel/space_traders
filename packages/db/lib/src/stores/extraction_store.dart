import 'package:db/db.dart';
import 'package:db/src/queries/extraction.dart';
import 'package:types/types.dart';

/// Store for extractions.
class ExtractionStore {
  /// Create a new extraction store.
  ExtractionStore(this._db);

  final Database _db;

  /// Return all extractions.
  Future<Iterable<ExtractionRecord>> all() async =>
      _db.queryMany(allExtractionsQuery(), extractionFromColumnMap);

  /// Insert an extraction into the database.
  Future<void> insert(ExtractionRecord extraction) async =>
      _db.execute(insertExtractionQuery(extraction));
}
