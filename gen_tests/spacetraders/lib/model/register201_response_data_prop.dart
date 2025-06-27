import 'package:meta/meta.dart';
import 'package:spacetraders/model/agent.dart';
import 'package:spacetraders/model/contract.dart';
import 'package:spacetraders/model/faction.dart';
import 'package:spacetraders/model/ship.dart';
import 'package:spacetraders/model_helpers.dart';

@immutable
class Register201ResponseDataProp {
  const Register201ResponseDataProp({
    required this.token,
    required this.agent,
    required this.faction,
    required this.contract,
    List<Ship>? ships,
  }) : ships = ships ?? const [];

  factory Register201ResponseDataProp.fromJson(Map<String, dynamic> json) {
    return Register201ResponseDataProp(
      token: json['token'] as String,
      agent: Agent.fromJson(json['agent'] as Map<String, dynamic>),
      faction: Faction.fromJson(json['faction'] as Map<String, dynamic>),
      contract: Contract.fromJson(json['contract'] as Map<String, dynamic>),
      ships: (json['ships'] as List)
          .map<Ship>((e) => Ship.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static Register201ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return Register201ResponseDataProp.fromJson(json);
  }

  final String token;
  final Agent agent;
  final Faction faction;
  final Contract contract;
  final List<Ship> ships;

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'agent': agent.toJson(),
      'faction': faction.toJson(),
      'contract': contract.toJson(),
      'ships': ships.map((e) => e.toJson()).toList(),
    };
  }

  @override
  int get hashCode => Object.hashAll([token, agent, faction, contract, ships]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Register201ResponseDataProp &&
        token == other.token &&
        agent == other.agent &&
        faction == other.faction &&
        contract == other.contract &&
        listsEqual(ships, other.ships);
  }
}
