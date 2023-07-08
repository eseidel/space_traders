import 'package:cli/api.dart';
import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/agent_cache.dart';
import 'package:cli/cache/behavior_cache.dart';
import 'package:cli/cache/contract_cache.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/logger.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockBehhaviorCache extends Mock implements BehaviorCache {}

class _MockShipCache extends Mock implements ShipCache {}

class _MockShip extends Mock implements Ship {}

class _MockLogger extends Mock implements Logger {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockAgent extends Mock implements Agent {}

void main() {
  test('CentralCommand.isDisabledForAll', () async {
    final behaviorCache = _MockBehhaviorCache();
    final shipCache = _MockShipCache();
    final centralCommand =
        CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);
    expect(centralCommand.isBehaviorDisabled(Behavior.trader), false);

    when(() => behaviorCache.deleteBehavior('S'))
        .thenAnswer((_) => Future.value());

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
    final behaviorCache = await BehaviorCache.load(fs);
    final shipCache = _MockShipCache();
    final centralCommand =
        CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);
    final ship = _MockShip();
    when(() => ship.symbol).thenReturn('S');
    expect(
      centralCommand.isBehaviorDisabledForShip(ship, Behavior.trader),
      false,
    );

    await behaviorCache.setBehavior('S', BehaviorState('S', Behavior.trader));

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
    final logger = _MockLogger();
    // Ship types we've never heard of, just return idle.
    final behavior =
        runWithLogger(logger, () => centralCommand.behaviorFor(ship));
    expect(behavior, Behavior.idle);
  });

  test('CentralCommand.otherExplorerSystems', () async {
    final fs = MemoryFileSystem.test();
    final behaviorCache = await BehaviorCache.load(fs);
    final shipCache = _MockShipCache();
    final centralCommand =
        CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);
    final shipA = _MockShip();
    final shipNavA = _MockShipNav();
    when(() => shipA.symbol).thenReturn('A');
    when(() => shipNavA.systemSymbol).thenReturn('S-A');
    when(() => shipA.nav).thenReturn(shipNavA);
    await centralCommand.setBehavior(
      'A',
      BehaviorState('A', Behavior.explorer),
    );
    await centralCommand.setDestination(shipA, 'S-A-W');
    final shipB = _MockShip();
    when(() => shipB.symbol).thenReturn('B');
    final shipNavB = _MockShipNav();
    when(() => shipNavB.systemSymbol).thenReturn('S-C');
    when(() => shipB.nav).thenReturn(shipNavB);
    await centralCommand.setBehavior(
      'B',
      BehaviorState('B', Behavior.explorer),
    );
    await centralCommand.setDestination(shipB, 'S-B-W');
    expect(centralCommand.currentDestination(shipB), 'S-B-W');
    when(() => shipCache.ship('B')).thenReturn(shipB);

    final otherSystems = centralCommand.otherExplorerSystems('A');
    expect(otherSystems, ['S-B']); // From destination
    await centralCommand.reachedDestination(shipB);
    expect(centralCommand.currentDestination(shipB), isNull);
    final otherSystems2 = centralCommand.otherExplorerSystems('A');
    expect(otherSystems2, ['S-C']); // From nav.systemSymbol
    await centralCommand.completeBehavior('B');
    final otherSystems3 = centralCommand.otherExplorerSystems('A');
    expect(otherSystems3, <String>[]);
  });

  test('CentralCommand.affordableContracts', () {
    final ship = _MockShip();
    final agent = _MockAgent();
    // TODO(eseidel): Contracts are disabled under 100000 credits.
    when(() => agent.credits).thenReturn(100000);
    final agentCache = AgentCache(agent);
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
    final contractCache = ContractCache(contracts);
    final active = contractCache.activeContracts;
    expect(active.length, 2);
    final affordable = affordableContracts(agentCache, contractCache).toList();
    expect(affordable.length, 1);
    expect(affordable.first.id, '2');
  });
}
