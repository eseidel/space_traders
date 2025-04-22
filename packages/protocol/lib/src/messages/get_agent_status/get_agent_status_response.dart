import 'package:json_annotation/json_annotation.dart';

part 'get_agent_status_response.g.dart';

@JsonSerializable()
class AgentStatusResponse {
  AgentStatusResponse({
    required this.name,
    required this.faction,
    required this.numberOfShips,
    required this.cash,
    required this.totalAssets,
    required this.gateOpen,
  });

  factory AgentStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$AgentStatusResponseFromJson(json);
  final String name;
  final String faction;
  final int numberOfShips;
  final int cash;
  final int totalAssets;
  final bool gateOpen;

  Map<String, dynamic> toJson() => _$AgentStatusResponseToJson(this);
}
