import 'package:cli/behavior/mount_from_buy.dart';
import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../cache/caches_mock.dart';

class _MockApi extends Mock implements Api {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockDatabase extends Mock implements Database {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

class _MockMarketPriceStore extends Mock implements MarketPriceStore {}

class _MockShip extends Mock implements Ship {}

class _MockShipEngine extends Mock implements ShipEngine {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockSystemsApi extends Mock implements SystemsApi {}

class _MockRoutePlanner extends Mock implements RoutePlanner {}

class _MockShipyardListingSnapshot extends Mock
    implements ShipyardListingSnapshot {}

class _MockShipyardPriceStore extends Mock implements ShipyardPriceStore {}

class _MockTransactionStore extends Mock implements TransactionStore {}

class _MockShipMountStore extends Mock implements ShipMountStore {}

class _MockShipModuleStore extends Mock implements ShipModuleStore {}

class _MockShipEngineStore extends Mock implements ShipEngineStore {}

class _MockShipReactorStore extends Mock implements ShipReactorStore {}

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
    final agent = Agent.test();
    registerFallbackValue(agent);
    when(() => db.upsertAgent(any())).thenAnswer((_) async {});
    when(db.getMyAgent).thenAnswer((_) async => agent);

    final ship = _MockShip();
    when(() => ship.fleetRole).thenReturn(FleetRole.command);

    final shipNav = _MockShipNav();
    final centralCommand = _MockCentralCommand();

    final now = DateTime(2021);
    DateTime getNow() => now;
    const shipSymbol = ShipSymbol('S', 2);
    when(() => ship.symbol).thenReturn(shipSymbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    final waypointSymbol = WaypointSymbol.fromString('S-A-W');
    when(() => shipNav.waypointSymbol).thenReturn(waypointSymbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(waypointSymbol.systemString);
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
        condition: 1,
        quality: 1,
        integrity: 1,
      ),
    );
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
    final shipCargo = ShipCargo(capacity: 10, units: 1, inventory: [cargoItem]);
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
      MarketPrice.fromMarketTradeGood(tradeGood, waypointSymbol, now),
    ]);
    final market = Market(
      symbol: waypointSymbol.waypoint,
      tradeGoods: [tradeGood],
    );
    when(() => caches.markets.fromCache(waypointSymbol)).thenReturn(market);
    when(
      () => caches.markets.refreshMarket(waypointSymbol),
    ).thenAnswer((_) => Future.value(market));

    final marketPricesStore = _MockMarketPriceStore();
    when(() => db.marketPrices).thenReturn(marketPricesStore);

    registerFallbackValue(Duration.zero);
    when(
      () => marketPricesStore.hasRecentAt(waypointSymbol, any()),
    ).thenAnswer((_) async => true);

    final shipyardPriceStore = _MockShipyardPriceStore();
    when(() => db.shipyardPrices).thenReturn(shipyardPriceStore);

    when(
      () => shipyardPriceStore.hasRecent(waypointSymbol, any()),
    ).thenAnswer((_) async => true);

    when(
      () => caches.waypoints.hasMarketplace(waypointSymbol),
    ).thenAnswer((_) async => true);
    when(
      () => caches.waypoints.hasShipyard(waypointSymbol),
    ).thenAnswer((_) async => true);

    when(
      () => caches.waypoints.waypointsInSystem(waypointSymbol.system),
    ).thenAnswer((_) async => []);

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
        waypointSymbol.systemString,
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
            agent: agent.toOpenApi(),
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
            agent: agent.toOpenApi(),
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

    final transactionStore = _MockTransactionStore();
    when(() => db.transactions).thenReturn(transactionStore);

    registerFallbackValue(Transaction.fallbackValue());
    when(() => transactionStore.insert(any())).thenAnswer((_) async {});

    when(
      () => caches.routePlanner.planRoute(
        any(),
        start: waypointSymbol,
        end: waypointSymbol,
      ),
    ).thenReturn(
      RoutePlan.empty(symbol: waypointSymbol, fuelCapacity: 100, shipSpeed: 30),
    );

    final state =
        BehaviorState(shipSymbol, Behavior.mountFromBuy)
          ..buyJob = BuyJob(
            tradeSymbol: toMount,
            units: 1,
            buyLocation: waypointSymbol,
          )
          ..mountJob = MountJob(
            mountSymbol: mountSymbolForTradeSymbol(toMount)!,
            shipyardSymbol: waypointSymbol,
          );
    when(() => db.upsertShip(ship)).thenAnswer((_) async {});

    final marketPriceStore = _MockMarketPriceStore();
    when(() => db.marketPrices).thenReturn(marketPriceStore);

    registerFallbackValue(TradeSymbol.ADVANCED_CIRCUITRY);
    when(
      () => marketPriceStore.medianPurchasePrice(any()),
    ).thenAnswer((_) async => 100);
    registerFallbackValue(waypointSymbol);
    registerFallbackValue(Duration.zero);
    when(
      () => marketPriceStore.hasRecentAt(any(), any()),
    ).thenAnswer((_) async => true);

    registerFallbackValue(ship.engine);
    when(() => db.shipEngines.add(any())).thenAnswer((_) async {});
    registerFallbackValue(ship.reactor);
    when(() => db.shipReactors.add(any())).thenAnswer((_) async {});

    final shipMountStore = _MockShipMountStore();
    when(() => db.shipMounts).thenReturn(shipMountStore);
    registerFallbackValue(ship.mounts.first);
    when(() => shipMountStore.addAll(any())).thenAnswer((_) async {});

    final shipModuleStore = _MockShipModuleStore();
    when(() => db.shipModules).thenReturn(shipModuleStore);
    registerFallbackValue(testShipModule());
    when(() => shipModuleStore.addAll(any())).thenAnswer((_) async {});

    final shipEngineStore = _MockShipEngineStore();
    when(() => db.shipEngines).thenReturn(shipEngineStore);
    registerFallbackValue(ship.engine);
    when(() => shipEngineStore.add(any())).thenAnswer((_) async {});

    final shipReactorStore = _MockShipReactorStore();
    when(() => db.shipReactors).thenReturn(shipReactorStore);
    registerFallbackValue(ship.reactor);
    when(() => shipReactorStore.add(any())).thenAnswer((_) async {});

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
    final cargo = ShipCargo(capacity: 100, units: 0);
    when(() => ship.cargo).thenReturn(cargo);
    when(() => ship.modules).thenReturn([]);
    final routePlanner = _MockRoutePlanner();

    final centralCommand = _MockCentralCommand();
    final caches = mockCaches();
    registerFallbackValue(TradeSymbol.ADVANCED_CIRCUITRY);
    when(() => caches.marketPrices.pricesFor(any())).thenReturn([]);
    final shipyardListings = _MockShipyardListingSnapshot();

    final template = ShipTemplate(
      frameSymbol: ShipFrameSymbolEnum.CARRIER,
      mounts: MountSymbolSet.from([
        ShipMountSymbolEnum.SURVEYOR_I,
        ShipMountSymbolEnum.SURVEYOR_II,
      ]),
    );

    final request = await mountRequestForShip(
      centralCommand,
      caches.marketPrices,
      routePlanner,
      shipyardListings,
      ship,
      template,
      expectedCreditsPerSecond: 7,
    );
    // We would need to return prices above for this to be non-null.
    expect(request, isNull);
  });
}
