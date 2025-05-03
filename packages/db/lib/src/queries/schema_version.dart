import 'package:db/src/query.dart';

/// Creates the schema_version table if it does not exist. This table is used
/// to store the current schema version of the database for migrations.
Query createSchemaVersionTableQuery() {
  // The id is used to ensure the table is a single row.
  return const Query('''
CREATE TABLE IF NOT EXISTS schema_version (
  id INTEGER PRIMARY KEY DEFAULT 1,
  version INTEGER NOT NULL,
  CONSTRAINT schema_version_single_row CHECK (id = 1)
)
''');
}

/// Returns the current database schema version.
Query selectCurrentSchemaVersionQuery() {
  return const Query('SELECT version FROM schema_version');
}

/// Upserts the schema version into the database.
Query upsertSchemaVersionQuery(int version) {
  return Query(
    'INSERT INTO schema_version (id, version) VALUES (1, $version) '
    'ON CONFLICT (id) DO UPDATE SET version = $version',
  );
}
