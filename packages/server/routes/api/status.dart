import 'package:dart_frog/dart_frog.dart';
import 'package:db/db.dart';
import 'package:server/read_async.dart';

class StatusResponse {
  StatusResponse({
    required this.name,
    required this.faction,
    required this.numberOfShips,
    required this.cash,
    required this.totalAssets,
    required this.gateOpen,
  });
  final String name;
  final String faction;
  final int numberOfShips;
  final double cash;
  final double totalAssets;
  final bool gateOpen;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'faction': faction,
      'numberOfShips': numberOfShips,
      'cash': cash,
      'totalAssets': totalAssets,
      'gateOpen': gateOpen,
    };
  }
}

Future<Response> onRequest(RequestContext context) async {
  final db = await context.readAsync<Database>();
  // final fs = await context.readAsync<FileSystem>();

  final agent = (await db.getMyAgent())!;
  final ships = await db.allShips();

  // final systemsCache = SystemsCache.load(fs);
  // final jumpGate = systemsCache.jumpGateWaypointForSystem(
  //   agent.headquarters.system,
  // );

  final status = StatusResponse(
    name: agent.symbol,
    faction: agent.startingFaction.toString(),
    numberOfShips: ships.length,
    cash: agent.credits.toDouble(),
    totalAssets: 0,
    gateOpen: false,
  );
  return Response.json(body: status.toJson());
}
