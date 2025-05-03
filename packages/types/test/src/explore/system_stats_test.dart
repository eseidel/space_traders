import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  group('SystemStats', () {
    test('round-trips through JSON', () {
      final stats = SystemStats(
        startSystem: SystemSymbol.fromString('X1-DF55'),
        totalSystems: 100,
        totalWaypoints: 500,
        totalJumpgates: 50,
        reachableSystems: 80,
        reachableWaypoints: 400,
        reachableMarkets: 30,
        reachableShipyards: 20,
        reachableAsteroids: 200,
        reachableJumpGates: 40,
        chartedWaypoints: 300,
        chartedAsteroids: 150,
        chartedJumpGates: 30,
        cachedJumpGates: 25,
      );

      // Convert to JSON
      final json = stats.toJson();

      // Convert back from JSON
      final reconstructedStats = SystemStats.fromJson(json);

      // Verify the reconstructed object matches the original
      expect(reconstructedStats.startSystem, equals(stats.startSystem));
      expect(reconstructedStats.totalSystems, equals(stats.totalSystems));
      expect(reconstructedStats.totalWaypoints, equals(stats.totalWaypoints));
      expect(reconstructedStats.totalJumpgates, equals(stats.totalJumpgates));
      expect(
        reconstructedStats.reachableSystems,
        equals(stats.reachableSystems),
      );
      expect(
        reconstructedStats.reachableWaypoints,
        equals(stats.reachableWaypoints),
      );
      expect(
        reconstructedStats.reachableMarkets,
        equals(stats.reachableMarkets),
      );
      expect(
        reconstructedStats.reachableShipyards,
        equals(stats.reachableShipyards),
      );
      expect(
        reconstructedStats.reachableAsteroids,
        equals(stats.reachableAsteroids),
      );
      expect(
        reconstructedStats.reachableJumpGates,
        equals(stats.reachableJumpGates),
      );
      expect(
        reconstructedStats.chartedWaypoints,
        equals(stats.chartedWaypoints),
      );
      expect(
        reconstructedStats.chartedAsteroids,
        equals(stats.chartedAsteroids),
      );
      expect(
        reconstructedStats.chartedJumpGates,
        equals(stats.chartedJumpGates),
      );
      expect(reconstructedStats.cachedJumpGates, equals(stats.cachedJumpGates));
    });

    test('computed properties work correctly', () {
      final stats = SystemStats(
        startSystem: SystemSymbol.fromString('X1-DF55'),
        totalSystems: 100,
        totalWaypoints: 500,
        totalJumpgates: 50,
        reachableSystems: 80,
        reachableWaypoints: 400,
        reachableMarkets: 30,
        reachableShipyards: 20,
        reachableAsteroids: 200,
        reachableJumpGates: 40,
        chartedWaypoints: 300,
        chartedAsteroids: 150,
        chartedJumpGates: 30,
        cachedJumpGates: 25,
      );

      // Test computed properties
      expect(stats.asteroidChartPercent, equals(150 / 200)); // 75%
      expect(stats.nonAsteroidChartPercent, equals(150 / 200)); // 75%
      expect(stats.reachableSystemPercent, equals(80 / 100)); // 80%
      expect(stats.reachableWaypointPercent, equals(400 / 500)); // 80%
      expect(stats.reachableJumpGatePercent, equals(40 / 50)); // 80%
    });
  });
}
