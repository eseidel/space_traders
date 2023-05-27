import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/queries.dart';
import 'package:space_traders_cli/route.dart';
import 'package:test/test.dart';

class MockWaypointCache extends Mock implements WaypointCache {}

void main() {
  test('RoutePlanner.findRoute', () async {
    final waypointCache = MockWaypointCache();
    final planner = RoutePlanner(waypointCache);
    final same = await planner.findRoute('a', 'a');
    expect(same, const Route(['a']));
  });
}
