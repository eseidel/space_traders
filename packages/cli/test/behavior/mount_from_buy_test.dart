import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/mount_from_buy.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../cache/caches_mock.dart';

class _MockAgent extends Mock implements Agent {}

class _MockApi extends Mock implements Api {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockDatabase extends Mock implements Database {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

class _MockShip extends Mock implements Ship {}

class _MockShipEngine extends Mock implements ShipEngine {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockSystemsApi extends Mock implements SystemsApi {}

void main() {
  setUpAll(() {
    registerFallbackValue(ShipSpec.fallbackValue());
  });

  test('advanceMountFromBuy smoke test', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final caches = mockCaches();
    final agent = _MockAgent();
    when(() => caches.agent.agent).thenReturn(agent);
    when(() => agent.credits).thenReturn(1000000);
    final ship = _MockShip();
    final shipNav = _MockShipNav();
    final centralCommand = _MockCentralCommand();

    final now = DateTime(2021);
    DateTime getNow() => now;
    const shipSymbol = ShipSymbol('S', 2);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    final waypointSymbol = WaypointSymbol.fromString('S-A-W');
    when(() => shipNav.waypointSymbol).thenReturn(waypointSymbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(waypointSymbol.system);
    when(() => ship.mounts).thenReturn([
      // A mount in our template, we will leave it be.
      ShipMount(
        symbol: ShipMountSymbolEnum.SURVEYOR_I,
        name: '',
        requirements: ShipRequirements(),
      ),
      // A mount not in our template (we will remove it)
      ShipMount(
        symbol: ShipMountSymbolEnum.LASER_CANNON_I,
        name: '',
        requirements: ShipRequirements(),
      ),
    ]);
    when(() => ship.modules).thenReturn([]);
    when(() => ship.reactor).thenReturn(
      ShipReactor(
        symbol: ShipReactorSymbolEnum.ANTIMATTER_I,
        name: 'name',
        description: 'description',
        powerOutput: 0,
        requirements: ShipRequirements(),
      ),
    );
    when(() => caches.agent.headquartersSymbol).thenReturn(waypointSymbol);
    when(() => ship.fuel).thenReturn(ShipFuel(current: 100, capacity: 100));
    final shipEngine = _MockShipEngine();
    when(() => shipEngine.speed).thenReturn(10);
    when(() => ship.engine).thenReturn(shipEngine);
    const toMount = TradeSymbol.MOUNT_SURVEYOR_II;
    final cargoItem = ShipCargoItem(
      symbol: toMount,
      name: '',
      description: '',
      units: 1,
    );
    final shipCargo = ShipCargo(
      capacity: 10,
      units: 1,
      inventory: [cargoItem],
    );
    when(() => ship.cargo).thenReturn(shipCargo);

    final tradeGood = MarketTradeGood(
      type: MarketTradeGoodTypeEnum.EXCHANGE,
      symbol: toMount,
      tradeVolume: 100,
      supply: SupplyLevel.ABUNDANT,
      purchasePrice: 100,
      sellPrice: 101,
    );
    when(() => caches.marketPrices.pricesFor(toMount)).thenReturn([
      MarketPrice.fromMarketTradeGood(tradeGood, waypointSymbol),
    ]);
    final market = Market(
      symbol: waypointSymbol.waypoint,
      tradeGoods: [
        tradeGood,
      ],
    );
    when(() => caches.markets.fromCache(waypointSymbol)).thenReturn(market);
    when(() => caches.markets.refreshMarket(waypointSymbol)).thenAnswer(
      (_) => Future.value(market),
    );
    registerFallbackValue(Duration.zero);
    when(
      () => caches.marketPrices.hasRecentData(
        waypointSymbol,
        maxAge: any(named: 'maxAge'),
      ),
    ).thenReturn(true);

    when(() => caches.waypoints.hasMarketplace(waypointSymbol))
        .thenAnswer((_) async => true);
    when(() => caches.waypoints.hasShipyard(waypointSymbol))
        .thenAnswer((_) async => true);

    when(
      () => caches.waypoints.waypointsInSystem(waypointSymbol.systemSymbol),
    ).thenAnswer((_) => Future.value([]));

    when(() => centralCommand.templateForShip(ship)).thenReturn(
      ShipTemplate(
        frameSymbol: ShipFrameSymbolEnum.CARRIER,
        mounts: MountSymbolSet.from([
          ShipMountSymbolEnum.SURVEYOR_I,
          ShipMountSymbolEnum.SURVEYOR_II,
        ]),
      ),
    );
    when(() => centralCommand.expectedCreditsPerSecond(ship)).thenReturn(7);

    final systemsApi = _MockSystemsApi();
    when(() => api.systems).thenReturn(systemsApi);
    when(
      () => systemsApi.getShipyard(
        waypointSymbol.system,
        waypointSymbol.waypoint,
      ),
    ).thenAnswer(
      (_) => Future.value(
        GetShipyard200Response(
          data: Shipyard(
            symbol: waypointSymbol.waypoint,
            modificationsFee: 10,
            shipTypes: [],
          ),
        ),
      ),
    );

    when(
      () => fleetApi.installMount(
        shipSymbol.symbol,
        installMountRequest: InstallMountRequest(symbol: toMount.value),
      ),
    ).thenAnswer(
      (_) => Future.value(
        InstallMount201Response(
          data: InstallMount201ResponseData(
            agent: agent,
            cargo: shipCargo,
            transaction: ShipModificationTransaction(
              waypointSymbol: waypointSymbol.waypoint,
              tradeSymbol: TradeSymbol.MOUNT_SURVEYOR_II.value,
              totalPrice: 100,
              shipSymbol: shipSymbol.symbol,
              timestamp: DateTime(2021),
            ),
          ),
        ),
      ),
    );
    when(
      () => fleetApi.removeMount(
        shipSymbol.symbol,
        removeMountRequest: RemoveMountRequest(
          symbol: ShipMountSymbolEnum.LASER_CANNON_I.value,
        ),
      ),
    ).thenAnswer(
      (_) => Future.value(
        RemoveMount201Response(
          data: RemoveMount201ResponseData(
            agent: agent,
            cargo: shipCargo,
            transaction: ShipModificationTransaction(
              waypointSymbol: waypointSymbol.waypoint,
              tradeSymbol: TradeSymbol.MOUNT_LASER_CANNON_I.value,
              totalPrice: 100,
              shipSymbol: shipSymbol.symbol,
              timestamp: DateTime(2021),
            ),
          ),
        ),
      ),
    );
    registerFallbackValue(Transaction.fallbackValue());
    when(() => db.insertTransaction(any())).thenAnswer((_) => Future.value());

    when(
      () => caches.routePlanner.planRoute(
        any(),
        start: waypointSymbol,
        end: waypointSymbol,
      ),
    ).thenReturn(
      RoutePlan.empty(
        symbol: waypointSymbol,
        fuelCapacity: 100,
        shipSpeed: 30,
      ),
    );

    final state = BehaviorState(shipSymbol, Behavior.mountFromBuy)
      ..buyJob = BuyJob(
        tradeSymbol: toMount,
        units: 1,
        buyLocation: waypointSymbol,
      )
      ..mountJob = MountJob(
        mountSymbol: mountSymbolForTradeSymbol(toMount)!,
        shipyardSymbol: waypointSymbol,
      );

    final logger = _MockLogger();
    expect(
      await runWithLogger(
        logger,
        () => advanceMountFromBuy(
          api,
          db,
          centralCommand,
          caches,
          state,
          ship,
          getNow: getNow,
        ),
      ),
      isNull,
    );
  });

  test('mountRequestForShip', () async {
    final ship = _MockShip();
    final waypointSymbol = WaypointSymbol.fromString('S-A-W');
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn(waypointSymbol.waypoint);
    when(() => ship.mounts).thenReturn([]);
    when(() => ship.fuel).thenReturn(ShipFuel(current: 100, capacity: 100));
    final shipEngine = _MockShipEngine();
    when(() => shipEngine.speed).thenReturn(10);
    when(() => ship.engine).thenReturn(shipEngine);
    final centralCommand = _MockCentralCommand();
    final caches = mockCaches();
    registerFallbackValue(TradeSymbol.ADVANCED_CIRCUITRY);
    when(() => caches.marketPrices.pricesFor(any())).thenReturn([]);

    final template = ShipTemplate(
      frameSymbol: ShipFrameSymbolEnum.CARRIER,
      mounts: MountSymbolSet.from([
        ShipMountSymbolEnum.SURVEYOR_I,
        ShipMountSymbolEnum.SURVEYOR_II,
      ]),
    );

    final request = await mountRequestForShip(
      centralCommand,
      caches,
      ship,
      template,
      expectedCreditsPerSecond: 7,
    );
    // We would need to return prices above for this to be non-null.
    expect(request, isNull);
  });
}
