import 'dart:convert';

import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/logger.dart';

void prettyPrintJson(Map<String, dynamic> json) {
  JsonEncoder encoder = JsonEncoder.withIndent('  ');
  String prettyprint = encoder.convert(json);
  print(prettyprint);
}

/// parseWaypointString parses a waypoint string into its component parts.
({String sector, String system, String waypoint}) parseWaypointString(
    String headquarters) {
  final parts = headquarters.split('-');
  return (
    sector: parts[0],
    system: "${parts[0]}-${parts[1]}",
    waypoint: "${parts[0]}-${parts[1]}-${parts[2]}",
  );
}

/// register registers a new user with the space traders api and
/// returns the auth token which should be saved and used for future requests.
Future<String> register(String callSign) async {
  final defaultApi = DefaultApi();

  final faction = RegisterRequestFactionEnum.values.first;

  RegisterRequest registerRequest = RegisterRequest(
    symbol: callSign,
    faction: faction,
  );
  Register201Response? registerResponse;
  try {
    registerResponse =
        await defaultApi.register(registerRequest: registerRequest);
    // print(registerResponse);
  } catch (e) {
    logger.err('Exception when calling DefaultApi->register: $e\n');
  }
  return registerResponse!.data.token;
}
