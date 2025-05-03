import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Query all factions.
Query allFactionsQuery() => const Query('SELECT * FROM faction_');

/// Upsert a faction.
Query upsertFactionQuery(Faction faction) => Query(
  'INSERT INTO faction_ (symbol, json) '
  'VALUES (@symbol, @json) '
  'ON CONFLICT (symbol) DO UPDATE SET json = @json',
  parameters: factionToColumnMap(faction),
);

/// Convert a faction to a column map.
Map<String, dynamic> factionToColumnMap(Faction faction) {
  final factionJson = faction.toJson();
  // OpenAPI doesn't call toJson on the symbol, so we need to do it here.
  factionJson['symbol'] = faction.symbol.toJson();
  return {'symbol': faction.symbol.toJson(), 'json': factionJson};
}

/// Convert a result row to a faction.
Faction factionFromColumnMap(Map<String, dynamic> values) {
  return Faction.fromJson(values['json'] as Map<String, dynamic>)!;
}
