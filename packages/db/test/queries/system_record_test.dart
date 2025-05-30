import 'package:db/db.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../docker.dart';

void main() {
  withPostgresServer('system', (server) {
    test('get and set', () async {
      final endpoint = await server.endpoint();
      final db = Database.testLive(
        endpoint: endpoint,
        connection: await server.newConnection(),
      );
      await db.migrateToLatestSchema();

      final systems = [
        System.test(
          SystemSymbol.fromString('W-A'),
          type: SystemType.RED_STAR,
          waypoints: [
            SystemWaypoint.test(
              WaypointSymbol.fromString('W-A-1'),
              type: WaypointType.PLANET,
            ),
            SystemWaypoint.test(
              WaypointSymbol.fromString('W-A-2'),
              type: WaypointType.JUMP_GATE,
            ),
          ],
          position: const SystemPosition(1, 1),
        ),
        System.test(
          SystemSymbol.fromString('W-B'),
          type: SystemType.ORANGE_STAR,
          waypoints: [SystemWaypoint.test(WaypointSymbol.fromString('W-B-1'))],
          position: const SystemPosition(2, 2),
        ),
      ];
      for (final system in systems) {
        await db.systems.upsertSystem(system);
      }

      // Record lookups work
      expect(
        await db.systems.systemRecordBySymbol(systems[0].symbol),
        equals(systems[0].toSystemRecord()),
      );

      // Waypoint lookups work
      expect(
        await db.systems.systemWaypointBySymbol(systems[0].waypoints[0].symbol),
        equals(systems[0].waypoints[0]),
      );

      expect(await db.systems.countSystemWaypoints(), 3);
      expect(await db.systems.countSystemRecords(), 2);

      expect(
        await db.systems.jumpGateSymbolForSystem(systems[0].symbol),
        systems[0].waypoints[1].symbol,
      );
      expect(await db.systems.jumpGateSymbolForSystem(systems[1].symbol), null);

      expect(
        await db.systems.isJumpGate(systems[0].waypoints[1].symbol),
        isTrue,
      );
      expect(
        await db.systems.isJumpGate(systems[0].waypoints[0].symbol),
        isFalse,
      );

      expect(await db.systems.waypointsInSystem(systems[0].symbol), [
        systems[0].waypoints[0],
        systems[0].waypoints[1],
      ]);

      expect(
        await db.systems.waypointType(systems[0].waypoints[1].symbol),
        WaypointType.JUMP_GATE,
      );
      expect(
        await db.systems.waypoint(systems[0].waypoints[1].symbol),
        systems[0].waypoints[1],
      );

      expect(
        await db.systems.waypointType(systems[0].waypoints[0].symbol),
        WaypointType.PLANET,
      );

      final snapshot = await db.systems.snapshotAllSystems();
      expect(snapshot.systems.length, 2);
      expect(snapshot.systems.map((s) => s.symbol), [
        systems[0].symbol,
        systems[1].symbol,
      ]);
      // Test System.operator==
      expect(snapshot.systems.first == systems[0], isTrue);
      expect(snapshot.systems.first == systems[1], isFalse);
    });
  });
}
