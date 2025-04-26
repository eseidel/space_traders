import 'package:json_annotation/json_annotation.dart';
import 'package:types/types.dart';

part 'get_map_data_response.g.dart';

@JsonSerializable()
class GetMapDataResponse {
  GetMapDataResponse({required this.ships, required this.systems});

  factory GetMapDataResponse.fromJson(Map<String, dynamic> json) =>
      _$GetMapDataResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GetMapDataResponseToJson(this);

  final List<System> systems;
  final List<Ship> ships;
}
