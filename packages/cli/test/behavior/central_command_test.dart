import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/config.dart';
import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../cache/caches_mock.dart';

class _MockAgentCache extends Mock implements AgentCache {}

class _MockApi extends Mock implements Api {}

class _MockBehaviorCache extends Mock implements BehaviorCache {}

class _MockContractSnapshot extends Mock implements ContractSnapshot {}

class _MockContractTerms extends Mock implements ContractTerms {}

class _MockCostedDeal extends Mock implements CostedDeal {}

class _MockDatabase extends Mock implements Database {}

class _MockDeal extends Mock implements Deal {}

class _MockLogger extends Mock implements Logger {}

class _MockShip extends Mock implements Ship {}

class _MockShipCache extends Mock implements ShipCache {}

class _MockShipFrame extends Mock implements ShipFrame {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipyardPrices extends Mock implements ShipyardPrices {}

class _MockShipyardShipCache extends Mock implements ShipyardShipCache {}

void main() {
  test('CentralCommand.otherCharterSystems', () {
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

    final fs = MemoryFileSystem.test();
    final behaviorCache = BehaviorCache.load(fs);
    final shipCache = _MockShipCache();
    final centralCommand =
        CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);

    void setupShip({
      required ShipSymbol shipSymbol,
      required WaypointSymbol start,
      required WaypointSymbol end,
    }) {
      final ship = _MockShip();
      final shipNav = _MockShipNav();
      when(() => ship.symbol).thenReturn(shipSymbol.symbol);
      when(() => shipNav.waypointSymbol).thenReturn(start.waypoint);
      when(() => shipNav.systemSymbol).thenReturn(start.systemString);
      when(() => ship.nav).thenReturn(shipNav);
      behaviorCache.setBehavior(
        shipSymbol,
        BehaviorState(
          shipSymbol,
          Behavior.charter,
          routePlan: fakeJump(start, end),
        ),
      );
      when(() => shipCache[shipSymbol]).thenReturn(ship);
    }

    // Sets up a ship X-A with a route from S-A-A to S-A-W.
    final shipASymbol = ShipSymbol.fromString('X-A');
    final aStart = WaypointSymbol.fromString('S-A-A');
    final aEnd = WaypointSymbol.fromString('S-A-W');
    setupShip(shipSymbol: shipASymbol, start: aStart, end: aEnd);

    /// Sets up a ship X-B with a route from S-C-A to S-B-W.
    final shipBSymbol = ShipSymbol.fromString('X-B');
    final bStart = WaypointSymbol.fromString('S-C-A');
    final bEnd = WaypointSymbol.fromString('S-B-W');
    setupShip(shipSymbol: shipBSymbol, start: bStart, end: bEnd);

    // Test that from S-A-A we avoid S-A-W and S-B-W.
    final otherSystems =
        centralCommand.otherCharterSystems(shipASymbol).toList();
    expect(
      otherSystems,
      [bStart.system, bEnd.system], // Source and destination
    );
    // Forget shipB's plan and we should only avoid S-C-A (where shipB is).
    behaviorCache.getBehavior(shipBSymbol)!.routePlan = null;
    final otherSystems2 =
        centralCommand.otherCharterSystems(shipASymbol).toList();
    expect(otherSystems2, [bStart.system]); // From nav.waypointSymbol

    // Remove shipB and we should avoid nothing.
    behaviorCache.deleteBehavior(shipBSymbol);
    final otherSystems3 =
        centralCommand.otherCharterSystems(shipASymbol).toList();
    expect(otherSystems3, <SystemSymbol>[]);

    final shipCSymbol = ShipSymbol.fromString('X-C');
    final cStart = WaypointSymbol.fromString('S-D-A');
    final cEnd = WaypointSymbol.fromString('S-E-W');
    setupShip(shipSymbol: shipCSymbol, start: cStart, end: cEnd);
    final otherSystems4 =
        centralCommand.otherCharterSystems(shipASymbol).toList();
    expect(
      otherSystems4,
      <SystemSymbol>[cStart.system, cEnd.system],
    );
  });

