import 'package:cli/logic/printing.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('waypointDescription', () {
    final waypoint = Waypoint.test(
      WaypointSymbol.fromString('S-A-A'),
      type: WaypointType.PLANET,
      position: WaypointPosition(1, 2, SystemSymbol.fromString('S-A')),
      traits: [
        WaypointTrait(
          description: 't',
          name: 'n',
          symbol: WaypointTraitSymbol.CORRUPT,
        ),
      ],
    );
    expect(waypointDescription(waypoint), 'A-A - PLANET - uncharted - n');
  });

  test('durationString', () {
    // I don't like that it always shows hours and minutes, even if they're 0.
    // But that's what we have for now, so testing it.
    expect(durationString(Duration.zero), '00:00:00');
    expect(durationString(const Duration(seconds: 1)), '00:00:01');
    expect(durationString(const Duration(seconds: 60)), '00:01:00');
    expect(durationString(const Duration(seconds: 3600)), '01:00:00');
  });

  test('contractDescription', () {
    final deadline = DateTime.utc(2021);
    final now = DateTime.utc(2020);
    final contract = Contract(
      id: 'id',
      factionSymbol: 'faction',
      type: ContractTypeEnum.PROCUREMENT,
      terms: ContractTerms(
        deadline: deadline,
        payment: ContractPayment(onAccepted: 1000, onFulfilled: 1000),
        deliver: [
          ContractDeliverGood(
            tradeSymbol: 'T',
            destinationSymbol: 'W',
            unitsFulfilled: 0,
            unitsRequired: 10,
          ),
        ],
      ),
      deadlineToAccept: deadline,
      accepted: false,
      fulfilled: false,
      timestamp: now,
    );
    expect(
      contractDescription(
        contract,
        getNow: () => now,
      ),
      'deliver 10  T to W in 1y for 1,000c with 1,000c upfront',
    );
  });

  test('stringForPriceDeviance', () {
    const a = TradeSymbol.FUEL;
    expect(
      stringForPriceDeviance(
        a,
        price: 0,
        median: null,
        MarketTransactionTypeEnum.PURCHASE,
      ),
      '            🤷',
    );
  });

  test('approximateDuration', () {
    expect(approximateDuration(Duration.zero), '0ms');
    expect(approximateDuration(const Duration(microseconds: 1)), '0ms');
    expect(approximateDuration(const Duration(milliseconds: 1)), '1ms');
    expect(approximateDuration(const Duration(seconds: 1)), '1s');
    expect(approximateDuration(const Duration(seconds: 60)), '1m');
    expect(approximateDuration(const Duration(seconds: 3600)), '1h');
    expect(approximateDuration(const Duration(seconds: 3600 * 24)), '1d');
    expect(approximateDuration(const Duration(seconds: 3600 * 24 * 7)), '1w');
    expect(approximateDuration(const Duration(seconds: 3600 * 24 * 30)), '4w');
    expect(
      approximateDuration(const Duration(seconds: 3600 * 24 * 365)),
      '1y',
    );
    expect(
      approximateDuration(const Duration(seconds: 3600 * 24 * 365 * 3)),
      '3y',
    );

    expect(approximateDuration(-Duration.zero), '0ms');
    expect(approximateDuration(const Duration(microseconds: -1)), '0ms');
    expect(approximateDuration(const Duration(milliseconds: -1)), '-1ms');
    expect(approximateDuration(const Duration(seconds: -1)), '-1s');
    expect(approximateDuration(const Duration(seconds: -60)), '-1m');
    expect(approximateDuration(const Duration(seconds: -3600)), '-1h');
    expect(approximateDuration(const Duration(seconds: -3600 * 24)), '-1d');
    expect(approximateDuration(const Duration(seconds: -3600 * 24 * 7)), '-1w');
    expect(
      approximateDuration(const Duration(seconds: -3600 * 24 * 30)),
      '-4w',
    );
    expect(
      approximateDuration(const Duration(seconds: -3600 * 24 * 365)),
      '-1y',
    );
    expect(
      approximateDuration(const Duration(seconds: -3600 * 24 * 365 * 3)),
      '-3y',
    );

    // Rounding
    expect(
      approximateDuration(const Duration(minutes: 2, seconds: 45)),
      '3m',
    );
    expect(
      approximateDuration(const Duration(minutes: -2, seconds: -45)),
      '-3m',
    );
  });

  test('cargoDescription', () {
    final cargo = ShipCargo(
      capacity: 10,
      units: 10,
      inventory: [
        ShipCargoItem(
          symbol: TradeSymbol.FUEL,
          name: 'name',
          description: '',
          units: 1,
        ),
        ShipCargoItem(
          symbol: TradeSymbol.FABRICS,
          name: 'name2',
          description: '',
          units: 2,
        ),
      ],
    );
    expect(cargoDescription(cargo), '1 name, 2 name2');
  });
}
