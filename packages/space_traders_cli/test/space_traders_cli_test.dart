import 'package:space_traders_cli/extensions.dart';
import 'package:test/test.dart';

void main() {
  test('parseWaypointString', () {
    final parsed = parseWaypointString('X1-DF55-20250Z');
    expect(parsed.sector, 'X1');
    expect(parsed.system, 'X1-DF55');
    expect(parsed.waypoint, 'X1-DF55-20250Z');
  });
}
