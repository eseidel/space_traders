import 'package:cli/cache/market_prices.dart';
import 'package:cli/printing.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('waypointDescription', () {
    final waypoint = Waypoint(
      symbol: 'a',
      type: WaypointType.PLANET,
      systemSymbol: 'c',
      x: 1,
      y: 2,
      orbitals: [],
      faction: WaypointFaction(symbol: FactionSymbols.AEGIS),
      traits: [
        WaypointTrait(
          description: 't',
          name: 'n',
          symbol: WaypointTraitSymbolEnum.CORRUPT,
        ),
      ],
      isUnderConstruction: true,
    );
    expect(waypointDescription(waypoint), 'a - PLANET - uncharted - n');
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
      expiration: deadline,
      deadlineToAccept: deadline,
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
    final fs = MemoryFileSystem.test();
    final marketPrices = MarketPrices([], fs: fs);
    const a = TradeSymbol.FUEL;
    expect(
      stringForPriceDeviance(
        marketPrices,
        a,
        0,
        MarketTransactionTypeEnum.PURCHASE,
      ),
      '            🤷',
    );
    marketPrices.addPrices([
      MarketPrice(
        waypointSymbol: WaypointSymbol.fromString('S-A-W'),
        symbol: a,
        supply: SupplyLevel.ABUNDANT,
        purchasePrice: 1,
        sellPrice: 2,
        tradeVolume: 100,
        timestamp: DateTime.timestamp(),
      ),
    ]);

    expect(
      stringForPriceDeviance(
        marketPrices,
        a,
        0,
        MarketTransactionTypeEnum.PURCHASE,
      ),
      lightGreen.wrap('-100%  -1c per'),
    );
    expect(
      stringForPriceDeviance(
        marketPrices,
        a,
        0,
        MarketTransactionTypeEnum.SELL,
      ),
      lightRed.wrap('-100%  -2c per'),
    );
    expect(
      stringForPriceDeviance(
        marketPrices,
        a,
        2,
        MarketTransactionTypeEnum.SELL,
      ),
      '            ⚖️ ',
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
