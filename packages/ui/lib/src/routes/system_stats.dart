import 'package:client/client.dart';
import 'package:flutter/material.dart';
import 'package:protocol/protocol.dart';
import 'package:types/types.dart';
import 'package:ui/src/api_builder.dart';

class SystemStatsScreen extends StatelessWidget {
  const SystemStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Stats')),
      body: ApiBuilder<SystemStats>(
        fetcher: (c) => c.getSystemStats(),
        builder: (context, data) => SystemStatsView(data),
      ),
    );
  }
}

Widget _row(String label, Object value, {bool isBold = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label),
      Text(
        value.toString(),
        style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null,
      ),
    ],
  );
}

class SystemStatsView extends StatelessWidget {
  const SystemStatsView(this.stats, {super.key});

  final SystemStats stats;

  // Starting from ${s.startSystem}, known reachable:
  // ${s.reachableSystems} systems (${p(s.reachableSystemPercent)} of ${s.totalSystems})
  // ${s.reachableWaypoints} waypoints (${p(s.reachableWaypointPercent)} of ${s.totalWaypoints})
  //  ${s.chartedWaypoints} charted non-asteroid (${p(s.nonAsteroidChartPercent)})
  //  ${s.chartedAsteroids} charted asteroid (${p(s.asteroidChartPercent)})
  // ${s.reachableMarkets} markets
  // ${s.reachableShipyards} shipyards
  // ${s.reachableJumpGates} jump gates (${p(s.reachableJumpGatePercent)} of ${s.totalJumpgates})
  //  ${s.cachedJumpGates} cached
  //  ${s.chartedJumpGates} charted

  @override
  Widget build(BuildContext context) {
    final s = stats;
    String of(int a, int b, {required String label}) {
      return '$a (${(a / b * 100).toStringAsFixed(1)}% of $b $label)';
    }

    String ofT(int a, int b) => of(a, b, label: 'total');
    String ofR(int a, int b) => of(a, b, label: 'reachable');

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _row('Starting System', s.startSystem),
          const Divider(),
          const Text('Reachable'),
          _row('Systems', ofT(s.reachableSystems, s.totalSystems)),
          _row('Waypoints', ofT(s.reachableWaypoints, s.totalWaypoints)),
          _row('Jumpgates', ofT(s.reachableJumpGates, s.totalJumpgates)),
          _row('Markets', s.reachableMarkets),
          _row('Shipyards', s.reachableShipyards),
          const Divider(),
          const Text('Charted'),
          _row('Waypoints', ofR(s.chartedWaypoints, s.reachableWaypoints)),
          _row('Jumpgates', ofR(s.chartedJumpGates, s.reachableJumpGates)),
          _row(
            'Non-Asteroid',
            ofR(
              s.chartedWaypoints - s.chartedAsteroids,
              s.reachableWaypoints - s.reachableAsteroids,
            ),
          ),
          _row('Asteroids', ofR(s.chartedAsteroids, s.reachableAsteroids)),
          _row('Cached Jumpgates', s.cachedJumpGates),
        ],
      ),
    );
  }
}
