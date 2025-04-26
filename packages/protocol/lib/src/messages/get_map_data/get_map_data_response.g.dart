// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter, require_trailing_commas, cast_nullable_to_non_nullable, lines_longer_than_80_chars

part of 'get_map_data_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetMapDataResponse _$GetMapDataResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GetMapDataResponse', json, ($checkedConvert) {
      final val = GetMapDataResponse(
        ships: $checkedConvert(
          'ships',
          (v) =>
              (v as List<dynamic>)
                  .map((e) => Ship.fromJson(e as Map<String, dynamic>))
                  .toList(),
        ),
        systems: $checkedConvert(
          'systems',
          (v) =>
              (v as List<dynamic>)
                  .map((e) => System.fromJson(e as Map<String, dynamic>))
                  .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GetMapDataResponseToJson(GetMapDataResponse instance) =>
    <String, dynamic>{
      'systems': instance.systems.map((e) => e.toJson()).toList(),
      'ships': instance.ships.map((e) => e.toJson()).toList(),
    };
