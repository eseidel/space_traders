import 'package:cli/caches.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:db/db.dart';
import 'package:protocol/protocol.dart';
import 'package:server/read_async.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = await context.readAsync<Database>();
  final fs = context.read<FileSystem>();

  final agent = (await db.getMyAgent())!;
  final ships = await db.allShips();

  final systemsCache = SystemsCache.load(fs);
  final jumpGate =
      systemsCache.jumpGateWaypointForSystem(agent.headquarters.system)!;

  final constructionCache = ConstructionCache(db);
  final underConstruction = await constructionCache.isUnderConstruction(
    jumpGate.symbol,
  );

  final status = AgentStatusResponse(
    name: agent.symbol,
    faction: agent.startingFaction.toString(),
    numberOfShips: ships.length,
    cash: agent.credits,
    totalAssets: 0,
    gateOpen: underConstruction ?? true,
  );
  return Response.json(body: status.toJson());
}
