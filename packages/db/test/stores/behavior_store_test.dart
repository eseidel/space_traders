import 'package:db/db.dart';
import 'package:db/src/queries/behavior.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../docker.dart';

void main() {
  test('Behavior round trip', () {
    // Behavior state fields are all covered by BehaviorState round trip tests
    // at the types level.
    final behavior = BehaviorState(const ShipSymbol('S', 1), Behavior.idle);
    final map = behaviorStateToColumnMap(behavior);
    final newBehavior = behaviorStateFromColumnMap(map);
    expect(newBehavior.behavior, equals(behavior.behavior));
  });

  withPostgresServer('behavior', (server) {
    test('smoke test', () async {
      final endpoint = await server.endpoint();
      final db = Database.testLive(
        endpoint: endpoint,
        connection: await server.newConnection(),
      );
      await db.migrateToLatestSchema();

      final idleSymbol = ShipSymbol.fromString('S-1');
      final idle = BehaviorState(idleSymbol, Behavior.idle);
      await db.behaviors.upsert(idle);
      final idleResult = await db.behaviors.get(idleSymbol);
      expect(idleResult!.behavior, equals(idle.behavior));

      final traderSymbol = ShipSymbol.fromString('S-2');
      final trader = BehaviorState(traderSymbol, Behavior.trader);
      await db.behaviors.upsert(trader);
      final traderResult = await db.behaviors.get(traderSymbol);
      expect(traderResult!.behavior, equals(trader.behavior));

      final behaviors = await db.behaviors.ofType(Behavior.idle);
      expect(behaviors.length, equals(1));
      expect(behaviors.first.behavior, equals(idle.behavior));

      final allBehaviors = await db.behaviors.all();
      expect(allBehaviors.length, equals(2));
      // Order is not guaranteed.
      expect(
        allBehaviors.map((b) => b.behavior).toSet(),
        equals({idle.behavior, trader.behavior}),
      );

      await db.behaviors.delete(idleSymbol);
      expect(await db.behaviors.get(idleSymbol), isNull);
    });
  });
}
