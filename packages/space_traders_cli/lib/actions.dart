import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';

Future<PurchaseShip201ResponseData> purchaseShip(
    Api api, ShipType shipType, String shipyardSymbol) async {
  PurchaseShipRequest purchaseShipRequest = PurchaseShipRequest(
    waypointSymbol: shipyardSymbol,
    shipType: shipType,
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
