import 'dart:convert';

import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/compare.dart';
import 'package:equatable/equatable.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) async {
  await runOffline(args, command);
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
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
    if (!testFile.path.endsWith('.json')) {
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

  ShipSpec get shipSpec => ShipSpec(
        speed: speed,
        fuelCapacity: fuelCapacity,
        cargoCapacity: 0,
      );

  final int speed;
  final int fuelCapacity;
  final int initialFuel;
}

class TestWaypoint {
  TestWaypoint({
    required this.symbol,
    required this.x,
    required this.y,
    required this.sellsFuel,
  });

  factory TestWaypoint.fromJson(Map<String, dynamic> json) {
    return TestWaypoint(
      symbol: json['symbol'] as String,
      x: json['x'] as int,
      y: json['y'] as int,
      sellsFuel: json['sellsFuel'] as bool? ?? false,
    );
  }

  final String symbol;
  final int x;
  final int y;
  final bool sellsFuel;
}

class TestRouteAction extends Equatable {
  const TestRouteAction({
    required this.start,
    required this.end,
    required this.action,
  });

  factory TestRouteAction.fromJson(Map<String, dynamic> json) {
    return TestRouteAction(
      start: json['start'] as String,
      end: json['end'] as String,
      action: json['action'] as String,
    );
  }

  final String start;
  final String end;
  final String action;

  @override
  List<Object> get props => [start, end, action];

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'start': start,
      'end': end,
      'action': action,
    };
  }

  @override
  String toString() => jsonEncode(this);
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
      route: (json['route'] as List<dynamic>)
          .map((e) => TestRouteAction.fromJson(e as Map<String, dynamic>))
          .toList(),
      fuelUsed: json['fuelUsed'] as int,
      time: json['time'] as int,
    );
  }

  final List<TestRouteAction> route;
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

String toActionString(RouteActionType type) {
  switch (type) {
    case RouteActionType.jump:
      return 'JUMP';
    case RouteActionType.refuel:
      return 'REFUEL';
    case RouteActionType.navCruise:
      return 'NAV-CRUISE';
    case RouteActionType.navDrift:
      return 'NAV-DRIFT';
    case RouteActionType.emptyRoute:
      throw UnimplementedError();
  }
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
          symbol: waypointSymbol,
          type: WaypointType.ASTEROID,
          position: WaypointPosition(waypoint.x, waypoint.y, systemSymbol),
        ),
      );
    }
    systems.add(
      System(
        symbol: systemSymbol,
        waypoints: waypoints,
        type: SystemType.NEBULA,
        position: const SystemPosition(0, 0),
      ),
    );
  }

  TestWaypoint lookupWaypoint(WaypointSymbol waypointSymbol) {
    final parts = waypointSymbol.waypoint.split('-');
    final systemName = parts[1];
    final waypointName = parts[2];

    for (final system in suite.systems) {
      if (system.symbol != systemName) {
        continue;
      }
      for (final waypoint in system.waypoints) {
        if (waypointName == waypoint.symbol) {
          return waypoint;
        }
      }
    }
    throw ArgumentError('Waypoint not found: $waypointSymbol');
  }

  final systemsCache = SystemsCache(systems, fs: fs);
  final systemConnectivity = SystemConnectivity.test({});
  final routePlanner = RoutePlanner.fromSystemsCache(
    systemsCache,
    systemConnectivity,
    sellsFuel: (WaypointSymbol w) => lookupWaypoint(w).sellsFuel,
  );

  final ship = suite.ship;

  for (var i = 0; i < suite.tests.length; i++) {
    final test = suite.tests[i];
    final start = WaypointSymbol.fromString('$sector-${test.start}');
    final end = WaypointSymbol.fromString('$sector-${test.end}');
    final plan = routePlanner.planRoute(
      ship.shipSpec,
      start: start,
      end: end,
    );
    if (plan == null) {
      logger.err('No route found for $start to $end');
      continue;
    }
    final route = <TestRouteAction>[];
    for (final action in plan.actions) {
      if (action.type == RouteActionType.emptyRoute) {
        continue;
      }
      route.add(
        TestRouteAction(
          start: action.startSymbol.sectorLocalName,
          end: action.endSymbol.sectorLocalName,
          action: toActionString(action.type),
        ),
      );
    }
    var failure = false;
    if (!jsonMatches(route, test.expect.route)) {
      logger
        ..err('Route mismatch for ${test.start} to ${test.end}')
        ..err('  Expected: ${test.expect.route}')
        ..err('  Actual: $route');
      failure = true;
    }
    if (plan.fuelUsed != test.expect.fuelUsed) {
      logger
        ..err('Fuel used mismatch for ${test.start} to ${test.end}')
        ..err('  Expected: ${test.expect.fuelUsed}')
        ..err('  Actual: ${plan.fuelUsed}');
      failure = true;
    }
    if (plan.duration.inSeconds != test.expect.time) {
      logger
        ..err('Time mismatch for ${test.start} to ${test.end}')
        ..err('  Expected: ${test.expect.time}')
        ..err('  Actual: ${plan.duration.inSeconds}');
      failure = true;
    }
    if (failure) {
      logger.err('$path.$i: Failed');
    } else {
      logger.info('$path.$i: Passed');
    }
  }
}