  test('CentralCommand.otherTraderSystems', () {
    final behaviorCache = _MockBehaviorCache();
    when(() => behaviorCache.states).thenReturn([]);
    final shipCache = _MockShipCache();
    final centralCommand =
        CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);
    expect(
      centralCommand.otherTraderSystems(ShipSymbol.fromString('X-A')),
      isEmpty,
    );
  });

  test('CentralCommand.affordableContracts', () {
    final ship = _MockShip();
    // TODO(eseidel): Contracts are disabled under 100000 credits.
    final agent = Agent.test(credits: 100000);
    final db = _MockDatabase();
    final agentCache = AgentCache(agent, db);
    when(() => ship.symbol).thenReturn('S');
    // Unless we change Contract.isExpired to take a getNow, we need to use
    // a real DateTime here.
    final now = DateTime.timestamp();
    final hourFromNow = now.add(const Duration(hours: 1));
    final contract1 = Contract(
      id: '1',
      factionSymbol: 'faction',
      type: ContractTypeEnum.PROCUREMENT,
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
      type: ContractTypeEnum.PROCUREMENT,
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
    final affordable =
        affordableContracts(agentCache, contractSnapshot).toList();
    expect(affordable.length, 1);
    expect(affordable.first.id, '2');
  });

  test('CentralCommand.remainingUnitsNeededForContract', () {
    final behaviorCache = _MockBehaviorCache();
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
    when(() => behaviorCache.states).thenReturn([
      BehaviorState(shipASymbol, Behavior.trader, deal: costedDeal),
    ]);
    final centralCommand =
        CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);
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
      centralCommand.remainingUnitsNeededForContract(contract, tradeSymbol),
      40,
    );
  });

  test('CentralCommand.remainingUnitsNeededForConstruction', () {
    final behaviorCache = _MockBehaviorCache();
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
    when(() => behaviorCache.states).thenReturn([
      BehaviorState(shipASymbol, Behavior.trader, deal: costedDeal),
    ]);
    final centralCommand =
        CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);
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
        construction,
        tradeSymbol,
      ),
      60,
    );
  });

  test('idleHaulerSymbols', () {
    final shipCache = _MockShipCache();
    when(() => shipCache.ships).thenReturn([]);
    final behaviorCache = _MockBehaviorCache();
    when(() => behaviorCache.states).thenReturn([]);
    final symbols = idleHaulerSymbols(shipCache, behaviorCache);
    expect(symbols, isEmpty);

    final ship = _MockShip();
    final shipFrame = _MockShipFrame();
    when(() => ship.frame).thenReturn(shipFrame);
    when(() => shipFrame.symbol)
        .thenReturn(ShipFrameSymbolEnum.LIGHT_FREIGHTER);
    when(() => ship.frame).thenReturn(shipFrame);
    final shipSymbol = ShipSymbol.fromString('X-A');
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => shipCache.ships).thenReturn([ship]);
    when(() => behaviorCache.states).thenReturn(
      [BehaviorState(shipSymbol, Behavior.idle)],
    );
    final symbols2 = idleHaulerSymbols(shipCache, behaviorCache);
    expect(symbols2, [shipSymbol]);
  });

  test('dealsInProgress smoke test', () {
    final deal = _MockCostedDeal();
    final cache = BehaviorCache(
      {
        ShipSymbol.fromString('X-A'):
            BehaviorState(ShipSymbol.fromString('X-A'), Behavior.miner),
        ShipSymbol.fromString('X-B'):
            BehaviorState(ShipSymbol.fromString('X-B'), Behavior.trader),
        ShipSymbol.fromString('X-C'):
            BehaviorState(ShipSymbol.fromString('X-C'), Behavior.trader)
              ..deal = deal,
      },
      fs: MemoryFileSystem.test(),
    );
    final deals = cache.dealsInProgress();
    expect(deals.length, 1);
    expect(deals.first, deal);
  });

  test('CentralCommand.shouldBuyShip', () {
    final shipCache = _MockShipCache();
    final behaviorCache = _MockBehaviorCache();
    when(() => behaviorCache.states).thenReturn([]);
    final centralCommand =
        CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);
    final ship = _MockShip();
    final shipSymbol = ShipSymbol.fromString('X-A');
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.registration).thenReturn(
      ShipRegistration(
        name: shipSymbol.symbol,
        factionSymbol: 'F',
        role: ShipRole.COMMAND,
      ),
    );
    final shipNav = _MockShipNav();
    when(() => shipNav.systemSymbol).thenReturn('W-A');
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipCache.ships).thenReturn([ship]);
    centralCommand.nextShipBuyJob = ShipBuyJob(
      shipyardSymbol: WaypointSymbol.fromString('W-A-Y'),
      shipType: ShipType.HEAVY_FREIGHTER,
      minCreditsNeeded: 100,
    );
    // Currently we pad with 100k for trading.
    final paddingCredits = config.shipBuyBufferForTrading;
    final shouldBuy = centralCommand.shouldBuyShip(ship, paddingCredits + 100);
    expect(shouldBuy, true);

    // But stops if someone else is already buying.
    when(() => behaviorCache.states).thenReturn([
      BehaviorState(const ShipSymbol('A', 1), Behavior.buyShip),
    ]);
    expect(centralCommand.shouldBuyShip(ship, 100000), false);

    final buyJob = centralCommand.takeShipBuyJob();
    expect(buyJob, isNotNull);
    expect(centralCommand.nextShipBuyJob, isNull);
  });

  test(
    'CentralCommand.templateForShip',
    () {
      Ship makeMiner(String shipSymbol) {
        final miner = _MockShip();
        when(() => miner.symbol).thenReturn(shipSymbol);
        final minerFrame = _MockShipFrame();
        when(() => minerFrame.symbol).thenReturn(ShipFrameSymbolEnum.MINER);
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
        frameSymbol: ShipFrameSymbolEnum.MINER,
        mounts: MountSymbolSet.from([
          ShipMountSymbolEnum.MINING_LASER_II,
          ShipMountSymbolEnum.MINING_LASER_II,
          ShipMountSymbolEnum.SURVEYOR_I,
        ]),
      );
      final shipCache = _MockShipCache();
      final behaviorCache = _MockBehaviorCache();
      final centralCommand =
          CentralCommand(shipCache: shipCache, behaviorCache: behaviorCache);

      final tenMiners = makeMiners(10);
      when(() => shipCache.ships).thenReturn(tenMiners);
      for (final miner in tenMiners) {
        expect(centralCommand.templateForShip(miner), surveyAndMine);
      }

      final surveyor = ShipTemplate(
        frameSymbol: ShipFrameSymbolEnum.MINER,
        mounts: MountSymbolSet.from([
          ShipMountSymbolEnum.SURVEYOR_II,
          ShipMountSymbolEnum.SURVEYOR_II,
          ShipMountSymbolEnum.SURVEYOR_II,
        ]),
      );
      // Move to survey2s once we have found survey2s
      centralCommand.setAvailableMounts(ShipMountSymbolEnum.values);
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
        symbol: ShipMountSymbolEnum.SURVEYOR_II,
        name: '',
        requirements: ShipRequirements(),
      );
      final surveyorOnlyMounts = [surveyorMount, surveyorMount, surveyorMount];
      when(() => surveyorOne.mounts).thenReturn(surveyorOnlyMounts);
      when(() => surveyorTwo.mounts).thenReturn(surveyorOnlyMounts);
      final mineOnly = ShipTemplate(
        frameSymbol: ShipFrameSymbolEnum.MINER,
        mounts: MountSymbolSet.from([
          ShipMountSymbolEnum.MINING_LASER_I,
          ShipMountSymbolEnum.MINING_LASER_II,
          ShipMountSymbolEnum.MINING_LASER_II,
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
    final caches = mockCaches();
    final ship = _MockShip();
    final shipNav = _MockShipNav();
    const faction = FactionSymbol.AEGIS;
    when(() => shipNav.systemSymbol).thenReturn('W-A');
    when(() => ship.nav).thenReturn(shipNav);
    final shipSymbol = ShipSymbol.fromString('X-A');
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    final shipFrame = _MockShipFrame();
    when(() => ship.frame).thenReturn(shipFrame);
    when(() => shipFrame.symbol)
        .thenReturn(ShipFrameSymbolEnum.LIGHT_FREIGHTER);
    when(() => ship.frame).thenReturn(shipFrame);
    when(() => ship.registration).thenReturn(
      ShipRegistration(
        name: shipSymbol.symbol,
        factionSymbol: faction.value,
        role: ShipRole.COMMAND,
      ),
    );
    when(() => caches.ships.ships).thenReturn([ship]);
    final centralCommand = CentralCommand(
      behaviorCache: caches.behaviors,
      shipCache: caches.ships,
    );
    final api = _MockApi();
    final hqSymbol = WaypointSymbol.fromString('W-A-Y');
    final hqSystemSymbol = hqSymbol.system;
    when(() => caches.agent.headquartersSystemSymbol)
        .thenReturn(hqSystemSymbol);
    when(() => caches.systems.waypointsInSystem(hqSystemSymbol)).thenReturn([]);
    when(() => caches.shipyardPrices.prices).thenReturn([]);
    when(() => caches.shipyardPrices.pricesFor(ShipType.ORE_HOUND))
        .thenReturn([]);
    registerFallbackValue(ShipType.ORE_HOUND);
    when(() => caches.shipyardPrices.havePriceFor(any())).thenReturn(true);
    when(() => caches.shipyardPrices.pricesFor(any())).thenReturn([]);
    when(() => caches.marketPrices.prices).thenReturn([]);
    registerFallbackValue(TradeSymbol.ADVANCED_CIRCUITRY);
    when(() => caches.marketPrices.havePriceFor(any())).thenReturn(false);
    when(() => caches.ships.countOfFrame(ShipFrameSymbolEnum.MINER))
        .thenReturn(0);

    when(
      () => caches.ships.countOfType(
        caches.static.shipyardShips,
        ShipType.LIGHT_SHUTTLE,
      ),
    ).thenReturn(0);
    when(() => caches.agent.headquarters(caches.systems)).thenReturn(
      SystemWaypoint.test(hqSymbol),
    );
    when(() => caches.agent.agent).thenReturn(
      Agent(
        symbol: shipSymbol.agentName,
        headquarters: hqSymbol,
        credits: 100000,
        shipCount: 1,
        startingFaction: faction,
      ),
    );

    when(caches.construction.allRecords).thenAnswer((_) async => []);
    when(() => caches.marketListings.systemsWithAtLeastNMarkets(5))
        .thenReturn({});

    final logger = _MockLogger();
    await runWithLogger(
      logger,
      () async => await centralCommand.advanceCentralPlanning(api, caches),
    );
    expect(centralCommand.nextShipBuyJob, isNull);
  });

  test('CentralCommand.shortenMaxPriceAgeForSystem', () {
    final shipCache = _MockShipCache();
    final behaviorCache = _MockBehaviorCache();
    final centralCommand =
        CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);
    final systemSymbol = SystemSymbol.fromString('S-A');
    final maxAge = centralCommand.maxPriceAgeForSystem(systemSymbol);
    final newMaxAge = centralCommand.shortenMaxPriceAgeForSystem(systemSymbol);
    final newMaxAge2 = centralCommand.maxPriceAgeForSystem(systemSymbol);
    expect(newMaxAge, lessThan(maxAge));
    expect(newMaxAge2, newMaxAge);
    final otherSystem = SystemSymbol.fromString('S-B');
    final otherMaxAge = centralCommand.maxPriceAgeForSystem(otherSystem);
    expect(otherMaxAge, maxAge);
  });

  test('sellOppsForContracts', () {
    final now = DateTime(2021);
    final contractSnapshot = _MockContractSnapshot();
    final contract = Contract(
      id: '2',
      factionSymbol: 'faction',
      type: ContractTypeEnum.PROCUREMENT,
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

    final agentCache = _MockAgentCache();
    final agent = Agent.test(credits: 100000);
    when(() => agentCache.agent).thenReturn(agent);

    int remainingUnitsNeededForContract(
      Contract contract,
      TradeSymbol tradeSymbol,
    ) {
      return 1;
    }

    final sellOpps = sellOppsForContracts(
      agentCache,
      contractSnapshot,
      remainingUnitsNeededForContract: remainingUnitsNeededForContract,
    );
    expect(sellOpps.toList().length, 1);

    final shipCache = _MockShipCache();
    final behaviorCache = _MockBehaviorCache();
    when(() => behaviorCache.states).thenReturn([]);
    final centralCommand =
        CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);
    expect(
      centralCommand
          .contractSellOpps(agentCache, contractSnapshot)
          .toList()
          .length,
      1,
    );
  });

  test('mountsNeededForAllShips', () {
    final shipCache = _MockShipCache();
    when(() => shipCache.ships).thenReturn([]);
    final behaviorCache = _MockBehaviorCache();
    final centralCommand =
        CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);
    expect(centralCommand.mountsNeededForAllShips(), isEmpty);
  });

  test('getJobForShip out of fuel', () {
    final shipCache = _MockShipCache();
    final behaviorCache = _MockBehaviorCache();
    final centralCommand =
        CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);
    final shipSymbol = ShipSymbol.fromString('X-A');
    final ship = _MockShip();
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.fuel).thenReturn(ShipFuel(current: 0, capacity: 1000));
    final job = centralCommand.getJobForShip(ship, 1000000);
    // Can't do anything when out of fuel.
    expect(job.behavior, Behavior.idle);
  });

  test('getJobForShip no behaviors', () {
    final shipCache = _MockShipCache();
    final behaviorCache = _MockBehaviorCache();
    final centralCommand =
        CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);
    final shipSymbol = ShipSymbol.fromString('X-A');
    final ship = _MockShip();
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    final shipFrame = _MockShipFrame();
    when(() => shipFrame.symbol)
        .thenReturn(ShipFrameSymbolEnum.LIGHT_FREIGHTER);
    when(() => ship.frame).thenReturn(shipFrame);
    when(() => ship.registration).thenReturn(
      ShipRegistration(
        name: shipSymbol.symbol,
        factionSymbol: 'F',
        role: ShipRole.COMMAND,
      ),
    );
    when(() => ship.fuel).thenReturn(ShipFuel(current: 1000, capacity: 1000));
    registerFallbackValue(Behavior.idle);
    when(() => behaviorCache.isBehaviorDisabledForShip(ship, any()))
        .thenReturn(true);
    final job = centralCommand.getJobForShip(ship, 1000000);
    // Nothing specified for this ship, so it should be idle.
    expect(job.behavior, Behavior.idle);
  });

  test('shipToBuyFromPlan', () {
    final shipyardShips = _MockShipyardShipCache();
    final shipyardPrices = _MockShipyardPrices();
    final shipCache = _MockShipCache();
    when(() => shipyardPrices.havePriceFor(any())).thenReturn(true);

    final buySecond = [ShipType.COMMAND_FRIGATE, ShipType.EXPLORER];
    when(() => shipCache.countOfType(shipyardShips, ShipType.COMMAND_FRIGATE))
        .thenReturn(1);
    when(() => shipCache.countOfType(shipyardShips, ShipType.EXPLORER))
        .thenReturn(0);
    expect(
      shipToBuyFromPlan(
        shipCache,
        buySecond,
        shipyardPrices,
        shipyardShips,
      ),
      ShipType.EXPLORER,
    );

    final buyFirst = [ShipType.EXPLORER, ShipType.COMMAND_FRIGATE];
    when(() => shipCache.countOfType(shipyardShips, ShipType.COMMAND_FRIGATE))
        .thenReturn(1);
    when(() => shipCache.countOfType(shipyardShips, ShipType.EXPLORER))
        .thenReturn(0);
    expect(
      shipToBuyFromPlan(
        shipCache,
        buyFirst,
        shipyardPrices,
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
    when(() => shipCache.countOfType(shipyardShips, ShipType.COMMAND_FRIGATE))
        .thenReturn(1);
    when(() => shipCache.countOfType(shipyardShips, ShipType.EXPLORER))
        .thenReturn(2);
    when(() => shipCache.countOfType(shipyardShips, ShipType.ORE_HOUND))
        .thenReturn(0);
    expect(
      shipToBuyFromPlan(
        shipCache,
        buyFourth,
        shipyardPrices,
        shipyardShips,
      ),
      ShipType.ORE_HOUND,
    );
  });
}
