// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter, require_trailing_commas, cast_nullable_to_non_nullable, lines_longer_than_80_chars

part of 'system_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SystemStats _$SystemStatsFromJson(Map<String, dynamic> json) => $checkedCreate(
  'SystemStats',
  json,
  ($checkedConvert) {
    final val = SystemStats(
      startSystem: $checkedConvert(
        'start_system',
        (v) => SystemSymbol.fromJson(v as String),
      ),
      totalSystems: $checkedConvert('total_systems', (v) => (v as num).toInt()),
      totalWaypoints: $checkedConvert(
        'total_waypoints',
        (v) => (v as num).toInt(),
      ),
      totalJumpgates: $checkedConvert(
        'total_jumpgates',
        (v) => (v as num).toInt(),
      ),
      reachableSystems: $checkedConvert(
        'reachable_systems',
        (v) => (v as num).toInt(),
      ),
      reachableWaypoints: $checkedConvert(
        'reachable_waypoints',
        (v) => (v as num).toInt(),
      ),
      reachableMarkets: $checkedConvert(
        'reachable_markets',
        (v) => (v as num).toInt(),
      ),
      reachableShipyards: $checkedConvert(
        'reachable_shipyards',
        (v) => (v as num).toInt(),
      ),
      reachableAsteroids: $checkedConvert(
        'reachable_asteroids',
        (v) => (v as num).toInt(),
      ),
      reachableJumpGates: $checkedConvert(
        'reachable_jump_gates',
        (v) => (v as num).toInt(),
      ),
      chartedWaypoints: $checkedConvert(
        'charted_waypoints',
        (v) => (v as num).toInt(),
      ),
      chartedAsteroids: $checkedConvert(
        'charted_asteroids',
        (v) => (v as num).toInt(),
      ),
      chartedJumpGates: $checkedConvert(
        'charted_jump_gates',
        (v) => (v as num).toInt(),
      ),
      cachedJumpGates: $checkedConvert(
        'cached_jump_gates',
        (v) => (v as num).toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'startSystem': 'start_system',
    'totalSystems': 'total_systems',
    'totalWaypoints': 'total_waypoints',
    'totalJumpgates': 'total_jumpgates',
    'reachableSystems': 'reachable_systems',
    'reachableWaypoints': 'reachable_waypoints',
    'reachableMarkets': 'reachable_markets',
    'reachableShipyards': 'reachable_shipyards',
    'reachableAsteroids': 'reachable_asteroids',
    'reachableJumpGates': 'reachable_jump_gates',
    'chartedWaypoints': 'charted_waypoints',
    'chartedAsteroids': 'charted_asteroids',
    'chartedJumpGates': 'charted_jump_gates',
    'cachedJumpGates': 'cached_jump_gates',
  },
);

Map<String, dynamic> _$SystemStatsToJson(SystemStats instance) =>
    <String, dynamic>{
      'start_system': instance.startSystem.toJson(),
      'total_systems': instance.totalSystems,
      'total_waypoints': instance.totalWaypoints,
      'total_jumpgates': instance.totalJumpgates,
      'reachable_systems': instance.reachableSystems,
      'reachable_waypoints': instance.reachableWaypoints,
      'reachable_markets': instance.reachableMarkets,
      'reachable_shipyards': instance.reachableShipyards,
      'reachable_asteroids': instance.reachableAsteroids,
      'reachable_jump_gates': instance.reachableJumpGates,
      'charted_waypoints': instance.chartedWaypoints,
      'charted_asteroids': instance.chartedAsteroids,
      'charted_jump_gates': instance.chartedJumpGates,
      'cached_jump_gates': instance.cachedJumpGates,
    };
