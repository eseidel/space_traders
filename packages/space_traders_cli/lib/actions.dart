import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';

/// purchase a ship of type [shipType] at [shipyardSymbol]
Future<PurchaseShip201ResponseData> purchaseShip(
  Api api,
  ShipType shipType,
  String shipyardSymbol,
) async {
  final purchaseShipRequest = PurchaseShipRequest(
    waypointSymbol: shipyardSymbol,
    shipType: shipType,
  );
  final purchaseResponse =
      await api.fleet.purchaseShip(purchaseShipRequest: purchaseShipRequest);
  return purchaseResponse!.data;
}

/// navigate [ship] to [waypoint]
Future<NavigateShip200ResponseData> navigateTo(
  Api api,
  Ship ship,
  Waypoint waypoint,
) async {
  final request = NavigateShipRequest(waypointSymbol: waypoint.symbol);
  final result =
      await api.fleet.navigateShip(ship.symbol, navigateShipRequest: request);
  return result!.data;
}

/// Sell all cargo matching the [where] predicate.
/// If [where] is null, sell all cargo.
/// returns a stream of the sell responses.
Stream<SellCargo201ResponseData> sellCargo(
  Api api,
  Ship ship, {
  bool Function(String tradeSymbol)? where,
}) async* {
  // logCargo(ship);
  // final contractsResponse = await api.contracts.getContracts();
  // print("Contracts: ${contractsResponse!.data}");
  // final marketplaces =
  //     systemWaypoints.where((w) => w.hasMarketplace).toList();
  // printWaypoints(marketplaces);

  // final marketResponse =
  //     await api.systems.getMarket(waypoint.systemSymbol, waypoint.symbol);
  // final market = marketResponse!.data;
  // prettyPrintJson(market.toJson());

  // This should not sell anything we have a contract for.
  // We should travel first to the marketplace that has the best price for
  // the ore we have a contract for.
  for (final item in ship.cargo.inventory) {
    if (where != null && where(item.symbol)) {
      continue;
    }
    final sellRequest = SellCargoRequest(
      symbol: item.symbol,
      units: item.units,
    );
    final sellResponse =
        await api.fleet.sellCargo(ship.symbol, sellCargoRequest: sellRequest);
    yield sellResponse!.data;
  }
}
