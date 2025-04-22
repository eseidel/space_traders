// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter, require_trailing_commas, cast_nullable_to_non_nullable, lines_longer_than_80_chars

part of 'get_agent_status_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentStatusResponse _$AgentStatusResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AgentStatusResponse',
      json,
      ($checkedConvert) {
        final val = AgentStatusResponse(
          name: $checkedConvert('name', (v) => v as String),
          faction: $checkedConvert('faction', (v) => v as String),
          numberOfShips: $checkedConvert(
            'number_of_ships',
            (v) => (v as num).toInt(),
          ),
          cash: $checkedConvert('cash', (v) => (v as num).toInt()),
          totalAssets: $checkedConvert(
            'total_assets',
            (v) => (v as num).toInt(),
          ),
          gateOpen: $checkedConvert('gate_open', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {
        'numberOfShips': 'number_of_ships',
        'totalAssets': 'total_assets',
        'gateOpen': 'gate_open',
      },
    );

Map<String, dynamic> _$AgentStatusResponseToJson(
  AgentStatusResponse instance,
) => <String, dynamic>{
  'name': instance.name,
  'faction': instance.faction,
  'number_of_ships': instance.numberOfShips,
  'cash': instance.cash,
  'total_assets': instance.totalAssets,
  'gate_open': instance.gateOpen,
};
