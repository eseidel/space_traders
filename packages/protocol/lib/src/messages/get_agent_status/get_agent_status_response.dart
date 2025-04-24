import 'package:json_annotation/json_annotation.dart';
import 'package:types/types.dart';

part 'get_agent_status_response.g.dart';

@JsonSerializable()
class AgentStatusResponse {
  AgentStatusResponse({
    required this.name,
    required this.faction,
    required this.numberOfShips,
    required this.cash,
    required this.gateOpen,
    required this.gamePhase,
  });

  factory AgentStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$AgentStatusResponseFromJson(json);

  final String name;
  final String faction;
  final int numberOfShips;
  final int cash;
  final bool gateOpen;
  final GamePhase gamePhase;

  Map<String, dynamic> toJson() => _$AgentStatusResponseToJson(this);
}
