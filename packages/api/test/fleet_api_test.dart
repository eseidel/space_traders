//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

import 'package:openapi/api.dart';
import 'package:test/test.dart';


/// tests for FleetApi
void main() {
  // final instance = FleetApi();

  group('tests for FleetApi', () {
    // Create Chart
    //
    // Command a ship to chart the current waypoint.  Waypoints in the universe are uncharted by default. These locations will not show up in the API until they have been charted by a ship.  Charting a location will record your agent as the one who created the chart.
    //
    //Future<CreateChart201Response> createChart(String shipSymbol) async
    test('test createChart', () async {
      // TODO
    });

    // Scan Ships
    //
    // Activate your ship's sensor arrays to scan for ship information.
    //
    //Future<CreateShipShipScan201Response> createShipShipScan(String shipSymbol) async
    test('test createShipShipScan', () async {
      // TODO
    });

    // Scan Systems
    //
    // Activate your ship's sensor arrays to scan for system information.
    //
    //Future<CreateShipSystemScan201Response> createShipSystemScan(String shipSymbol) async
    test('test createShipSystemScan', () async {
      // TODO
    });

    // Scan Waypoints
    //
    // Activate your ship's sensor arrays to scan for waypoint information.
    //
    //Future<CreateShipWaypointScan201Response> createShipWaypointScan(String shipSymbol) async
    test('test createShipWaypointScan', () async {
      // TODO
    });

    // Create Survey
    //
    // If you want to target specific yields for an extraction, you can survey a waypoint, such as an asteroid field, and send the survey in the body of the extract request. Each survey may have multiple deposits, and if a symbol shows up more than once, that indicates a higher chance of extracting that resource.  Your ship will enter a cooldown between consecutive survey requests. Surveys will eventually expire after a period of time. Multiple ships can use the same survey for extraction.
    //
    //Future<CreateSurvey201Response> createSurvey(String shipSymbol) async
    test('test createSurvey', () async {
      // TODO
    });

    // Dock Ship
    //
    // Attempt to dock your ship at it's current location. Docking will only succeed if the waypoint is a dockable location, and your ship is capable of docking at the time of the request.  The endpoint is idempotent - successive calls will succeed even if the ship is already docked.
    //
    //Future<DockShip200Response> dockShip(String shipSymbol) async
    test('test dockShip', () async {
      // TODO
    });

    // Extract Resources
    //
    // Extract resources from the waypoint into your ship. Send an optional survey as the payload to target specific yields.
    //
    //Future<ExtractResources201Response> extractResources(String shipSymbol, { ExtractResourcesRequest extractResourcesRequest }) async
    test('test extractResources', () async {
      // TODO
    });

    // Get Ship
    //
    // Retrieve the details of your ship.
    //
    //Future<GetMyShip200Response> getMyShip(String shipSymbol) async
    test('test getMyShip', () async {
      // TODO
    });

    // Get Ship Cargo
    //
    // Retrieve the cargo of your ship.
    //
    //Future<GetMyShipCargo200Response> getMyShipCargo(String shipSymbol) async
    test('test getMyShipCargo', () async {
      // TODO
    });

    // List Ships
    //
    // Retrieve all of your ships.
    //
    //Future<GetMyShips200Response> getMyShips({ int page, int limit }) async
    test('test getMyShips', () async {
      // TODO
    });

    // Get Ship Cooldown
    //
    // Retrieve the details of your ship's reactor cooldown. Some actions such as activating your jump drive, scanning, or extracting resources taxes your reactor and results in a cooldown.  Your ship cannot perform additional actions until your cooldown has expired. The duration of your cooldown is relative to the power consumption of the related modules or mounts for the action taken.  Response returns a 204 status code (no-content) when the ship has no cooldown.
    //
    //Future<GetShipCooldown200Response> getShipCooldown(String shipSymbol) async
    test('test getShipCooldown', () async {
      // TODO
    });

    // Get Ship Nav
    //
    // Get the current nav status of a ship.
    //
    //Future<GetShipNav200Response> getShipNav(String shipSymbol) async
    test('test getShipNav', () async {
      // TODO
    });

    // Jettison Cargo
    //
    // Jettison cargo from your ship's cargo hold.
    //
    //Future<Jettison200Response> jettison(String shipSymbol, { JettisonRequest jettisonRequest }) async
    test('test jettison', () async {
      // TODO
    });

    // Jump Ship
    //
    // Jump your ship instantly to a target system. Unlike other forms of navigation, jumping requires a unit of antimatter.
    //
    //Future<JumpShip200Response> jumpShip(String shipSymbol, { JumpShipRequest jumpShipRequest }) async
    test('test jumpShip', () async {
      // TODO
    });

    // Navigate Ship
    //
    // Navigate to a target destination. The destination must be located within the same system as the ship. Navigating will consume the necessary fuel and supplies from the ship's manifest, and will pay out crew wages from the agent's account.  The returned response will detail the route information including the expected time of arrival. Most ship actions are unavailable until the ship has arrived at it's destination.  To travel between systems, see the ship's warp or jump actions.
    //
    //Future<NavigateShip200Response> navigateShip(String shipSymbol, { NavigateShipRequest navigateShipRequest }) async
    test('test navigateShip', () async {
      // TODO
    });

    // Orbit Ship
    //
    // Attempt to move your ship into orbit at it's current location. The request will only succeed if your ship is capable of moving into orbit at the time of the request.  The endpoint is idempotent - successive calls will succeed even if the ship is already in orbit.
    //
    //Future<OrbitShip200Response> orbitShip(String shipSymbol) async
    test('test orbitShip', () async {
      // TODO
    });

    // Patch Ship Nav
    //
    // Update the nav data of a ship, such as the flight mode.
    //
    //Future<GetShipNav200Response> patchShipNav(String shipSymbol, { PatchShipNavRequest patchShipNavRequest }) async
    test('test patchShipNav', () async {
      // TODO
    });

    // Purchase Cargo
    //
    // Purchase cargo.
    //
    //Future<PurchaseCargo201Response> purchaseCargo(String shipSymbol, { PurchaseCargoRequest purchaseCargoRequest }) async
    test('test purchaseCargo', () async {
      // TODO
    });

    // Purchase Ship
    //
    // Purchase a ship
    //
    //Future<PurchaseShip201Response> purchaseShip({ PurchaseShipRequest purchaseShipRequest }) async
    test('test purchaseShip', () async {
      // TODO
    });

    // Refuel Ship
    //
    // Refuel your ship from the local market.
    //
    //Future<RefuelShip200Response> refuelShip(String shipSymbol) async
    test('test refuelShip', () async {
      // TODO
    });

    // Sell Cargo
    //
    // Sell cargo.
    //
    //Future<SellCargo201Response> sellCargo(String shipSymbol, { SellCargoRequest sellCargoRequest }) async
    test('test sellCargo', () async {
      // TODO
    });

    // Ship Refine
    //
    // Attempt to refine the raw materials on your ship. The request will only succeed if your ship is capable of refining at the time of the request.
    //
    //Future<ShipRefine200Response> shipRefine(String shipSymbol, { ShipRefineRequest shipRefineRequest }) async
    test('test shipRefine', () async {
      // TODO
    });

    // Transfer Cargo
    //
    // Transfer cargo between ships.
    //
    //Future<TransferCargo200Response> transferCargo(String shipSymbol, { TransferCargoRequest transferCargoRequest }) async
    test('test transferCargo', () async {
      // TODO
    });

    // Warp Ship
    //
    // Warp your ship to a target destination in another system. Warping will consume the necessary fuel and supplies from the ship's manifest, and will pay out crew wages from the agent's account.  The returned response will detail the route information including the expected time of arrival. Most ship actions are unavailable until the ship has arrived at it's destination.
    //
    //Future<NavigateShip200Response> warpShip(String shipSymbol, { NavigateShipRequest navigateShipRequest }) async
    test('test warpShip', () async {
      // TODO
    });

  });
}
