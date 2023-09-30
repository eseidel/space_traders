import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/agent_cache.dart';
import 'package:cli/cache/behavior_cache.dart';
import 'package:cli/cache/contract_cache.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/logger.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockAgent extends Mock implements Agent {}

class _MockBehhaviorCache extends Mock implements BehaviorCache {}

class _MockContract extends Mock implements Contract {}

class _MockContractTerms extends Mock implements ContractTerms {}

class _MockCostedDeal extends Mock implements CostedDeal {}

class _MockDeal extends Mock implements Deal {}

class _MockLogger extends Mock implements Logger {}

class _MockShip extends Mock implements Ship {}

class _MockShipCache extends Mock implements ShipCache {}

class _MockShipFuel extends Mock implements ShipFuel {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipFrame extends Mock implements ShipFrame {}

void main() {
  test('CentralCommand.chooseNewBehaviorFor', () async {
    final behaviorCache = _MockBehhaviorCache();
    when(() => behaviorCache.states).thenReturn([]);
    final shipCache = _MockShipCache();
    final centralCommand =
        CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);
    final ship = _MockShip();
    when(() => ship.mounts).thenReturn([]);
    when(() => shipCache.ships).thenReturn([ship]);
    when(() => ship.registration).thenReturn(
      ShipRegistration(
        name: 'S',
        factionSymbol: 'F',
        role: ShipRole.CARRIER,
      ),
    );
    final shipFrame = _MockShipFrame();
    when(() => ship.frame).thenReturn(shipFrame);
    when(() => shipFrame.symbol)
        .thenReturn(ShipFrameSymbolEnum.LIGHT_FREIGHTER);
    final shipFuel = _MockShipFuel();
    when(() => shipFuel.capacity).thenReturn(100);
    when(() => shipFuel.current).thenReturn(100);
    when(() => ship.fuel).thenReturn(shipFuel);
    final logger = _MockLogger();
    // Ship types we've never heard of, just return idle.
    final behavior = runWithLogger(
      logger,
      () => centralCommand.chooseNewBehaviorFor(ship, 100),
    );
    expect(behavior, Behavior.idle);
  });

