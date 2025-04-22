import 'package:dart_frog/dart_frog.dart';
import 'package:db/db.dart';
import 'package:server/read_async.dart';
import 'package:protocol/protocol.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = await context.readAsync<Database>();
  // final fs = await context.readAsync<FileSystem>();

  final agent = (await db.getMyAgent())!;
  final ships = await db.allShips();

  // final systemsCache = SystemsCache.load(fs);
  // final jumpGate = systemsCache.jumpGateWaypointForSystem(
  //   agent.headquarters.system,
  // );

  final status = AgentStatusResponse(
    name: agent.symbol,
    faction: agent.startingFaction.toString(),
    numberOfShips: ships.length,
    cash: agent.credits.toDouble(),
    totalAssets: 0,
    gateOpen: false,
  );
  return Response.json(body: status.toJson());
}
