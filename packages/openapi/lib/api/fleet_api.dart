import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:openapi/api_client.dart';
import 'package:openapi/api_exception.dart';
import 'package:openapi/model/create_chart201_response.dart';
import 'package:openapi/model/create_ship_ship_scan201_response.dart';
import 'package:openapi/model/create_ship_system_scan201_response.dart';
import 'package:openapi/model/create_ship_waypoint_scan201_response.dart';
import 'package:openapi/model/create_survey201_response.dart';
import 'package:openapi/model/dock_ship200_response.dart';
import 'package:openapi/model/extract_resources201_response.dart';
import 'package:openapi/model/extract_resources_with_survey201_response.dart';
import 'package:openapi/model/get_mounts200_response.dart';
import 'package:openapi/model/get_my_ship200_response.dart';
import 'package:openapi/model/get_my_ship_cargo200_response.dart';
import 'package:openapi/model/get_my_ships200_response.dart';
import 'package:openapi/model/get_repair_ship200_response.dart';
import 'package:openapi/model/get_scrap_ship200_response.dart';
import 'package:openapi/model/get_ship_cooldown_response.dart';
import 'package:openapi/model/get_ship_modules200_response.dart';
import 'package:openapi/model/get_ship_nav200_response.dart';
import 'package:openapi/model/install_mount201_response.dart';
import 'package:openapi/model/install_mount_request.dart';
import 'package:openapi/model/install_ship_module201_response.dart';
import 'package:openapi/model/install_ship_module_request.dart';
import 'package:openapi/model/jettison200_response.dart';
import 'package:openapi/model/jettison_request.dart';
import 'package:openapi/model/jump_ship200_response.dart';
import 'package:openapi/model/jump_ship_request.dart';
import 'package:openapi/model/navigate_ship200_response.dart';
import 'package:openapi/model/navigate_ship_request.dart';
import 'package:openapi/model/negotiate_contract201_response.dart';
import 'package:openapi/model/orbit_ship200_response.dart';
import 'package:openapi/model/patch_ship_nav200_response.dart';
import 'package:openapi/model/patch_ship_nav_request.dart';
import 'package:openapi/model/purchase_cargo201_response.dart';
import 'package:openapi/model/purchase_cargo_request.dart';
import 'package:openapi/model/purchase_ship201_response.dart';
import 'package:openapi/model/purchase_ship_request.dart';
import 'package:openapi/model/refuel_ship200_response.dart';
import 'package:openapi/model/refuel_ship_request.dart';
import 'package:openapi/model/remove_mount201_response.dart';
import 'package:openapi/model/remove_mount_request.dart';
import 'package:openapi/model/remove_ship_module201_response.dart';
import 'package:openapi/model/remove_ship_module_request.dart';
import 'package:openapi/model/repair_ship200_response.dart';
import 'package:openapi/model/scrap_ship200_response.dart';
import 'package:openapi/model/sell_cargo201_response.dart';
import 'package:openapi/model/sell_cargo_request.dart';
import 'package:openapi/model/ship_refine201_response.dart';
import 'package:openapi/model/ship_refine_request.dart';
import 'package:openapi/model/siphon_resources201_response.dart';
import 'package:openapi/model/survey.dart';
import 'package:openapi/model/transfer_cargo200_response.dart';
import 'package:openapi/model/transfer_cargo_request.dart';
import 'package:openapi/model/warp_ship200_response.dart';
import 'package:openapi/model/warp_ship_request.dart';

/// The fleet endpoints contain actions that relate to the fleet of ships owned
/// by agents, and the actions those ships can perform.
class FleetApi {
  FleetApi(ApiClient? client) : client = client ?? ApiClient();

  final ApiClient client;

