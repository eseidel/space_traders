import 'package:cli/config.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:db/db.dart';
import 'package:protocol/protocol.dart';
import 'package:server/read_async.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = await context.readAsync<Database>();

  final agent = (await db.getMyAgent())!;
  final ships = await db.allShips();

  final jumpGate = await db.systems.jumpGateWaypointForSystem(
    agent.headquarters.system,
  );

  final underConstruction = await db.construction.isUnderConstruction(
    jumpGate!.symbol,
  );
  final config = await Config.fromDb(db);

  final status = AgentStatusResponse(
    name: agent.symbol,
    faction: agent.startingFaction.toString(),
    numberOfShips: ships.length,
    cash: agent.credits,
    gamePhase: config.gamePhase,
    gateOpen: underConstruction == false,
  );
  return Response.json(body: status.toJson());
}