  test('CentralCommand.otherExplorerSystems', () async {
    RoutePlan fakeJump(WaypointSymbol start, WaypointSymbol end) {
      return RoutePlan(
        fuelCapacity: 10,
        shipSpeed: 10,
        actions: [
          RouteAction(
            startSymbol: start,
            endSymbol: end,
            type: RouteActionType.jump,
            duration: 10,
          ),
        ],
        fuelUsed: 10,
      );
    }

    final fs = MemoryFileSystem.test();
    final behaviorCache = BehaviorCache.load(fs);
    final shipCache = _MockShipCache();
    final centralCommand =
        CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);
    final shipA = _MockShip();
    final shipNavA = _MockShipNav();
    final shipASymbol = ShipSymbol.fromString('X-A');
    when(() => shipA.symbol).thenReturn(shipASymbol.symbol);
    when(() => shipNavA.systemSymbol).thenReturn('S-A');
    when(() => shipA.nav).thenReturn(shipNavA);
    final stateA = BehaviorState(shipASymbol, Behavior.explorer);

    final saa = WaypointSymbol.fromString('S-A-A');
    final saw = WaypointSymbol.fromString('S-A-W');
    stateA.routePlan = fakeJump(saa, saw);
    behaviorCache.setBehavior(shipASymbol, stateA);
    final shipB = _MockShip();
    final shipBSymbol = ShipSymbol.fromString('X-B');
    when(() => shipB.symbol).thenReturn(shipBSymbol.symbol);
    final shipNavB = _MockShipNav();
    when(() => shipNavB.systemSymbol).thenReturn('S-C');
    when(() => shipB.nav).thenReturn(shipNavB);
    final stateB = BehaviorState(shipBSymbol, Behavior.explorer);
    final sbw = WaypointSymbol.fromString('S-B-W');
    stateB.routePlan = fakeJump(saa, sbw);
    behaviorCache.setBehavior(shipBSymbol, stateB);
    when(() => shipCache.ship(shipBSymbol)).thenReturn(shipB);

    final otherSystems =
        centralCommand.otherExplorerSystems(shipASymbol).toList();
    expect(otherSystems, [sbw.systemSymbol]); // From destination
    stateB.routePlan = null;
    final otherSystems2 =
        centralCommand.otherExplorerSystems(shipASymbol).toList();
    expect(
      otherSystems2,
      [SystemSymbol.fromString('S-C')],
    ); // From nav.systemSymbol
    behaviorCache.deleteBehavior(shipBSymbol);
    final otherSystems3 =
        centralCommand.otherExplorerSystems(shipASymbol).toList();
    expect(otherSystems3, <SystemSymbol>[]);
  });

  test('CentralCommand.affordableContracts', () {
    final ship = _MockShip();
    final agent = _MockAgent();
    // TODO(eseidel): Contracts are disabled under 100000 credits.
    when(() => agent.credits).thenReturn(100000);
    final fs = MemoryFileSystem.test();
    final agentCache = AgentCache(agent, fs: fs);
    when(() => ship.symbol).thenReturn('S');
    final hourFromNow = DateTime.timestamp().add(const Duration(hours: 1));
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
      expiration: hourFromNow,
      deadlineToAccept: hourFromNow,
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
      expiration: hourFromNow,
      deadlineToAccept: hourFromNow,
    );
    final contracts = [contract1, contract2];
    final contractCache = ContractCache(contracts, fs: fs);
    final active = contractCache.activeContracts;
    expect(active.length, 2);
    final affordable = affordableContracts(agentCache, contractCache).toList();
    expect(affordable.length, 1);
    expect(affordable.first.id, '2');
  });

  test('CentralCommand.remainingUnitsNeededForContract', () {
    final behaviorCache = _MockBehhaviorCache();
    final shipCache = _MockShipCache();
    final shipASymbol = ShipSymbol.fromString('X-A');
    when(() => shipCache.shipSymbols).thenReturn([shipASymbol]);
    final costedDeal = _MockCostedDeal();
    final deal = _MockDeal();
    when(() => costedDeal.deal).thenReturn(deal);
    when(() => costedDeal.cargoSize).thenReturn(120);
    when(() => deal.maxUnits).thenReturn(10);
    when(() => costedDeal.contractId).thenReturn('C');
    const tradeSymbol = TradeSymbol.FUEL;
    when(() => behaviorCache.getBehavior(shipASymbol)).thenReturn(
      BehaviorState(shipASymbol, Behavior.trader, deal: costedDeal),
    );
    final centralCommand =
        CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);
    final contract = _MockContract();
    final contractTerms = _MockContractTerms();
    when(() => contract.terms).thenReturn(contractTerms);
    when(() => contract.id).thenReturn('C');
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

  test('idleHaulerSymbols', () {
    final shipCache = _MockShipCache();
    when(() => shipCache.ships).thenReturn([]);
    final behaviorCache = _MockBehhaviorCache();
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
      // "explorer" and "idle" are both the "idle" states for a hauler.
      [BehaviorState(shipSymbol, Behavior.explorer)],
    );
    final symbols2 = idleHaulerSymbols(shipCache, behaviorCache);
    expect(symbols2, [shipSymbol]);
  });

  test('dealsInProgress smoke test', () {
    final deal = _MockCostedDeal();
    final cache = BehaviorCache(
      {
        ShipSymbol.fromString('X-A'):
            BehaviorState(ShipSymbol.fromString('X-A'), Behavior.explorer),
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
    final behaviorCache = _MockBehhaviorCache();
    when(() => behaviorCache.states).thenReturn([]);
    final centralCommand =
        CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);
    final ship = _MockShip();
    final shipSymbol = ShipSymbol.fromString('X-A');
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    final shipNav = _MockShipNav();
    when(() => shipNav.systemSymbol).thenReturn('W-A');
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipCache.ships).thenReturn([ship]);
    centralCommand.nextShipBuyJob = ShipBuyJob(
      shipyardSymbol: WaypointSymbol.fromString('W-A-Y'),
      shipType: ShipType.HEAVY_FREIGHTER,
      minCreditsNeeded: 100,
    );
    final shouldBuy = centralCommand.shouldBuyShip(ship, 100000);
    expect(shouldBuy, true);

    // But stops if someone else is already buying.
    when(() => behaviorCache.states).thenReturn([
      BehaviorState(const ShipSymbol('A', 1), Behavior.buyShip),
    ]);
    expect(centralCommand.shouldBuyShip(ship, 100000), false);
  });

  test('CentralCommand.templateForShip', () {
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
    final behaviorCache = _MockBehhaviorCache();
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
  });
}
