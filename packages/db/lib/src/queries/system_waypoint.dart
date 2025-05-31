import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Query to return all system waypoints.
Query allSystemWaypointsQuery() => const Query('''
      SELECT * FROM system_waypoint_
      ''');

/// Query to upsert a system waypoint into the database.
Query upsertSystemWaypointQuery(SystemWaypoint waypoint) => Query(
  '''
      INSERT INTO system_waypoint_ (symbol, type, x, y, system)
      VALUES (@symbol, @type, @x, @y, @system)
      ON CONFLICT (symbol) DO UPDATE SET
      type = @type, x = @x, y = @y, system = @system
      ''',
  parameters: {
    'symbol': waypoint.symbol.waypoint,
    'type': waypoint.type.value,
    'x': waypoint.position.x,
    'y': waypoint.position.y,
    'system': waypoint.system.system,
  },
);

/// Query to return all system waypoints for a given system.
Query systemWaypointsBySystemQuery(SystemSymbol system) => Query(
  '''
      SELECT * FROM system_waypoint_
      WHERE system = @system
      ''',
  parameters: {'system': system.system},
);

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
Query systemWaypointBySymbolQuery(WaypointSymbol symbol) => Query(
  '''
      SELECT * FROM system_waypoint_  
      WHERE symbol = @symbol
      ''',
  parameters: {'symbol': symbol.waypoint},
);

/// Create a SystemWaypoint from a column map.
SystemWaypoint systemWaypointFromColumnMap(Map<String, dynamic> columnMap) {
  final symbol = WaypointSymbol.fromString(columnMap['symbol'] as String);
  return SystemWaypoint(
    symbol: symbol,
    type: WaypointType.fromJson(columnMap['type'] as String),
    position: WaypointPosition(
      columnMap['x'] as int,
      columnMap['y'] as int,
      symbol.system,
    ),
  );
}
