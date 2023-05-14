import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/extensions.dart';

Future<PurchaseShip201ResponseData> purchaseMiningShip(
    Api api, List<Waypoint> systemWaypoints) async {
  final shipyardWaypoint = systemWaypoints.firstWhere((w) => w.hasShipyard);
  PurchaseShipRequest purchaseShipRequest = PurchaseShipRequest(
    waypointSymbol: shipyardWaypoint.symbol,
    shipType: ShipType.MINING_DRONE,
  );
  final purchaseResponse =
      await api.fleet.purchaseShip(purchaseShipRequest: purchaseShipRequest);
  return purchaseResponse!.data;
}

Future<NavigateShip200ResponseData> navigateTo(
    Api api, Ship ship, Waypoint waypoint) async {
  final request = NavigateShipRequest(waypointSymbol: waypoint.symbol);
  final result =
      await api.fleet.navigateShip(ship.symbol, navigateShipRequest: request);
  return result!.data;
}
