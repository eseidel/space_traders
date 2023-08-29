import 'package:db/faction.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('Faction round trip', () {
    final faction = Faction(
      symbol: FactionSymbols.AEGIS,
      name: 'Aegis',
      description: 'Aegis is a faction.',
      headquarters: 'Foo',
      traits: [],
      isRecruiting: false,
    );
    final map = factionToColumnMap(faction);
    expect(map, isNotNull);
    final newFaction = factionFromColumnMap(map);
    expect(newFaction.symbol, equals(faction.symbol));
  });
}
