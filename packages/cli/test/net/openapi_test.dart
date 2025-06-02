import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:openapi/api.dart';
import 'package:test/test.dart';

// This test belongs in the openapi package, but since that's auto-generated,
// testing it here.

class MockClient extends Mock implements http.Client {}

void main() {
  test('SystemsApi', () async {
    final client = MockClient();
    registerFallbackValue(Uri.parse('https://api.spacetraders.io/v2/systems'));
    when(() => client.get(any())).thenAnswer(
      (_) async => http.Response(
        jsonEncode(
          GetSystems200Response(
            data: [
              System(
                symbol: 'X1-QB10',
                sectorSymbol: 'QB10',
                type: SystemType.NEUTRON_STAR,
                x: 0,
                y: 0,
                factions: [],
                waypoints: [
                  SystemWaypoint(
                    symbol: 'X1-QB10-1',
                    type: WaypointType.PLANET,
                    x: 0,
                    y: 0,
                  ),
                ],
              ),
            ],
            meta: Meta(total: 1),
          ),
        ),
        200,
      ),
    );
    final apiClient = ApiClient()..client = client;
    final api = SystemsApi(apiClient);
    final systems = await api.getSystems(limit: 1, page: 1);
    verify(
      () => client.get(
        Uri.parse('https://api.spacetraders.io/v2/systems?page=1&limit=1'),
      ),
    ).called(1);
    expect(systems?.data.length, 1);
    expect(systems?.data[0].symbol, 'X1-QB10');
    expect(systems?.data[0].sectorSymbol, 'QB10');
    expect(systems?.data[0].type, SystemType.NEUTRON_STAR);
    expect(systems?.data[0].x, 0);
    expect(systems?.data[0].y, 0);
    expect(systems?.data[0].factions.length, 0);
  });
}
