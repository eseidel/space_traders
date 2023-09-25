import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/mount_from_buy.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/route.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockAgent extends Mock implements Agent {}

class _MockAgentCache extends Mock implements AgentCache {}

class _MockApi extends Mock implements Api {}

class _MockCaches extends Mock implements Caches {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockDatabase extends Mock implements Database {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

class _MockMarketCache extends Mock implements MarketCache {}

class _MockMarketPrices extends Mock implements MarketPrices {}

class _MockRoutePlanner extends Mock implements RoutePlanner {}

class _MockShip extends Mock implements Ship {}

class _MockShipCache extends Mock implements ShipCache {}

class _MockShipEngine extends Mock implements ShipEngine {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipyardPrices extends Mock implements ShipyardPrices {}

class _MockSystemsApi extends Mock implements SystemsApi {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockWaypoint extends Mock implements Waypoint {}

class _MockWaypointCache extends Mock implements WaypointCache {}

void main() {
  test('advanceMountFromBuy smoke test', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final agentCache = _MockAgentCache();
    final agent = _MockAgent();
    when(() => agentCache.agent).thenReturn(agent);
    when(() => agent.credits).thenReturn(1000000);
    final ship = _MockShip();
    final systemsCache = _MockSystemsCache();
    final waypointCache = _MockWaypointCache();
    final shipNav = _MockShipNav();
    final centralCommand = _MockCentralCommand();
    final caches = _MockCaches();
    final shipCache = _MockShipCache();
    when(() => caches.ships).thenReturn(shipCache);
    when(() => caches.waypoints).thenReturn(waypointCache);
    when(() => caches.agent).thenReturn(agentCache);
    when(() => caches.systems).thenReturn(systemsCache);
    final routePlanner = _MockRoutePlanner();
    when(() => caches.routePlanner).thenReturn(routePlanner);
    final marketPrices = _MockMarketPrices();
    when(() => caches.marketPrices).thenReturn(marketPrices);
    final shipyardPrices = _MockShipyardPrices();
    when(() => caches.shipyardPrices).thenReturn(shipyardPrices);
    final marketCache = _MockMarketCache();
    when(() => caches.markets).thenReturn(marketCache);

    final now = DateTime(2021);
    DateTime getNow() => now;
    const shipSymbol = ShipSymbol('S', 2);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    final symbol = WaypointSymbol.fromString('S-A-W');
    when(() => shipNav.waypointSymbol).thenReturn(symbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(symbol.system);
    when(() => ship.mounts).thenReturn([
      ShipMount(
        symbol: ShipMountSymbolEnum.SURVEYOR_I,
        name: '',
        requirements: ShipRequirements(),
      ),
    ]);
    when(() => agentCache.headquartersSymbol).thenReturn(symbol);
    when(() => ship.fuel).thenReturn(ShipFuel(current: 100, capacity: 100));
    final shipEngine = _MockShipEngine();
    when(() => shipEngine.speed).thenReturn(10);
    when(() => ship.engine).thenReturn(shipEngine);
    const toMount = TradeSymbol.MOUNT_SURVEYOR_II;
    final cargoItem = ShipCargoItem(
      symbol: toMount.value,
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
      symbol: toMount.value,
      tradeVolume: 100,
      supply: MarketTradeGoodSupplyEnum.ABUNDANT,
      purchasePrice: 100,
      sellPrice: 101,
    );
    when(() => marketPrices.pricesFor(toMount)).thenReturn([
      MarketPrice.fromMarketTradeGood(tradeGood, symbol),
    ]);
    when(() => marketCache.marketForSymbol(symbol)).thenAnswer(
      (_) => Future.value(
        Market(
          symbol: symbol.waypoint,
          tradeGoods: [
            tradeGood,
          ],
        ),
      ),
    );
    registerFallbackValue(Duration.zero);
    when(
      () => marketPrices.hasRecentMarketData(
        symbol,
        maxAge: any(named: 'maxAge'),
      ),
    ).thenReturn(true);

    final waypoint = _MockWaypoint();
    when(() => waypoint.symbol).thenReturn(symbol.waypoint);
    when(() => waypoint.type).thenReturn(WaypointType.ASTEROID_FIELD);
    when(() => waypoint.traits).thenReturn([
      WaypointTrait(
        description: '',
        name: '',
        symbol: WaypointTraitSymbolEnum.SHIPYARD,
      ),
      WaypointTrait(
        symbol: WaypointTraitSymbolEnum.MARKETPLACE,
        name: '',
        description: '',
      ),
    ]);
    when(() => waypoint.systemSymbol).thenReturn(symbol.system);

    registerFallbackValue(symbol);
    when(() => waypointCache.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));
    registerFallbackValue(symbol.systemSymbol);

    when(
      () => waypointCache.waypointsInSystem(any()),
    ).thenAnswer((_) => Future.value([waypoint]));

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
    when(() => systemsApi.getShipyard(symbol.system, symbol.waypoint))
        .thenAnswer(
      (_) => Future.value(
        GetShipyard200Response(
          data: Shipyard(
            symbol: symbol.waypoint,
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
              waypointSymbol: symbol.waypoint,
              tradeSymbol: TradeSymbol.MOUNT_SURVEYOR_II.value,
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
      () => routePlanner.planRoute(
        start: symbol,
        end: symbol,
        fuelCapacity: any(named: 'fuelCapacity'),
        shipSpeed: any(named: 'shipSpeed'),
      ),
    ).thenReturn(
      RoutePlan.empty(
        symbol: symbol,
        fuelCapacity: 100,
        shipSpeed: 30,
      ),
    );

    final state = BehaviorState(shipSymbol, Behavior.mountFromDelivery)
      ..buyJob = BuyJob(
        tradeSymbol: toMount,
        units: 1,
        buyLocation: symbol,
      )
      ..mountJob = MountJob(
        mountSymbol: mountSymbolForTradeSymbol(toMount)!,
        shipyardSymbol: symbol,
      );

    final logger = _MockLogger();
    expect(
      () async {
        final waitUntil = await runWithLogger(
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
        );
        return waitUntil;
      },
      throwsA(
        const JobException(
          'Mounting complete!',
          Duration(hours: 1),
        ),
      ),
    );
  });
}