  /// List Ships
  /// Return a paginated list of all of ships under your agent's ownership.
  Future<GetMyShips200Response> getMyShips({
    int? page = 1,
    int? limit = 10,
  }) async {
    page?.validateMinimum(1);
    limit?.validateMaximum(20);
    limit?.validateMinimum(1);

    final response = await client.invokeApi(
      method: Method.get,
      path: '/my/ships',
      queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return GetMyShips200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Purchase Ship
  /// Purchase a ship from a Shipyard. In order to use this function, a ship
  /// under your agent's ownership must be in a waypoint that has the
  /// `Shipyard` trait, and the Shipyard must sell the type of the desired
  /// ship.
  ///
  /// Shipyards typically offer ship types, which are predefined templates of
  /// ships that have dedicated roles. A template comes with a preset of an
  /// engine, a reactor, and a frame. It may also include a few modules and
  /// mounts.
  Future<PurchaseShip201Response> purchaseShip(
    PurchaseShipRequest purchaseShipRequest,
  ) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships',
      body: purchaseShipRequest.toJson(),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return PurchaseShip201Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Get Ship
  /// Retrieve the details of a ship under your agent's ownership.
  Future<GetMyShip200Response> getMyShip(String shipSymbol) async {
    final response = await client.invokeApi(
      method: Method.get,
      path: '/my/ships/{shipSymbol}'.replaceAll('{shipSymbol}', shipSymbol),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return GetMyShip200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Create Chart
  /// Command a ship to chart the waypoint at its current location.
  ///
  /// Most waypoints in the universe are uncharted by default. These waypoints
  /// have their traits hidden until they have been charted by a ship.
  ///
  /// Charting a waypoint will record your agent as the one who created the
  /// chart, and all other agents would also be able to see the waypoint's
  /// traits. Charting a waypoint gives you a one time reward of credits based
  /// on the rarity of the waypoint's traits.
  Future<CreateChart201Response> createChart(String shipSymbol) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/chart'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return CreateChart201Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Negotiate Contract
  /// Negotiate a new contract with the HQ.
  ///
  /// In order to negotiate a new contract, an agent must not have ongoing or
  /// offered contracts over the allowed maximum amount. Currently the maximum
  /// contracts an agent can have at a time is 1.
  ///
  /// Once a contract is negotiated, it is added to the list of contracts
  /// offered to the agent, which the agent can then accept.
  ///
  /// The ship must be present at any waypoint with a faction present to
  /// negotiate a contract with that faction.
  Future<NegotiateContract201Response> negotiateContract(
    String shipSymbol,
  ) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/negotiate/contract'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return NegotiateContract201Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Get Ship Cooldown
  /// Retrieve the details of your ship's reactor cooldown. Some actions such
  /// as activating your jump drive, scanning, or extracting resources taxes
  /// your reactor and results in a cooldown.
  ///
  /// Your ship cannot perform additional actions until your cooldown has
  /// expired. The duration of your cooldown is relative to the power
  /// consumption of the related modules or mounts for the action taken.
  ///
  /// Response returns a 204 status code (no-content) when the ship has no
  /// cooldown.
  Future<GetShipCooldownResponse> getShipCooldown(String shipSymbol) async {
    final response = await client.invokeApi(
      method: Method.get,
      path: '/my/ships/{shipSymbol}/cooldown'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return GetShipCooldownResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Dock Ship
  /// Attempt to dock your ship at its current location. Docking will only
  /// succeed if your ship is capable of docking at the time of the request.
  ///
  /// Docked ships can access elements in their current location, such as the
  /// market or a shipyard, but cannot do actions that require the ship to be
  /// above surface such as navigating or extracting.
  ///
  /// The endpoint is idempotent - successive calls will succeed even if the
  /// ship is already docked.
  Future<DockShip200Response> dockShip(String shipSymbol) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/dock'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return DockShip200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Extract Resources
  /// Extract resources from a waypoint that can be extracted, such as
  /// asteroid fields, into your ship. Send an optional survey as the payload
  /// to target specific yields.
  ///
  /// The ship must be in orbit to be able to extract and must have mining
  /// equipments installed that can extract goods, such as the `Gas Siphon`
  /// mount for gas-based goods or `Mining Laser` mount for ore-based goods.
  ///
  /// The survey property is now deprecated. See the `extract/survey` endpoint
  /// for more details.
  Future<ExtractResources201Response> extractResources(
    String shipSymbol,
  ) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/extract'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return ExtractResources201Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Extract Resources with Survey
  /// Use a survey when extracting resources from a waypoint. This endpoint
  /// requires a survey as the payload, which allows your ship to extract
  /// specific yields.
  ///
  /// Send the full survey object as the payload which will be validated
  /// according to the signature. If the signature is invalid, or any
  /// properties of the survey are changed, the request will fail.
  Future<ExtractResourcesWithSurvey201Response> extractResourcesWithSurvey(
    String shipSymbol, {
    Survey? survey,
  }) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/extract/survey'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      body: survey?.toJson(),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return ExtractResourcesWithSurvey201Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Jettison Cargo
  /// Jettison cargo from your ship's cargo hold.
  Future<Jettison200Response> jettison(
    String shipSymbol,
    JettisonRequest jettisonRequest,
  ) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/jettison'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      body: jettisonRequest.toJson(),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return Jettison200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Jump Ship
  /// Jump your ship instantly to a target connected waypoint. The ship must
  /// be in orbit to execute a jump.
  ///
  /// A unit of antimatter is purchased and consumed from the market when
  /// jumping. The price of antimatter is determined by the market and is
  /// subject to change. A ship can only jump to connected waypoints
  Future<JumpShip200Response> jumpShip(
    String shipSymbol,
    JumpShipRequest jumpShipRequest,
  ) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/jump'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      body: jumpShipRequest.toJson(),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return JumpShip200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Scan Systems
  /// Scan for nearby systems, retrieving information on the systems' distance
  /// from the ship and their waypoints. Requires a ship to have the `Sensor
  /// Array` mount installed to use.
  ///
  /// The ship will enter a cooldown after using this function, during which
  /// it cannot execute certain actions.
  Future<CreateShipSystemScan201Response> createShipSystemScan(
    String shipSymbol,
  ) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/scan/systems'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return CreateShipSystemScan201Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Scan Waypoints
  /// Scan for nearby waypoints, retrieving detailed information on each
  /// waypoint in range. Scanning uncharted waypoints will allow you to ignore
  /// their uncharted state and will list the waypoints' traits.
  ///
  /// Requires a ship to have the `Sensor Array` mount installed to use.
  ///
  /// The ship will enter a cooldown after using this function, during which
  /// it cannot execute certain actions.
  Future<CreateShipWaypointScan201Response> createShipWaypointScan(
    String shipSymbol,
  ) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/scan/waypoints'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return CreateShipWaypointScan201Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Scan Ships
  /// Scan for nearby ships, retrieving information for all ships in range.
  ///
  /// Requires a ship to have the `Sensor Array` mount installed to use.
  ///
  /// The ship will enter a cooldown after using this function, during which
  /// it cannot execute certain actions.
  Future<CreateShipShipScan201Response> createShipShipScan(
    String shipSymbol,
  ) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/scan/ships'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return CreateShipShipScan201Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Get Scrap Ship
  /// Get the value of scrapping a ship. Requires the ship to be docked at a
  /// waypoint that has the `Shipyard` trait.
  Future<GetScrapShip200Response> getScrapShip(String shipSymbol) async {
    final response = await client.invokeApi(
      method: Method.get,
      path: '/my/ships/{shipSymbol}/scrap'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return GetScrapShip200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Scrap Ship
  /// Scrap a ship, removing it from the game and receiving a portion of the
  /// ship's value back in credits. The ship must be docked in a waypoint that
  /// has the `Shipyard` trait to be scrapped.
  Future<ScrapShip200Response> scrapShip(String shipSymbol) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/scrap'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return ScrapShip200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Navigate Ship
  /// Navigate to a target destination. The ship must be in orbit to use this
  /// function. The destination waypoint must be within the same system as the
  /// ship's current location. Navigating will consume the necessary fuel from
  /// the ship's manifest based on the distance to the target waypoint.
  ///
  /// The returned response will detail the route information including the
  /// expected time of arrival. Most ship actions are unavailable until the
  /// ship has arrived at it's destination.
  ///
  /// To travel between systems, see the ship's Warp or Jump actions.
  Future<NavigateShip200Response> navigateShip(
    String shipSymbol,
    NavigateShipRequest navigateShipRequest,
  ) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/navigate'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      body: navigateShipRequest.toJson(),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return NavigateShip200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Warp Ship
  /// Warp your ship to a target destination in another system. The ship must
  /// be in orbit to use this function and must have the `Warp Drive` module
  /// installed. Warping will consume the necessary fuel from the ship's
  /// manifest.
  ///
  /// The returned response will detail the route information including the
  /// expected time of arrival. Most ship actions are unavailable until the
  /// ship has arrived at its destination.
  Future<WarpShip200Response> warpShip(
    String shipSymbol,
    WarpShipRequest warpShipRequest,
  ) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/warp'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      body: warpShipRequest.toJson(),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return WarpShip200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Orbit Ship
  /// Attempt to move your ship into orbit at its current location. The
  /// request will only succeed if your ship is capable of moving into orbit
  /// at the time of the request.
  ///
  /// Orbiting ships are able to do actions that require the ship to be above
  /// surface such as navigating or extracting, but cannot access elements in
  /// their current waypoint, such as the market or a shipyard.
  ///
  /// The endpoint is idempotent - successive calls will succeed even if the
  /// ship is already in orbit.
  Future<OrbitShip200Response> orbitShip(String shipSymbol) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/orbit'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return OrbitShip200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Purchase Cargo
  /// Purchase cargo from a market.
  ///
  /// The ship must be docked in a waypoint that has `Marketplace` trait, and
  /// the market must be selling a good to be able to purchase it.
  ///
  /// The maximum amount of units of a good that can be purchased in each
  /// transaction are denoted by the `tradeVolume` value of the good, which
  /// can be viewed by using the Get Market action.
  ///
  /// Purchased goods are added to the ship's cargo hold.
  Future<PurchaseCargo201Response> purchaseCargo(
    String shipSymbol,
    PurchaseCargoRequest purchaseCargoRequest,
  ) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/purchase'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      body: purchaseCargoRequest.toJson(),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return PurchaseCargo201Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Ship Refine
  /// Attempt to refine the raw materials on your ship. The request will only
  /// succeed if your ship is capable of refining at the time of the request.
  /// In order to be able to refine, a ship must have goods that can be
  /// refined and have installed a `Refinery` module that can refine it.
  ///
  /// When refining, 100 basic goods will be converted into 10 processed
  /// goods.
  Future<ShipRefine201Response> shipRefine(
    String shipSymbol,
    ShipRefineRequest shipRefineRequest,
  ) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/refine'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      body: shipRefineRequest.toJson(),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return ShipRefine201Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Refuel Ship
  /// Refuel your ship by buying fuel from the local market.
  ///
  /// Requires the ship to be docked in a waypoint that has the `Marketplace`
  /// trait, and the market must be selling fuel in order to refuel.
  ///
  /// Each fuel bought from the market replenishes 100 units in your ship's
  /// fuel.
  ///
  /// Ships will always be refuel to their frame's maximum fuel capacity when
  /// using this action.
  Future<RefuelShip200Response> refuelShip(
    String shipSymbol, {
    RefuelShipRequest? refuelShipRequest,
  }) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/refuel'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      body: refuelShipRequest?.toJson(),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return RefuelShip200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Get Repair Ship
  /// Get the cost of repairing a ship. Requires the ship to be docked at a
  /// waypoint that has the `Shipyard` trait.
  Future<GetRepairShip200Response> getRepairShip(String shipSymbol) async {
    final response = await client.invokeApi(
      method: Method.get,
      path: '/my/ships/{shipSymbol}/repair'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return GetRepairShip200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Repair Ship
  /// Repair a ship, restoring the ship to maximum condition. The ship must be
  /// docked at a waypoint that has the `Shipyard` trait in order to use this
  /// function. To preview the cost of repairing the ship, use the Get action.
  Future<RepairShip200Response> repairShip(String shipSymbol) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/repair'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return RepairShip200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Sell Cargo
  /// Sell cargo in your ship to a market that trades this cargo. The ship
  /// must be docked in a waypoint that has the `Marketplace` trait in order
  /// to use this function.
  Future<SellCargo201Response> sellCargo(
    String shipSymbol,
    SellCargoRequest sellCargoRequest,
  ) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/sell'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      body: sellCargoRequest.toJson(),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return SellCargo201Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Siphon Resources
  /// Siphon gases or other resources from gas giants.
  ///
  /// The ship must be in orbit to be able to siphon and must have siphon
  /// mounts and a gas processor installed.
  Future<SiphonResources201Response> siphonResources(String shipSymbol) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/siphon'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return SiphonResources201Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Create Survey
  /// Create surveys on a waypoint that can be extracted such as asteroid
  /// fields. A survey focuses on specific types of deposits from the
  /// extracted location. When ships extract using this survey, they are
  /// guaranteed to procure a high amount of one of the goods in the survey.
  ///
  /// In order to use a survey, send the entire survey details in the body of
  /// the extract request.
  ///
  /// Each survey may have multiple deposits, and if a symbol shows up more
  /// than once, that indicates a higher chance of extracting that resource.
  ///
  /// Your ship will enter a cooldown after surveying in which it is unable to
  /// perform certain actions. Surveys will eventually expire after a period
  /// of time or will be exhausted after being extracted several times based
  /// on the survey's size. Multiple ships can use the same survey for
  /// extraction.
  ///
  /// A ship must have the `Surveyor` mount installed in order to use this
  /// function.
  Future<CreateSurvey201Response> createSurvey(String shipSymbol) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/survey'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return CreateSurvey201Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Transfer Cargo
  /// Transfer cargo between ships.
  ///
  /// The receiving ship must be in the same waypoint as the transferring
  /// ship, and it must able to hold the additional cargo after the transfer
  /// is complete. Both ships also must be in the same state, either both are
  /// docked or both are orbiting.
  ///
  /// The response body's cargo shows the cargo of the transferring ship after
  /// the transfer is complete.
  Future<TransferCargo200Response> transferCargo(
    String shipSymbol,
    TransferCargoRequest transferCargoRequest,
  ) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/transfer'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      body: transferCargoRequest.toJson(),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return TransferCargo200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Get Ship Cargo
  /// Retrieve the cargo of a ship under your agent's ownership.
  Future<GetMyShipCargo200Response> getMyShipCargo(String shipSymbol) async {
    final response = await client.invokeApi(
      method: Method.get,
      path: '/my/ships/{shipSymbol}/cargo'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return GetMyShipCargo200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Get Ship Modules
  /// Get the modules installed on a ship.
  Future<GetShipModules200Response> getShipModules(String shipSymbol) async {
    final response = await client.invokeApi(
      method: Method.get,
      path: '/my/ships/{shipSymbol}/modules'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return GetShipModules200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Install Ship Module
  /// Install a module on a ship. The module must be in your cargo.
  Future<InstallShipModule201Response> installShipModule(
    String shipSymbol,
    InstallShipModuleRequest installShipModuleRequest,
  ) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/modules/install'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      body: installShipModuleRequest.toJson(),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return InstallShipModule201Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Remove Ship Module
  /// Remove a module from a ship. The module will be placed in cargo.
  Future<RemoveShipModule201Response> removeShipModule(
    String shipSymbol,
    RemoveShipModuleRequest removeShipModuleRequest,
  ) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/modules/remove'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      body: removeShipModuleRequest.toJson(),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return RemoveShipModule201Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Get Mounts
  /// Get the mounts installed on a ship.
  Future<GetMounts200Response> getMounts(String shipSymbol) async {
    final response = await client.invokeApi(
      method: Method.get,
      path: '/my/ships/{shipSymbol}/mounts'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return GetMounts200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Install Mount
  /// Install a mount on a ship.
  ///
  /// In order to install a mount, the ship must be docked and located in a
  /// waypoint that has a `Shipyard` trait. The ship also must have the mount
  /// to install in its cargo hold.
  ///
  /// An installation fee will be deduced by the Shipyard for installing the
  /// mount on the ship.
  Future<InstallMount201Response> installMount(
    String shipSymbol,
    InstallMountRequest installMountRequest,
  ) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/mounts/install'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      body: installMountRequest.toJson(),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return InstallMount201Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Remove Mount
  /// Remove a mount from a ship.
  ///
  /// The ship must be docked in a waypoint that has the `Shipyard` trait, and
  /// must have the desired mount that it wish to remove installed.
  ///
  /// A removal fee will be deduced from the agent by the Shipyard.
  Future<RemoveMount201Response> removeMount(
    String shipSymbol,
    RemoveMountRequest removeMountRequest,
  ) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/my/ships/{shipSymbol}/mounts/remove'.replaceAll(
        '{shipSymbol}',
        shipSymbol,
      ),
      body: removeMountRequest.toJson(),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return RemoveMount201Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Get Ship Nav
  /// Get the current nav status of a ship.
  Future<GetShipNav200Response> getShipNav(String shipSymbol) async {
    final response = await client.invokeApi(
      method: Method.get,
      path: '/my/ships/{shipSymbol}/nav'.replaceAll('{shipSymbol}', shipSymbol),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return GetShipNav200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }

  /// Patch Ship Nav
  /// Update the nav configuration of a ship.
  ///
  /// Currently only supports configuring the Flight Mode of the ship, which
  /// affects its speed and fuel consumption.
  Future<PatchShipNav200Response> patchShipNav(
    String shipSymbol, {
    PatchShipNavRequest? patchShipNavRequest,
  }) async {
    final response = await client.invokeApi(
      method: Method.patch,
      path: '/my/ships/{shipSymbol}/nav'.replaceAll('{shipSymbol}', shipSymbol),
      body: patchShipNavRequest?.toJson(),
      authRequest: const HttpAuth(scheme: 'bearer', secretName: 'AgentToken'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return PatchShipNav200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException.unhandled(response.statusCode);
  }
}
