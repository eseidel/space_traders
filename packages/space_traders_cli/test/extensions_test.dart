import 'dart:convert';

import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:test/test.dart';

void main() {
  test('parseWaypointString', () {
    final parsed = parseWaypointString('X1-DF55-20250Z');
    expect(parsed.sector, 'X1');
    expect(parsed.system, 'X1-DF55');
    expect(parsed.waypoint, 'X1-DF55-20250Z');
  });

  test('expirationFromApiException', () {
    final expiration = expirationFromApiException(
      ApiException(
        400,
        jsonEncode({
          'error': {
            'message': 'Ship action is still on cooldown for 6 second(s).',
            'code': 4000,
            'data': {
              'cooldown': {
                'shipSymbol': 'ESEIDEL2-1',
                'totalSeconds': 70,
                'remainingSeconds': 6,
                'expiration': '2023-05-20T22:53:30.735Z'
              }
            }
          }
        }),
      ),
    );
    expect(expiration, isNotNull);

    // We don't care what the error number is so long as the body has
    // code 4000 and the cooldown data is present.
    final expiration2 = expirationFromApiException(
      ApiException(
        400,
        jsonEncode({
          'error': {
            'message': 'Ship action is still on cooldown for 6 second(s).',
            'code': 4000,
            'data': {
              'cooldown': {
                'shipSymbol': 'ESEIDEL2-1',
                'totalSeconds': 70,
                'remainingSeconds': 6,
                'expiration': '2023-05-20T22:53:30.735Z'
              }
            }
          }
        }),
      ),
    );
    expect(expiration2, isNotNull);

    // A 400 error without a cooldown should return null.
    final expiration3 = expirationFromApiException(
      ApiException(400, jsonEncode({'error': 'Expired token'})),
    );
    expect(expiration3, isNull);
  });
}
