import 'package:dart_frog/dart_frog.dart';
import 'package:db/db.dart';
import 'package:protocol/protocol.dart';
import 'package:server/read_async.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = await context.readAsync<Database>();
  final ships = await db.allShips();
  final fleetShipsResponse = FleetShipsResponse(ships: ships.toList());
  return Response.json(body: fleetShipsResponse.toJson());
}
