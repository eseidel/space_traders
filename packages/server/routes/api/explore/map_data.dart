import 'package:cli/caches.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:db/db.dart';
import 'package:protocol/protocol.dart';
import 'package:server/read_async.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = await context.readAsync<Database>();
  final fs = context.read<FileSystem>();

  final systemsCache = SystemsCache.load(fs);
  final shipSnapshot = await ShipSnapshot.load(db);
  final response = GetMapDataResponse(
    ships: shipSnapshot.ships,
    systems: systemsCache.systems,
  );

  return Response.json(body: response.toJson());
}
