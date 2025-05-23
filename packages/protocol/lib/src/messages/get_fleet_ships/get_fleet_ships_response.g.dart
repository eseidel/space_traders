// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter, require_trailing_commas, cast_nullable_to_non_nullable, lines_longer_than_80_chars

part of 'get_fleet_ships_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FleetShipsResponse _$FleetShipsResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FleetShipsResponse', json, ($checkedConvert) {
      final val = FleetShipsResponse(
        ships: $checkedConvert(
          'ships',
          (v) => (v as List<dynamic>)
              .map((e) => Ship.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$FleetShipsResponseToJson(FleetShipsResponse instance) =>
    <String, dynamic>{'ships': instance.ships.map((e) => e.toJson()).toList()};
