import 'package:json_annotation/json_annotation.dart';
import 'package:types/types.dart';

part 'get_fleet_ships_response.g.dart';

@JsonSerializable()
class FleetShipsResponse {
  FleetShipsResponse({required this.ships});

  factory FleetShipsResponse.fromJson(Map<String, dynamic> json) =>
      _$FleetShipsResponseFromJson(json);

  final List<Ship> ships;

  Map<String, dynamic> toJson() => _$FleetShipsResponseToJson(this);
}
