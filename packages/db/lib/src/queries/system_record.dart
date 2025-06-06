import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Query to return all system records.
Query allSystemRecordsQuery() => const Query('''
      SELECT * FROM system_record_
      ''');

/// Query to upsert a system record into the database.
Query upsertSystemRecordQuery(SystemRecord system) => Query(
  '''
      INSERT INTO system_record_ (symbol, type, x, y, waypoint_symbols)
      VALUES (@symbol, @type, @x, @y, @waypoint_symbols)
      ON CONFLICT (symbol) DO UPDATE SET
      type = @type, x = @x, y = @y, waypoint_symbols = @waypoint_symbols
      ''',
  parameters: {
    'symbol': system.symbol.system,
    'type': system.type.value,
    'x': system.position.x,
    'y': system.position.y,
    'waypoint_symbols': system.waypointSymbols.map((e) => e.waypoint).toList(),
  },
);

/// Query to return a system record by symbol.
Query systemRecordBySymbolQuery(SystemSymbol symbol) => Query(
  '''
      SELECT * FROM system_record_
      WHERE symbol = @symbol
      ''',
  parameters: {'symbol': symbol.system},
);

/// Create a SystemRecord from a column map.
SystemRecord systemRecordFromColumnMap(Map<String, dynamic> columnMap) {
  return SystemRecord(
    symbol: SystemSymbol.fromString(columnMap['symbol'] as String),
    type: SystemType.fromJson(columnMap['type'] as String),
    position: SystemPosition(columnMap['x'] as int, columnMap['y'] as int),
    waypointSymbols: (columnMap['waypoint_symbols'] as List)
        .cast<String>()
        .map(WaypointSymbol.fromString)
        .toList(),
  );
}
