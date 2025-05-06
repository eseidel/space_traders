import 'package:db/db.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('migration', (server) {
    test('migration', () async {
      final endpoint = await server.endpoint();
      final db = Database.testLive(
        endpoint: endpoint,
        connection: await server.newConnection(),
      );

      final schemaVersion = await db.currentSchemaVersion();
      expect(schemaVersion, isNull);

      final emptyTables = await db.allTableNames();
      expect(emptyTables.length, equals(0));
      await db.migrateToLatestSchema();
      final latestTables = await db.allTableNames();
      expect(latestTables.length, greaterThan(emptyTables.length));

      final latestVersion = await db.currentSchemaVersion();
      expect(latestVersion, greaterThan(0));

      await db.migrateToSchema(version: 0);
      final revertedTables = await db.allTableNames();
      // Schema version sticks around even if we revert to version 0.
      expect(revertedTables, equals(['schema_version', ...emptyTables]));

      final revertedVersion = await db.currentSchemaVersion();
      expect(revertedVersion, equals(0));

      await db.migrateToLatestSchema();
      final latestTables2 = await db.allTableNames();
      expect(latestTables2.length, equals(latestTables.length));

      final latestVersion2 = await db.currentSchemaVersion();
      expect(latestVersion2, equals(latestVersion));
    });
  });
}
