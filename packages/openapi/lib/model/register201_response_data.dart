import 'package:openapi/model/agent.dart';
import 'package:openapi/model/contract.dart';
import 'package:openapi/model/faction.dart';
import 'package:openapi/model/ship.dart';

class Register201ResponseData {
  Register201ResponseData({
    required this.token,
    required this.agent,
    required this.faction,
    required this.contract,
    required this.ships,
  });

  factory Register201ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return Register201ResponseData(
      token: json['token'] as String,
      agent: Agent.fromJson(json['agent'] as Map<String, dynamic>),
      faction: Faction.fromJson(json['faction'] as Map<String, dynamic>),
      contract: Contract.fromJson(json['contract'] as Map<String, dynamic>),
      ships:
          (json['ships'] as List<dynamic>)
              .map<Ship>((e) => Ship.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static Register201ResponseData? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Register201ResponseData.fromJson(json);
  }

  String token;
  Agent agent;
  Faction faction;
  Contract contract;
  List<Ship> ships;

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'agent': agent.toJson(),
      'faction': faction.toJson(),
      'contract': contract.toJson(),
      'ships': ships.map((e) => e.toJson()).toList(),
    };
  }
}
