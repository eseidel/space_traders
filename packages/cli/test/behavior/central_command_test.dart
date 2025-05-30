import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/config.dart';
import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../cache/caches_mock.dart';

class _MockApi extends Mock implements Api {}

class _MockBehaviorStore extends Mock implements BehaviorStore {}

class _MockBehaviorTimeouts extends Mock implements BehaviorTimeouts {}

class _MockChartingStore extends Mock implements ChartingStore {}

class _MockContractSnapshot extends Mock implements ContractSnapshot {}

class _MockContractTerms extends Mock implements ContractTerms {}

class _MockCostedDeal extends Mock implements CostedDeal {}

class _MockDatabase extends Mock implements Database {}

class _MockDeal extends Mock implements Deal {}

class _MockLogger extends Mock implements Logger {}

class _MockMarketListingStore extends Mock implements MarketListingStore {}

class _MockMarketPriceStore extends Mock implements MarketPriceStore {}

class _MockRoutePlanner extends Mock implements RoutePlanner {}

class _MockShip extends Mock implements Ship {}

class _MockShipCache extends Mock implements ShipSnapshot {}

class _MockShipFrame extends Mock implements ShipFrame {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipyardShipSnapshot extends Mock implements ShipyardShipSnapshot {}

class _MockShipyardListingSnapshot extends Mock
    implements ShipyardListingSnapshot {}

class _MockShipyardListingStore extends Mock implements ShipyardListingStore {}

class _MockSystemConnectivity extends Mock implements SystemConnectivity {}

class _MockSystemsStore extends Mock implements SystemsStore {}

class _MockShipyardShipStore extends Mock implements ShipyardShipStore {}

void main() {
  test('CentralCommand.otherCharterSystems', () async {
    RoutePlan fakeJump(WaypointSymbol start, WaypointSymbol end) {
      return RoutePlan(
        fuelCapacity: 10,
        shipSpeed: 10,
        actions: [
          RouteAction(
            startSymbol: start,
            endSymbol: end,
            type: RouteActionType.jump,
            seconds: 10,
            fuelUsed: 10,
          ),
        ],
      );
    }

    final db = _MockDatabase();

    final behaviorStore = _MockBehaviorStore();
    when(() => db.behaviors).thenReturn(behaviorStore);

    registerFallbackValue(BehaviorState.fallbackValue());
    registerFallbackValue(const ShipSymbol.fallbackValue());
    when(() => behaviorStore.upsert(any())).thenAnswer((_) async {});
    when(() => behaviorStore.delete(any())).thenAnswer((_) async {});
    final behaviors = BehaviorSnapshot([]);
    final ships = ShipSnapshot([]);

    final centralCommand = CentralCommand();

    Future<void> setupShip({
      required ShipSymbol shipSymbol,
      required WaypointSymbol start,
      required WaypointSymbol end,
    }) async {
      final ship = _MockShip();
      final shipNav = _MockShipNav();
      when(() => ship.symbol).thenReturn(shipSymbol);
      when(() => shipNav.waypointSymbol).thenReturn(start.waypoint);
      when(() => shipNav.systemSymbol).thenReturn(start.systemString);
      when(() => ship.nav).thenReturn(shipNav);
      final behaviorState = BehaviorState(
        shipSymbol,
        Behavior.charter,
        routePlan: fakeJump(start, end),
      );
      // This is a hack to modify the snapshots:
      behaviors.states.add(behaviorState);
      ships.ships.add(ship);
      when(
        () => behaviorStore.get(shipSymbol),
      ).thenAnswer((_) async => behaviorState);
    }

    // Sets up a ship X-A with a route from S-A-A to S-A-W.
    final shipASymbol = ShipSymbol.fromString('X-A');
    final aStart = WaypointSymbol.fromString('S-A-A');
    final aEnd = WaypointSymbol.fromString('S-A-W');
    await setupShip(shipSymbol: shipASymbol, start: aStart, end: aEnd);

    /// Sets up a ship X-B with a route from S-C-A to S-B-W.
    final shipBSymbol = ShipSymbol.fromString('X-B');
    final bStart = WaypointSymbol.fromString('S-C-A');
    final bEnd = WaypointSymbol.fromString('S-B-W');
    await setupShip(shipSymbol: shipBSymbol, start: bStart, end: bEnd);

    // Test that from S-A-A we avoid S-A-W and S-B-W.
    final otherSystems = centralCommand
        .otherCharterSystems(ships, behaviors, shipASymbol)
        .toList();
    expect(
      otherSystems,
      [bStart.system, bEnd.system], // Source and destination
    );
    // Forget shipB's plan and we should only avoid S-C-A (where shipB is).
    // This is another hack, modifying the snapshot:
    behaviors[shipBSymbol]?.routePlan = null;
    final otherSystems2 = centralCommand
        .otherCharterSystems(ships, behaviors, shipASymbol)
        .toList();
    expect(otherSystems2, [bStart.system]); // From nav.waypointSymbol

    final shipCSymbol = ShipSymbol.fromString('X-C');
    final cStart = WaypointSymbol.fromString('S-D-A');
    final cEnd = WaypointSymbol.fromString('S-E-W');
    await setupShip(shipSymbol: shipCSymbol, start: cStart, end: cEnd);
    final otherSystems4 = centralCommand
        .otherCharterSystems(ships, behaviors, shipASymbol)
        .toList();
    expect(otherSystems4, <SystemSymbol>[
      bStart.system,
      cStart.system,
      cEnd.system,
    ]);
  });

  test('CentralCommand.otherTraderSystems', () {
    final behaviors = BehaviorSnapshot([]);
    final ships = ShipSnapshot([]);
    final centralCommand = CentralCommand();
    expect(
      centralCommand.otherTraderSystems(
        ships,
        behaviors,
        ShipSymbol.fromString('X-A'),
      ),
      isEmpty,
    );
  });

  test('CentralCommand.affordableContracts', () {
    final ship = _MockShip();
    // TODO(eseidel): Contracts are disabled under 100000 credits.
    final agent = Agent.test(credits: 100000);
    final shipSymbol = ShipSymbol.fromString('X-A');
    when(() => ship.symbol).thenReturn(shipSymbol);
    // Unless we change Contract.isExpired to take a getNow, we need to use
    // a real DateTime here.
    final now = DateTime.timestamp();
    final hourFromNow = now.add(const Duration(hours: 1));
    final contract1 = Contract(
      id: '1',
      factionSymbol: 'faction',
      type: ContractType.PROCUREMENT,
      terms: ContractTerms(
        deadline: hourFromNow,
        payment: ContractPayment(onAccepted: 100000, onFulfilled: 100000),
        deliver: [
          ContractDeliverGood(
            tradeSymbol: 'T',
            destinationSymbol: 'W',
            unitsFulfilled: 0,
            unitsRequired: 1,
          ),
        ],
      ),
      deadlineToAccept: hourFromNow,
      accepted: false,
      fulfilled: false,
      timestamp: now,
    );
    final contract2 = Contract(
      id: '2',
      factionSymbol: 'faction',
      type: ContractType.PROCUREMENT,
      terms: ContractTerms(
        deadline: hourFromNow,
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
      deadlineToAccept: hourFromNow,
      accepted: false,
      fulfilled: false,
      timestamp: now,
    );
    final contracts = [contract1, contract2];
    final contractSnapshot = ContractSnapshot(contracts);
    final active = contractSnapshot.activeContracts;
    expect(active.length, 2);
    final affordable = affordableContracts(agent, contractSnapshot).toList();
    expect(affordable.length, 1);
    expect(affordable.first.id, '2');
  });

  test('CentralCommand.remainingUnitsNeededForContract', () {
    final shipCache = _MockShipCache();
    final shipASymbol = ShipSymbol.fromString('X-A');
    when(() => shipCache.shipSymbols).thenReturn([shipASymbol]);
    final costedDeal = _MockCostedDeal();
    final deal = _MockDeal();
    when(() => costedDeal.deal).thenReturn(deal);
    when(() => costedDeal.cargoSize).thenReturn(120);
    when(() => costedDeal.isContractDeal).thenReturn(true);
    when(() => deal.maxUnits).thenReturn(10);
    when(() => costedDeal.contractId).thenReturn('C');
    const tradeSymbol = TradeSymbol.FUEL;
    final behaviors = BehaviorSnapshot([
      BehaviorState(shipASymbol, Behavior.trader, deal: costedDeal),
    ]);
    final centralCommand = CentralCommand();
    final contractTerms = _MockContractTerms();
    final contract = Contract.test(id: 'C', terms: contractTerms);
    final good = ContractDeliverGood(
      tradeSymbol: tradeSymbol.value,
      destinationSymbol: 'W',
      unitsFulfilled: 50,
      unitsRequired: 100,
    );
    when(() => contractTerms.deliver).thenReturn([good]);
    expect(
      centralCommand.remainingUnitsNeededForContract(
        behaviors,
        contract,
        tradeSymbol,
      ),
      40,
    );
  });

  test('CentralCommand.remainingUnitsNeededForConstruction', () {
    final shipCache = _MockShipCache();
    final shipASymbol = ShipSymbol.fromString('X-A');
    when(() => shipCache.shipSymbols).thenReturn([shipASymbol]);
    final waypointSymbol = WaypointSymbol.fromString('W-A-Y');

    final costedDeal = _MockCostedDeal();
    final deal = _MockDeal();
    when(() => costedDeal.deal).thenReturn(deal);
    when(() => costedDeal.cargoSize).thenReturn(120);
    when(() => costedDeal.isContractDeal).thenReturn(false);
    when(() => costedDeal.isConstructionDeal).thenReturn(true);
    when(() => deal.destinationSymbol).thenReturn(waypointSymbol);
    when(() => deal.maxUnits).thenReturn(10);
    const tradeSymbol = TradeSymbol.FAB_MATS;
    final behaviors = BehaviorSnapshot([
      BehaviorState(shipASymbol, Behavior.trader, deal: costedDeal),
    ]);
    final centralCommand = CentralCommand();
    final construction = Construction(
      symbol: waypointSymbol.waypoint,
      isComplete: false,
      materials: [
        ConstructionMaterial(
          tradeSymbol: tradeSymbol,
          required_: 100,
          fulfilled: 30,
        ),
      ],
    );
    expect(
      centralCommand.remainingUnitsNeededForConstruction(
        behaviors,
        construction,
        tradeSymbol,
      ),
      60,
    );
  });

  test('idleHaulerSymbols', () {
    final shipCache = _MockShipCache();
    when(() => shipCache.ships).thenReturn([]);
    final empty = BehaviorSnapshot([]);
    final symbols = empty.idleHaulerSymbols(shipCache);
    expect(symbols, isEmpty);

    final ship = _MockShip();
    final shipFrame = _MockShipFrame();
    when(() => ship.frame).thenReturn(shipFrame);
    when(() => shipFrame.symbol).thenReturn(ShipFrameSymbol.LIGHT_FREIGHTER);
    when(() => ship.frame).thenReturn(shipFrame);
    final shipSymbol = ShipSymbol.fromString('X-A');
    when(() => ship.symbol).thenReturn(shipSymbol);
    when(() => shipCache.ships).thenReturn([ship]);
    final oneIdle = BehaviorSnapshot([
      BehaviorState(shipSymbol, Behavior.idle),
    ]);
    final symbols2 = oneIdle.idleHaulerSymbols(shipCache);
    expect(symbols2, [shipSymbol]);
  });

  test('dealsInProgress smoke test', () {
    final deal = _MockCostedDeal();
    final behaviors = BehaviorSnapshot([
      BehaviorState(ShipSymbol.fromString('X-A'), Behavior.miner),
      BehaviorState(ShipSymbol.fromString('X-B'), Behavior.trader),
      BehaviorState(ShipSymbol.fromString('X-C'), Behavior.trader)..deal = deal,
    ]);
    final deals = behaviors.dealsInProgress();
    expect(deals.length, 1);
    expect(deals.first, deal);
  });

  test('CentralCommand.shouldBuyShip', () async {
    final db = _MockDatabase();
    final shipCache = _MockShipCache();
    final centralCommand = CentralCommand();
    final ship = _MockShip();
    final shipSymbol = ShipSymbol.fromString('X-A');
    when(() => ship.symbol).thenReturn(shipSymbol);
    when(() => ship.registration).thenReturn(
      ShipRegistration(
        name: shipSymbol.symbol,
        factionSymbol: 'F',
        role: ShipRole.COMMAND,
      ),
    );
    final shipNav = _MockShipNav();
    final waypointSymbol = WaypointSymbol.fromString('W-A-Y');
    when(() => shipNav.systemSymbol).thenReturn(waypointSymbol.systemString);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipCache.ships).thenReturn([ship]);
    centralCommand.nextShipBuyJob = ShipBuyJob(
      shipyardSymbol: waypointSymbol,
      shipType: ShipType.HEAVY_FREIGHTER,
      minCreditsNeeded: 100,
    );
    // Currently we pad with 100k for trading.
    final paddingCredits = config.shipBuyBufferForTrading;
    final behaviorStore = _MockBehaviorStore();
    when(() => db.behaviors).thenReturn(behaviorStore);
    when(
      () => behaviorStore.ofType(Behavior.buyShip),
    ).thenAnswer((_) async => []);
    final systemConnectivity = _MockSystemConnectivity();
    registerFallbackValue(waypointSymbol.system);
    when(
      () => systemConnectivity.existsJumpPathBetween(any(), any()),
    ).thenReturn(true);

    final shouldBuy = await centralCommand.shouldBuyShip(
      db,
      systemConnectivity,
      ship,
      paddingCredits + 100,
    );
    expect(shouldBuy, true);

    // But stops if someone else is already buying.
    when(() => behaviorStore.ofType(Behavior.buyShip)).thenAnswer(
      (_) async => [BehaviorState(const ShipSymbol('A', 1), Behavior.buyShip)],
    );
    expect(
      await centralCommand.shouldBuyShip(db, systemConnectivity, ship, 100000),
      false,
    );

    final buyJob = centralCommand.takeShipBuyJob();
    expect(buyJob, isNotNull);
    expect(centralCommand.nextShipBuyJob, isNull);
  });

  test(
    'CentralCommand.templateForShip',
    () {
      Ship makeMiner(String shipSymbol) {
        final miner = _MockShip();
        when(() => miner.symbol).thenReturn(ShipSymbol.fromJson(shipSymbol));
        final minerFrame = _MockShipFrame();
        when(() => minerFrame.symbol).thenReturn(ShipFrameSymbol.MINER);
        when(() => miner.frame).thenReturn(minerFrame);
        when(() => miner.mounts).thenReturn([]);
        return miner;
      }

      List<Ship> makeMiners(int count) {
        final miners = <Ship>[];
        for (var i = 0; i < count; i++) {
          miners.add(makeMiner('M-$i'));
        }
        return miners;
      }

      // Miners should have a standard laser1, laser2, surveyor1 setup.
      final surveyAndMine = ShipTemplate(
        frameSymbol: ShipFrameSymbol.MINER,
        mounts: MountSymbolSet.from([
          ShipMountSymbol.MINING_LASER_II,
          ShipMountSymbol.MINING_LASER_II,
          ShipMountSymbol.SURVEYOR_I,
        ]),
      );
      final shipCache = _MockShipCache();
      final centralCommand = CentralCommand();

      final tenMiners = makeMiners(10);
      when(() => shipCache.ships).thenReturn(tenMiners);
      for (final miner in tenMiners) {
        expect(centralCommand.templateForShip(miner), surveyAndMine);
      }

      final surveyor = ShipTemplate(
        frameSymbol: ShipFrameSymbol.MINER,
        mounts: MountSymbolSet.from([
          ShipMountSymbol.SURVEYOR_II,
          ShipMountSymbol.SURVEYOR_II,
          ShipMountSymbol.SURVEYOR_II,
        ]),
      );
      // Move to survey2s once we have found survey2s
      centralCommand.setAvailableMounts(ShipMountSymbol.values);
      // Every 5th miner should be a surveyor.
      for (var i = 0; i < tenMiners.length; i++) {
        final template = centralCommand.templateForShip(tenMiners[i]);
        if (i % 5 == 0) {
          expect(template, surveyor);
        } else {
          expect(template, surveyAndMine);
        }
      }

      // Once we have surveyor2s we should move miners to only laser2s.
      final surveyorOne = tenMiners[0];
      final surveyorTwo = tenMiners[5];
      final surveyorMount = ShipMount(
        symbol: ShipMountSymbol.SURVEYOR_II,
        name: '',
        description: '',
        requirements: ShipRequirements(),
      );
      final surveyorOnlyMounts = [surveyorMount, surveyorMount, surveyorMount];
      when(() => surveyorOne.mounts).thenReturn(surveyorOnlyMounts);
      when(() => surveyorTwo.mounts).thenReturn(surveyorOnlyMounts);
      final mineOnly = ShipTemplate(
        frameSymbol: ShipFrameSymbol.MINER,
        mounts: MountSymbolSet.from([
          ShipMountSymbol.MINING_LASER_I,
          ShipMountSymbol.MINING_LASER_II,
          ShipMountSymbol.MINING_LASER_II,
        ]),
      );
      // Every 5th miner should be a surveyor.
      for (var i = 0; i < tenMiners.length; i++) {
        final template = centralCommand.templateForShip(tenMiners[i]);
        if (i % 5 == 0) {
          expect(template, surveyor);
        } else {
          expect(template, mineOnly);
        }
      }

      /// Even when we have surveyor2s, we should not to surveyOnly if we
      /// only have a single ship in a squad.
      final sixShips = makeMiners(6);
      when(() => shipCache.ships).thenReturn(sixShips);
      // Ships 2-5 won't mineOnly until the surveyor has its mounts.
      when(() => sixShips[0].mounts).thenReturn(surveyorOnlyMounts);
      expect(centralCommand.templateForShip(sixShips[0]), surveyor);
      expect(centralCommand.templateForShip(sixShips[1]), mineOnly);
      expect(centralCommand.templateForShip(sixShips[2]), mineOnly);
      expect(centralCommand.templateForShip(sixShips[3]), mineOnly);
      expect(centralCommand.templateForShip(sixShips[4]), mineOnly);
      // Even if we already have surveyors mounted on the first ship of a squad,
      // we should not specialize until we have two ships in a squad.
      when(() => sixShips[5].mounts).thenReturn(surveyorOnlyMounts);
      expect(centralCommand.templateForShip(sixShips[5]), surveyAndMine);

      // Once we have two ships in a squad then it's OK to specialize:
      final sevenShips = makeMiners(7);
      when(() => shipCache.ships).thenReturn(sevenShips);
      // Ships 2-5 won't mineOnly until the surveyor has its mounts.
      when(() => sevenShips[0].mounts).thenReturn(surveyorOnlyMounts);
      expect(centralCommand.templateForShip(sevenShips[0]), surveyor);
      expect(centralCommand.templateForShip(sevenShips[1]), mineOnly);
      expect(centralCommand.templateForShip(sevenShips[2]), mineOnly);
      expect(centralCommand.templateForShip(sevenShips[3]), mineOnly);
      expect(centralCommand.templateForShip(sevenShips[4]), mineOnly);
      // Ships 2+ won't mineOnly until the surveyor has its mounts.
      when(() => sevenShips[5].mounts).thenReturn(surveyorOnlyMounts);
      expect(centralCommand.templateForShip(sevenShips[5]), surveyor);
      expect(centralCommand.templateForShip(sevenShips[6]), mineOnly);
    },
    skip: 'Assumes too much about squad assignments.',
  );

  test('advanceCentralPlanning smoke test', () async {
    final db = _MockDatabase();
    final systemsStore = _MockSystemsStore();
    when(() => db.systems).thenReturn(systemsStore);
    final caches = mockCaches();
    const faction = FactionSymbol.AEGIS;
    final shipSymbol = ShipSymbol.fromString('X-A');
    final centralCommand = CentralCommand();
    final api = _MockApi();
    final hqSymbol = WaypointSymbol.fromString('W-A-Y');
    final hqSystemSymbol = hqSymbol.system;
    when(() => caches.systems.waypointsInSystem(hqSystemSymbol)).thenReturn([]);
    registerFallbackValue(ShipType.ORE_HOUND);
    when(() => caches.marketPrices.prices).thenReturn([]);
    registerFallbackValue(TradeSymbol.ADVANCED_CIRCUITRY);

    final marketListingStore = _MockMarketListingStore();
    when(() => db.marketListings).thenReturn(marketListingStore);
    when(
      () => marketListingStore.whichTrades(any()),
    ).thenAnswer((_) async => false);
    final agent = Agent.test(
      symbol: shipSymbol.agentName,
      headquarters: hqSymbol,
      credits: 100000,
      startingFaction: faction,
    );
    registerFallbackValue(agent);
    when(db.getMyAgent).thenAnswer((_) async => agent);

    when(
      marketListingStore.snapshotAll,
    ).thenAnswer((_) async => MarketListingSnapshot([]));
    when(db.allShips).thenAnswer((_) async => []);

    final shipyardListingStore = _MockShipyardListingStore();
    when(() => db.shipyardListings).thenReturn(shipyardListingStore);
    when(
      shipyardListingStore.snapshotAll,
    ).thenAnswer((_) async => ShipyardListingSnapshot([]));

    final behaviorStore = _MockBehaviorStore();
    when(() => db.behaviors).thenReturn(behaviorStore);
    when(() => behaviorStore.get(shipSymbol)).thenAnswer((_) async => null);

    final chartingStore = _MockChartingStore();
    when(() => db.charting).thenReturn(chartingStore);
    when(
      chartingStore.snapshotAllRecords,
    ).thenAnswer((_) async => ChartingSnapshot([]));
    when(
      () => chartingStore.chartedValues(hqSymbol),
    ).thenAnswer((_) async => ChartedValues.test(waypointSymbol: hqSymbol));

    final marketPriceStore = _MockMarketPriceStore();
    when(() => db.marketPrices).thenReturn(marketPriceStore);

    when(
      () => marketPriceStore.medianPurchasePrice(any()),
    ).thenAnswer((_) async => 100);

    final shipyardShipStore = _MockShipyardShipStore();
    when(() => db.shipyardShips).thenReturn(shipyardShipStore);

    when(
      shipyardShipStore.snapshot,
    ).thenAnswer((_) async => _MockShipyardShipSnapshot());

    when(systemsStore.snapshotAllSystems).thenAnswer(
      (_) async => SystemsSnapshot([
        System.test(
          hqSystemSymbol,
          waypoints: [
            SystemWaypoint.test(hqSymbol, type: WaypointType.JUMP_GATE),
          ],
        ),
      ]),
    );
    when(
      () => systemsStore.jumpGateWaypointForSystem(hqSystemSymbol),
    ).thenAnswer((_) async => null);

    registerFallbackValue(const WaypointSymbol.fallbackValue());

    final logger = _MockLogger();
    await runWithLogger(
      logger,
      () async => await centralCommand.advanceCentralPlanning(db, api, caches),
    );
    expect(centralCommand.nextShipBuyJob, isNull);
  });

  test('sellOppsForContracts', () {
    final now = DateTime(2021);
    final contractSnapshot = _MockContractSnapshot();
    final contract = Contract(
      id: '2',
      factionSymbol: 'faction',
      type: ContractType.PROCUREMENT,
      terms: ContractTerms(
        deadline: DateTime(2021),
        payment: ContractPayment(onAccepted: 1000, onFulfilled: 1000),
        deliver: [
          ContractDeliverGood(
            tradeSymbol: 'FUEL',
            destinationSymbol: 'A-B-C',
            unitsFulfilled: 0,
            unitsRequired: 10,
          ),
        ],
      ),
      deadlineToAccept: DateTime(2021),
      accepted: false,
      fulfilled: false,
      timestamp: now,
    );
    when(() => contractSnapshot.activeContracts).thenReturn([contract]);

    final agent = Agent.test(credits: 100000);

    int remainingUnitsNeededForContract(
      BehaviorSnapshot behaviors,
      Contract contract,
      TradeSymbol tradeSymbol,
    ) {
      return 1;
    }

    final behaviors = BehaviorSnapshot([]);
    final sellOpps = sellOppsForContracts(
      agent,
      behaviors,
      contractSnapshot,
      remainingUnitsNeededForContract: remainingUnitsNeededForContract,
    );
    expect(sellOpps.toList().length, 1);

    final centralCommand = CentralCommand();
    expect(
      centralCommand
          .contractSellOpps(agent, behaviors, contractSnapshot)
          .toList()
          .length,
      1,
    );
  });

  test('mountsNeededForAllShips', () {
    final centralCommand = CentralCommand();
    final ships = ShipSnapshot([]);
    expect(centralCommand.mountsNeededForAllShips(ships), isEmpty);
  });

  test('getJobForShip out of fuel', () async {
    final db = _MockDatabase();
    final centralCommand = CentralCommand();
    final shipSymbol = ShipSymbol.fromString('X-A');
    final ship = _MockShip();
    when(() => ship.symbol).thenReturn(shipSymbol);
    when(() => ship.fuel).thenReturn(ShipFuel(current: 0, capacity: 1000));
    final systemConnectivity = _MockSystemConnectivity();
    final job = await centralCommand.getJobForShip(
      db,
      systemConnectivity,
      ship,
      1000000,
    );
    // Can't do anything when out of fuel.
    expect(job.behavior, Behavior.idle);
  });

  test('getJobForShip no behaviors', () async {
    final db = _MockDatabase();
    final behaviorTimeouts = _MockBehaviorTimeouts();
    final centralCommand = CentralCommand(behaviorTimeouts: behaviorTimeouts);
    final shipSymbol = ShipSymbol.fromString('X-A');
    final ship = _MockShip();
    when(() => ship.symbol).thenReturn(shipSymbol);
    final shipFrame = _MockShipFrame();
    when(() => shipFrame.symbol).thenReturn(ShipFrameSymbol.LIGHT_FREIGHTER);
    when(() => ship.frame).thenReturn(shipFrame);
    when(() => ship.registration).thenReturn(
      ShipRegistration(
        name: shipSymbol.symbol,
        factionSymbol: 'F',
        role: ShipRole.COMMAND,
      ),
    );
    when(() => ship.fuel).thenReturn(ShipFuel(current: 1000, capacity: 1000));
    when(() => ship.fleetRole).thenReturn(FleetRole.command);

    registerFallbackValue(Behavior.idle);
    when(
      () => behaviorTimeouts.isBehaviorDisabledForShip(ship, any()),
    ).thenReturn(true);
    final systemConnectivity = _MockSystemConnectivity();
    final job = await centralCommand.getJobForShip(
      db,
      systemConnectivity,
      ship,
      1000000,
    );
    // Nothing specified for this ship, so it should be idle.
    expect(job.behavior, Behavior.idle);
  });

  test('shipToBuyFromPlan', () async {
    final shipyardShips = _MockShipyardShipSnapshot();
    final shipyardListingSnapshot = _MockShipyardListingSnapshot();
    final shipCache = _MockShipCache();
    when(
      () => shipyardListingSnapshot.knowOfShipyardWithShip(any()),
    ).thenReturn(true);

    final buySecond = [ShipType.COMMAND_FRIGATE, ShipType.EXPLORER];
    when(
      () => shipCache.countOfType(shipyardShips, ShipType.COMMAND_FRIGATE),
    ).thenReturn(1);
    when(
      () => shipCache.countOfType(shipyardShips, ShipType.EXPLORER),
    ).thenReturn(0);
    expect(
      await shipToBuyFromPlan(
        shipCache,
        buySecond,
        shipyardListingSnapshot,
        shipyardShips,
      ),
      ShipType.EXPLORER,
    );

    final buyFirst = [ShipType.EXPLORER, ShipType.COMMAND_FRIGATE];
    when(
      () => shipCache.countOfType(shipyardShips, ShipType.COMMAND_FRIGATE),
    ).thenReturn(1);
    when(
      () => shipCache.countOfType(shipyardShips, ShipType.EXPLORER),
    ).thenReturn(0);
    expect(
      await shipToBuyFromPlan(
        shipCache,
        buyFirst,
        shipyardListingSnapshot,
        shipyardShips,
      ),
      ShipType.EXPLORER,
    );

    final buyFourth = [
      ShipType.EXPLORER,
      ShipType.COMMAND_FRIGATE,
      ShipType.EXPLORER,
      ShipType.ORE_HOUND,
    ];
    when(
      () => shipCache.countOfType(shipyardShips, ShipType.COMMAND_FRIGATE),
    ).thenReturn(1);
    when(
      () => shipCache.countOfType(shipyardShips, ShipType.EXPLORER),
    ).thenReturn(2);
    when(
      () => shipCache.countOfType(shipyardShips, ShipType.ORE_HOUND),
    ).thenReturn(0);
    expect(
      await shipToBuyFromPlan(
        shipCache,
        buyFourth,
        shipyardListingSnapshot,
        shipyardShips,
      ),
      ShipType.ORE_HOUND,
    );
  });

  test('findNextDealAndLog smoke test', () async {
    final centralCommand = CentralCommand();
    final agent = Agent.test();
    final contractSnapshot = ContractSnapshot([]);
    final systemConnectivity = _MockSystemConnectivity();
    final behaviors = BehaviorSnapshot([]);
    final shipSymbol = ShipSymbol.fromString('X-A');
    final ship = Ship.test(shipSymbol);
    final marketPrices = MarketPriceSnapshot([]);
    final systems = SystemsSnapshot([]);
    final routePlanner = _MockRoutePlanner();

    final logger = _MockLogger();
    final deal = await runWithLogger(
      logger,
      () async => centralCommand.findNextDealAndLog(
        agent,
        contractSnapshot,
        marketPrices,
        systems,
        systemConnectivity,
        routePlanner,
        behaviors,
        ship,
        maxTotalOutlay: 1000000,
      ),
    );
    // We should fix this test to return a deal.
    verify(() => logger.detail('No deals within all known markets.')).called(1);
    expect(deal, isNull);
  });
}
