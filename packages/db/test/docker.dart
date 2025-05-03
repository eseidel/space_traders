// cspell:words snakeoil
import 'dart:async';
import 'dart:io';

import 'package:docker_process/containers/postgres.dart';
import 'package:meta/meta.dart';
import 'package:postgres/postgres.dart';
import 'package:postgres/src/v3/connection.dart';
import 'package:test/test.dart';

class PostgresServer {
  PostgresServer();
  final _port = Completer<int>();
  final _containerName = Completer<String>();

  Future<int> get port => _port.future;

  Future<Endpoint> endpoint() async => Endpoint(
    host: 'localhost',
    database: 'postgres',
    username: 'postgres',
    password: 'postgres',
    port: await port,
  );

  Future<Connection> newConnection({
    ReplicationMode replicationMode = ReplicationMode.none,
    SslMode? sslMode,
    QueryMode? queryMode,
  }) async {
    return PgConnectionImplementation.connect(
      await endpoint(),
      connectionSettings: ConnectionSettings(
        connectTimeout: const Duration(seconds: 3),
        queryTimeout: const Duration(seconds: 3),
        replicationMode: replicationMode,
        sslMode: sslMode,
        queryMode: queryMode,
      ),
    );
  }

  Future<void> kill() async {
    await Process.run('docker', ['kill', await _containerName.future]);
  }
}

@isTestGroup
void withPostgresServer(
  String groupName,
  void Function(PostgresServer server) fn,
) {
  group(groupName, () {
    final server = PostgresServer();

    setUpAll(() async {
      try {
        final port = await selectFreePort();
        final containerName = 'postgres-dart-test-$port';
        await _startPostgresContainer(port: port, containerName: containerName);

        server._containerName.complete(containerName);
        server._port.complete(port);
      } catch (e, st) {
        server._containerName.completeError(e, st);
        server._port.completeError(e, st);
        rethrow;
      }
    });

    tearDownAll(() async {
      final containerName = await server._containerName.future;
      await Process.run('docker', ['stop', containerName]);
      await Process.run('docker', ['kill', containerName]);
    });

    fn(server);
  });
}

Future<int> selectFreePort() async {
  final socket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

Future<void> _startPostgresContainer({
  required int port,
  required String containerName,
}) async {
  if (await _isPostgresContainerRunning(containerName)) {
    return;
  }

  await startPostgres(
    name: containerName,
    version: 'latest',
    pgPort: port,
    pgDatabase: 'postgres',
    pgUser: 'postgres',
    cleanup: true,
    configurations: [
      // SSL settings
      'ssl=on',
      // The debian image includes a self-signed SSL cert that can be used:
      'ssl_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem',
      'ssl_key_file=/etc/ssl/private/ssl-cert-snakeoil.key',
    ],
  );
}

Future<bool> _isPostgresContainerRunning(String containerName) async {
  final pr = await Process.run('docker', ['ps', '--format', '{{.Names}}']);
  return pr.stdout
      .toString()
      .split('\n')
      .map((s) => s.trim())
      .contains(containerName);
}
