import 'package:db/db.dart';
import 'package:db/src/queue.dart';
import 'package:test/test.dart';
import 'package:types/queue.dart';

import '../docker.dart';

void main() {
  withPostgresServer('network_store', (server) {
    group('foo', () {
      late Database db;
      setUpAll(() async {
        final endpoint = await server.endpoint();
        db = Database.testLive(
          endpoint: endpoint,
          connection: await server.newConnection(),
        );
        await db.migrateToLatestSchema();
      });

      setUp(() async {
        await db.migrateToSchema(version: 0);
        await db.migrateToLatestSchema();
      });

      test('insert', () async {
        const request = RequestRecord(
          id: 1,
          request: QueuedRequest(
            url: 'https://example.com',
            method: 'GET',
            headers: {},
            body: '',
          ),
          priority: 1,
        );
        await db.network.insertRequest(request);

        final nextRequest = await db.network.nextRequest();
        expect(nextRequest, request);
      });
    });
  });
}
