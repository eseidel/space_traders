import 'package:cli/api.dart';
import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/agent_cache.dart';
import 'package:cli/cache/behavior_cache.dart';
import 'package:cli/cache/contract_cache.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/trading.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockAgent extends Mock implements Agent {}

class _MockBehhaviorCache extends Mock implements BehaviorCache {}

class _MockContract extends Mock implements Contract {}

class _MockContractTerms extends Mock implements ContractTerms {}

class _MockCostedDeal extends Mock implements CostedDeal {}

class _MockLogger extends Mock implements Logger {}

class _MockShip extends Mock implements Ship {}

class _MockShipCache extends Mock implements ShipCache {}

class _MockShipFuel extends Mock implements ShipFuel {}

class _MockShipNav extends Mock implements ShipNav {}

void main() {
  test('CentralCommand.isDisabledForAll', () async {
    final behaviorCache = _MockBehhaviorCache();
    final shipCache = _MockShipCache();
    final centralCommand =
        CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);
    expect(centralCommand.isBehaviorDisabled(Behavior.trader), false);

    final ship = _MockShip();
    when(() => ship.symbol).thenReturn('S');
    final logger = _MockLogger();

    await runWithLogger(
      logger,
      () async => centralCommand.disableBehaviorForAll(
        ship,
        Behavior.trader,
        'why',
        const Duration(hours: 1),
      ),
    );
    expect(centralCommand.isBehaviorDisabled(Behavior.trader), true);
  });

  test('CentralCommand.isDisabledForShip', () async {
    final fs = MemoryFileSystem.test();
    final behaviorCache = BehaviorCache.load(fs);
    final shipCache = _MockShipCache();
    final centralCommand =
        CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);
    final ship = _MockShip();
    when(() => ship.symbol).thenReturn('S');
    expect(
      centralCommand.isBehaviorDisabledForShip(ship, Behavior.trader),
      false,
    );

    behaviorCache.setBehavior('S', BehaviorState('S', Behavior.trader));

    final logger = _MockLogger();
    await runWithLogger(
      logger,
      () async => centralCommand.disableBehaviorForShip(
        ship,
        Behavior.trader,
        'why',
        const Duration(hours: 1),
      ),
    );
    final ship2 = _MockShip();
    when(() => ship2.symbol).thenReturn('T');
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
    when(() => ship.registration).thenReturn(
      ShipRegistration(
        name: 'S',
        factionSymbol: 'F',
        role: ShipRole.CARRIER,
      ),
    );
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
    RoutePlan fakeJump(String start, String end) {
      return RoutePlan(
        fuelCapacity: 10,
        shipSpeed: 10,
        actions: [
          RouteAction(
            startSymbol: start,
            endSymbol: end,
            type: RouteActionType.jump,
            duration: 10,
          )
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
    await centralCommand.setBehavior(
      aSymbol.symbol,
      BehaviorState(aSymbol.symbol, Behavior.explorer),
    );
    await centralCommand.setRoutePlan(shipA, fakeJump('S-A-A', 'S-A-W'));
    final shipB = _MockShip();
    when(() => shipB.symbol).thenReturn('X-B');
    final shipNavB = _MockShipNav();
    when(() => shipNavB.systemSymbol).thenReturn('S-C');
    when(() => shipB.nav).thenReturn(shipNavB);
    await centralCommand.setBehavior(
      'X-B',
      BehaviorState('X-B', Behavior.explorer),
    );
    await centralCommand.setRoutePlan(shipB, fakeJump('S-A-A', 'S-B-W'));
    expect(centralCommand.currentRoutePlan(shipB)!.endSymbol, 'S-B-W');
    when(() => shipCache.ship('X-B')).thenReturn(shipB);

    final otherSystems = centralCommand.otherExplorerSystems(aSymbol).toList();
    expect(otherSystems, [SystemSymbol.fromString('S-B')]); // From destination
    await centralCommand.reachedEndOfRoutePlan(shipB);
    expect(centralCommand.currentRoutePlan(shipB), isNull);
    final otherSystems2 = centralCommand.otherExplorerSystems(aSymbol).toList();
    expect(
      otherSystems2,
      [SystemSymbol.fromString('S-C')],
    ); // From nav.systemSymbol
    await centralCommand.completeBehavior('X-B');
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
          )
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
          )
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
    when(() => shipCache.shipSymbols).thenReturn(['A']);
    final costedDeal = _MockCostedDeal();
    when(() => costedDeal.contractId).thenReturn('C');
    when(() => costedDeal.maxUnitsToBuy).thenReturn(10);
    const tradeSymbol = TradeSymbol.FUEL;
    when(() => behaviorCache.getBehavior('A'))
        .thenReturn(BehaviorState('A', Behavior.trader, deal: costedDeal));
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
