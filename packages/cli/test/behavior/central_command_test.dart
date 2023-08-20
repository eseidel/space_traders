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
  test('CentralCommand.isDisabledForShip', () async {
    final fs = MemoryFileSystem.test();
    final behaviorCache = BehaviorCache.load(fs);
    final shipCache = _MockShipCache();
    final centralCommand =
        CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);
    final ship = _MockShip();
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    expect(
      centralCommand.isBehaviorDisabledForShip(ship, Behavior.trader),
      false,
    );

    behaviorCache.setBehavior(
      shipSymbol,
      BehaviorState(shipSymbol, Behavior.trader),
    );

    final logger = _MockLogger();
    await runWithLogger(
      logger,
      () async => centralCommand.disableBehaviorForShip(
        ship,
        'why',
        const Duration(hours: 1),
      ),
    );
    final ship2 = _MockShip();
    when(() => ship2.symbol).thenReturn('S-2');
    expect(
      centralCommand.isBehaviorDisabledForShip(ship, Behavior.trader),
      true,
    );
    expect(
      centralCommand.isBehaviorDisabledForShip(ship2, Behavior.trader),
      false,
    );
  });

  test('CentralCommand.behaviorFor', () async {
    final behaviorCache = _MockBehhaviorCache();
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
    final behavior =
        runWithLogger(logger, () => centralCommand.behaviorFor(ship));
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
    final aSymbol = ShipSymbol.fromString('X-A');
    when(() => shipA.symbol).thenReturn(aSymbol.symbol);
    when(() => shipNavA.systemSymbol).thenReturn('S-A');
    when(() => shipA.nav).thenReturn(shipNavA);
    centralCommand.setBehavior(
      aSymbol,
      BehaviorState(aSymbol, Behavior.explorer),
    );

    final saa = WaypointSymbol.fromString('S-A-A');
    final saw = WaypointSymbol.fromString('S-A-W');
    centralCommand.setRoutePlan(shipA, fakeJump(saa, saw));
    final shipB = _MockShip();
    final shipBSymbol = ShipSymbol.fromString('X-B');
    when(() => shipB.symbol).thenReturn(shipBSymbol.symbol);
    final shipNavB = _MockShipNav();
    when(() => shipNavB.systemSymbol).thenReturn('S-C');
    when(() => shipB.nav).thenReturn(shipNavB);
    centralCommand.setBehavior(
      shipBSymbol,
      BehaviorState(shipBSymbol, Behavior.explorer),
    );
    final sbw = WaypointSymbol.fromString('S-B-W');
    centralCommand.setRoutePlan(shipB, fakeJump(saa, sbw));
    expect(centralCommand.currentRoutePlan(shipB)!.endSymbol, sbw);
    when(() => shipCache.ship(shipBSymbol)).thenReturn(shipB);

    final otherSystems = centralCommand.otherExplorerSystems(aSymbol).toList();
    expect(otherSystems, [sbw.systemSymbol]); // From destination
    centralCommand.reachedEndOfRoutePlan(shipB);
    expect(centralCommand.currentRoutePlan(shipB), isNull);
    final otherSystems2 = centralCommand.otherExplorerSystems(aSymbol).toList();
    expect(
      otherSystems2,
      [SystemSymbol.fromString('S-C')],
    ); // From nav.systemSymbol
    centralCommand.completeBehavior(shipBSymbol);
    final otherSystems3 = centralCommand.otherExplorerSystems(aSymbol).toList();
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
}
