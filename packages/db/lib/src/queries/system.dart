import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Query to return all system records.
Query allSystemRecordsQuery() => const Query('''
      SELECT * FROM system_record_
      ''');

/// Query to return all system waypoints.
Query allSystemWaypointsQuery() => const Query('''
      SELECT * FROM system_waypoint_
      ''');

/// Query to return all system waypoints for a given system.
Query systemWaypointsBySystemQuery(SystemSymbol system) => const Query('''
      SELECT * FROM system_waypoint_
      WHERE system = @system
      ''');

/// Query to return all system waypoints for a given system.
Query systemWaypointsBySystemAndTypeQuery(
  SystemSymbol system,
  WaypointType type,
) => Query(
  '''
      SELECT * FROM system_waypoint_
      WHERE system = @system AND type = @type
      ''',
  parameters: {'system': system.system, 'type': type.value},
);

/// Lookup a SystemWaypoint by symbol.
Query systemWaypointBySymbolQuery(WaypointSymbol symbol) => const Query('''
      SELECT * FROM system_waypoint_  
      WHERE symbol = @symbol
      ''');

/// Create a SystemRecord from a column map.
SystemRecord systemRecordFromColumnMap(Map<String, dynamic> columnMap) {
  return SystemRecord(
    symbol: SystemSymbol.fromString(columnMap['symbol'] as String),
    type: SystemType.fromJson(columnMap['type'] as String)!,
    position: SystemPosition(columnMap['x'] as int, columnMap['y'] as int),
    waypointSymbols:
        (columnMap['waypoint_symbols'] as List)
            .cast<String>()
            .map(WaypointSymbol.fromString)
            .toList(),
  );
}

/// Create a SystemWaypoint from a column map.
SystemWaypoint systemWaypointFromColumnMap(Map<String, dynamic> columnMap) {
  final symbol = WaypointSymbol.fromString(columnMap['symbol'] as String);
  return SystemWaypoint(
    symbol: symbol,
    type: WaypointType.fromJson(columnMap['type'] as String)!,
    position: WaypointPosition(
      columnMap['x'] as int,
      columnMap['y'] as int,
      symbol.system,
    ),
  );
}
