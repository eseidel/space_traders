import 'dart:convert';

import 'package:cli/api.dart';
import 'package:cli/net/exceptions.dart';
import 'package:test/test.dart';

void main() {
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
                'expiration': '2023-05-20T22:53:30.735Z',
              },
            },
          },
        }),
      ),
    );
    expect(expiration, isNotNull);

    // We don't care what the error number is so long as the body has
    // code 4000 and the cooldown data is present.
    final expiration2 = expirationFromApiException(
      ApiException(
        409,
        jsonEncode({
          'error': {
            'message': 'Ship action is still on cooldown for 10 second(s).',
            'code': 4000,
            'data': {
              'cooldown': {
                'shipSymbol': 'ESEIDEL2-1',
                'totalSeconds': 70,
                'remainingSeconds': 10,
                'expiration': '2023-05-21T00:17:14.284Z',
              },
            },
          },
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

  test('isSurveyExhaustedException', () {
    final exception = ApiException(
      409,
      jsonEncode({
        'error': {
          'message': 'Ship extract failed. '
              'Survey X1-VS75-67965Z-D0F7C6 has been exhausted.',
          'code': 4224,
        },
      }),
    );
    expect(isSurveyExhaustedException(exception), isTrue);
  });

  test('isSurveyExpiredException', () {
    final exception = ApiException(
      400,
      jsonEncode({
        'error': {
          'message': 'Ship survey failed. '
              'Target signature is no longer in range or valid.',
          'code': 4221,
        },
      }),
    );
    expect(isSurveyExpiredException(exception), isTrue);
  });

  test('isAPIExceptionWithCode', () {
    final exception = ApiException(
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
              'expiration': '2023-05-20T22:53:30.735Z',
            },
          },
        },
      }),
    );
    expect(isAPIExceptionWithCode(exception, 4000), isTrue);
  });

  test('isMarketDoesNotSellFuelException', () {
    final exception = ApiException(
        400,
        '{"error":{"message":"Market purchase failed. Trade good FUEL is '
        'not available at '
        'X1-BZ43-47417A.","code":4601,"data":{"waypointSymbol": '
        '"X1-BZ43-47417A","tradeSymbol":"FUEL"}}}');
    expect(isMarketDoesNotSellFuelException(exception), isTrue);
  });

  test('isInfuficientFuelException', () {
    final exception = ApiException(
        400,
        '{"error":{"message":"Navigate request failed. Ship ESEIDEL-2 '
        'requires 14 more fuel for '
        'navigation.","code":4203,"data":{"shipSymbol":"ESEIDEL-2", '
        '"fuelRequired":39,"fuelAvailable":25}}}');
    expect(isInfuficientFuelException(exception), isTrue);
  });

  test('isMaintenanceWindowException', () {
    final exception = ApiException(
        503,
        '{"error":{"message":"SpaceTraders is currently in maintenance mode '
        'and unavailable. This will hopefully only last a few minutes while we '
        'update or upgrade our servers. Check discord for updates '
        'https://discord.com/invite/jh6zurdWk5 and consider donating to keep '
        'the servers running '
        'https://donate.stripe.com/28o29m5vxcri6OccMM","code":503}}');
    expect(isMaintenanceWindowException(exception), isTrue);
  });

  test('isReservedHandleException', () {
    final exception = ApiException(
      400,
      '{"error":{"message":'
      '"Cannot register agent. Call sign has been reserved between resets: '
      'ESEIDEL. If you reserved your call sign and cannot register, please '
      'reach out on Discord, Twitter, or email us at '
      'contact@spacetraders.io","code":4110}}',
    );
    expect(isReservedHandleException(exception), isTrue);
  });

  test('isWaypointAlreadyChartedException', () {
    final exception = ApiException(
      400,
      '{"error":{"message":"Waypoint already charted: X1-ZY63-71980E", '
      '"code":4230,"data":{"waypointSymbol":"X1-ZY63-71980E"}}}',
    );
    expect(isWaypointAlreadyChartedException(exception), isTrue);
  });

  test('isInsufficientCreditsException', () {
    final exception = ApiException(
      400,
      '{"error":{"message":"Market purchase failed. Agent does not have '
      'sufficient credits to purchase 10 unit(s) of '
      'MODULE_MINERAL_PROCESSOR_I","code":4600,"data": '
      '{"agentCredits":44815,"totalPrice":44930,"tradeSymbol":'
      '"MODULE_MINERAL_PROCESSOR_I","units":10,"purchasePrice":4493}}}',
    );
    expect(isInsufficientCreditsException(exception), isTrue);
  });

  test('isShipNotInOrbitException', () {
    final exception = ApiException(
      400,
      '{"error":{"message":"Ship action failed. Ship is not currently in '
      'orbit at X1-PA79-91721F.","code":4236,"data":{"waypointSymbol" '
      ':"X1-PA79-91721F"}}}',
    );
    expect(isShipNotInOrbitException(exception), isTrue);
  });

  test('neededCreditsFromPurchaseShipException', () {
    final exception = ApiException(
      400,
      '{"error":{"message":"Failed to purchase ship. Agent has insufficient '
      'funds.","code":4216, "data":{"creditsAvailable":116103, '
      '"creditsNeeded":172355}}}',
    );
    expect(neededCreditsFromPurchaseShipException(exception), 172355);
  });
}
