import 'package:file/local.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final waypointCache = WaypointCache(api);

  final myShips = await allMyShips(api).toList();
  final ship = await chooseShip(api, waypointCache, myShips);

  final response = await api.fleet.negotiateContract(ship.symbol);
  final contract = response!.data;
  logger.info(contract.toString());
}