import 'dart:convert';

import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:collection/collection.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) async {
  await runOffline(args, command);
}

Future<void> command(FileSystem fs, ArgResults argResults) async {
  const testsDir = '../../../space_traders_tests';
  // Load up the pathing tests directory.
  final pathingTestsDir = fs.directory('$testsDir/pathing');
  if (!pathingTestsDir.existsSync()) {
    logger.err('Pathing tests directory not found at ${pathingTestsDir.path}');
    return;
  }
  final tests = pathingTestsDir.listSync();
  if (tests.isEmpty) {
    logger.err('No pathing tests found in ${pathingTestsDir.path}');
    return;
  }
  for (final testFile in tests) {
    if (testFile is! File) {
      continue;
    }
    final suite = TestSuite.fromJson(
      jsonDecode(testFile.readAsStringSync()) as Map<String, dynamic>,
    );
    final relative = path.relative(testFile.path, from: testsDir);
    runTests(suite, relative);
  }
}

class TestShip {
  TestShip({
    required this.speed,
    required this.fuelCapacity,
    required this.initialFuel,
  });

  factory TestShip.fromJson(Map<String, dynamic> json) {
    return TestShip(
      speed: json['speed'] as int,
      fuelCapacity: json['fuelCapacity'] as int,
      initialFuel: json['fuel'] as int,
    );
  }

  final int speed;
  final int fuelCapacity;
  final int initialFuel;
}

class TestWaypoint {
  TestWaypoint({
    required this.symbol,
    required this.x,
    required this.y,
  });

  factory TestWaypoint.fromJson(Map<String, dynamic> json) {
    return TestWaypoint(
      symbol: json['symbol'] as String,
      x: json['x'] as int,
      y: json['y'] as int,
    );
  }

  final String symbol;
  final int x;
  final int y;
}

class TestSystem {
  TestSystem({
    required this.symbol,
    required this.waypoints,
  });

  factory TestSystem.fromJson(Map<String, dynamic> json) {
    return TestSystem(
      symbol: json['symbol'] as String,
      waypoints: (json['waypoints'] as List<dynamic>)
          .map((e) => TestWaypoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String symbol;
  final List<TestWaypoint> waypoints;
}

class TestExpect {
  TestExpect({
    required this.route,
    required this.fuelUsed,
    required this.time,
  });

  factory TestExpect.fromJson(Map<String, dynamic> json) {
    return TestExpect(
      route: (json['route'] as List<dynamic>).cast<String>(),
      fuelUsed: json['fuelUsed'] as int,
      time: json['time'] as int,
    );
  }

  final List<String> route;
  final int fuelUsed;
  final int time;
}

class Test {
  Test({
    required this.start,
    required this.end,
    required this.expect,
  });

  factory Test.fromJson(Map<String, dynamic> json) {
    return Test(
      start: json['start'] as String,
      end: json['end'] as String,
      expect: TestExpect.fromJson(json['expect'] as Map<String, dynamic>),
    );
  }

  final String start;
  final String end;
  final TestExpect expect;
}

class TestSuite {
  TestSuite({
    required this.ship,
    required this.systems,
    required this.tests,
  });

  factory TestSuite.fromJson(Map<String, dynamic> json) {
    return TestSuite(
      ship: TestShip.fromJson(json['ship'] as Map<String, dynamic>),
      systems: (json['systems'] as List<dynamic>)
          .map((e) => TestSystem.fromJson(e as Map<String, dynamic>))
          .toList(),
      tests: (json['tests'] as List<dynamic>)
          .map((e) => Test.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final TestShip ship;
  final List<TestSystem> systems;
  final List<Test> tests;
}

void runTests(TestSuite suite, String path) {
  // Create a systems cache for the test.
  // Create a route planner.
  // Run the tests.
  final fs = MemoryFileSystem.test();
  final systems = <System>[];
  const sector = 'X1';
  for (final system in suite.systems) {
    final systemSymbol = SystemSymbol.fromString('$sector-${system.symbol}');
    final waypoints = <SystemWaypoint>[];
    for (final waypoint in system.waypoints) {
      final waypointSymbol = WaypointSymbol.fromString(
        '${systemSymbol.system}-${waypoint.symbol}',
      );
      waypoints.add(
        SystemWaypoint(
          symbol: waypointSymbol.waypoint,
          type: WaypointType.ASTEROID,
          x: waypoint.x,
          y: waypoint.y,
        ),
      );
    }
    systems.add(
      System(
        symbol: systemSymbol.system,
        sectorSymbol: systemSymbol.sector,
        waypoints: waypoints,
        type: SystemType.NEBULA,
        x: 0,
        y: 0,
      ),
    );
  }

  final systemsCache = SystemsCache(systems, fs: fs);
  final routePlanner =
      RoutePlanner.fromSystemsCache(systemsCache, sellsFuel: (_) => false);

  final ship = suite.ship;

  for (var i = 0; i < suite.tests.length; i++) {
    final test = suite.tests[i];
    final start = WaypointSymbol.fromString('$sector-${test.start}');
    final end = WaypointSymbol.fromString('$sector-${test.end}');
    final plan = routePlanner.planRoute(
      start: start,
      end: end,
      fuelCapacity: ship.fuelCapacity,
      shipSpeed: ship.speed,
    );
    if (plan == null) {
      logger.err('No route found for $start to $end');
      continue;
    }
    var route = <String>[];
    for (final action in plan.actions) {
      if (route.isEmpty) {
        route.add(action.startSymbol.waypoint);
      }
      route.add(action.endSymbol.waypoint);
    }
    // Remove the sector.
    route = route.map((e) => e.substring(e.indexOf('-') + 1)).toList();
    var failure = false;
    if (!const ListEquality<String>().equals(route, test.expect.route)) {
      logger
        ..err('Route mismatch for ${test.start} to ${test.end}')
        ..err('Expected: ${test.expect.route}')
        ..err('Actual: $route');
      failure = true;
    }
    if (plan.fuelUsed != test.expect.fuelUsed) {
      logger
        ..err('Fuel used mismatch for ${test.start} to ${test.end}')
        ..err('Expected: ${test.expect.fuelUsed}')
        ..err('Actual: ${plan.fuelUsed}');
      failure = true;
    }
    if (plan.duration.inSeconds != test.expect.time) {
      logger
        ..err('Time mismatch for ${test.start} to ${test.end}')
        ..err('Expected: ${test.expect.time}')
        ..err('Actual: ${plan.duration.inSeconds}');
      failure = true;
    }
    if (failure) {
      logger.err('$path.$i: Failed');
    } else {
      logger.info('$path.$i: Passed');
    }
  }
}
