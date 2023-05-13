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


/// tests for SystemsApi
void main() {
  // final instance = SystemsApi();

  group('tests for SystemsApi', () {
    // Get Jump Gate
    //
    // Get jump gate details for a waypoint.
    //
    //Future<GetJumpGate200Response> getJumpGate(String systemSymbol, String waypointSymbol) async
    test('test getJumpGate', () async {
      // TODO
    });

    // Get Market
    //
    // Retrieve imports, exports and exchange data from a marketplace. Imports can be sold, exports can be purchased, and exchange goods can be purchased or sold. Send a ship to the waypoint to access trade good prices and recent transactions.
    //
    //Future<GetMarket200Response> getMarket(String systemSymbol, String waypointSymbol) async
    test('test getMarket', () async {
      // TODO
    });

    // Get Shipyard
    //
    // Get the shipyard for a waypoint. Send a ship to the waypoint to access ships that are currently available for purchase and recent transactions.
    //
    //Future<GetShipyard200Response> getShipyard(String systemSymbol, String waypointSymbol) async
    test('test getShipyard', () async {
      // TODO
    });

    // Get System
    //
    // Get the details of a system.
    //
    //Future<GetSystem200Response> getSystem(String systemSymbol) async
    test('test getSystem', () async {
      // TODO
    });

    // List Waypoints
    //
    // Fetch all of the waypoints for a given system. System must be charted or a ship must be present to return waypoint details.
    //
    //Future<GetSystemWaypoints200Response> getSystemWaypoints(String systemSymbol, { int page, int limit }) async
    test('test getSystemWaypoints', () async {
      // TODO
    });

    // List Systems
    //
    // Return a list of all systems.
    //
    //Future<GetSystems200Response> getSystems({ int page, int limit }) async
    test('test getSystems', () async {
      // TODO
    });

    // Get Waypoint
    //
    // View the details of a waypoint.
    //
    //Future<GetWaypoint200Response> getWaypoint(String systemSymbol, String waypointSymbol) async
    test('test getWaypoint', () async {
      // TODO
    });

  });
}
