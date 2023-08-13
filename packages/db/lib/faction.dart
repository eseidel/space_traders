import 'package:db/query.dart';
import 'package:postgres/postgres.dart';
import 'package:types/types.dart';

/// Query all factions.
Query allFactionsQuery() => const Query(
      'SELECT * FROM faction_',
      substitutionValues: {},
    );

/// Query a faction by symbol.
Query factionBySymbolQuery(FactionSymbols symbol) => Query(
      'SELECT * FROM faction_ WHERE symbol = @symbol',
      substitutionValues: {
        'symbol': symbol.toString(),
      },
    );

/// insert a faction.
Query insertFactionQuery(Faction faction) => Query(
      'INSERT INTO faction_ (symbol, json) '
      'VALUES (@symbol, @json)',
      substitutionValues: factionToColumnMap(faction),
    );

/// Convert a faction to a column map.
Map<String, dynamic> factionToColumnMap(Faction faction) => {
      'symbol': faction.symbol.toString(),
      'json': faction.toJson(),
    };

/// Convert a result row to a faction.
Faction factionFromResultRow(PostgreSQLResultRow row) {
  final values = row.toColumnMap();
  return Faction.fromJson(values['json'] as Map<String, dynamic>)!;
}
