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

      test('request', () async {
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

        expect(await db.network.getRequest(request.id!), request);

        final nextRequest = await db.network.nextRequest();
        expect(nextRequest, request);

        await db.network.deleteRequest(request);

        await expectLater(
          () => db.network.deleteRequest(request),
          throwsStateError,
        );

        expect(await db.network.getRequest(request.id!), isNull);
      });

      test('response', () async {
        const response = ResponseRecord(
          id: 1,
          requestId: 1,
          response: QueuedResponse(body: 'body', statusCode: 200, headers: {}),
        );
        await db.network.insertResponse(response);

        // Get can be called multiple times.
        expect(
          await db.network.getResponseForRequest(response.requestId),
          response,
        );
        expect(
          await db.network.getResponseForRequest(response.requestId),
          response,
        );

        final now = DateTime.timestamp();
        await db.network.deleteResponsesBefore(now);
        // After deleting, the response is no longer available.
        expect(
          await db.network.getResponseForRequest(response.requestId),
          isNull,
        );
      });
    });
  });
}
