import 'package:meta/meta.dart';
import 'package:spacetraders/model/agent.dart';
import 'package:spacetraders/model/repair_transaction.dart';
import 'package:spacetraders/model/ship.dart';

@immutable
class RepairShip200ResponseDataProp {
  const RepairShip200ResponseDataProp({
    required this.agent,
    required this.ship,
    required this.transaction,
  });

  factory RepairShip200ResponseDataProp.fromJson(Map<String, dynamic> json) {
    return RepairShip200ResponseDataProp(
      agent: Agent.fromJson(json['agent'] as Map<String, dynamic>),
      ship: Ship.fromJson(json['ship'] as Map<String, dynamic>),
      transaction: RepairTransaction.fromJson(
        json['transaction'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static RepairShip200ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return RepairShip200ResponseDataProp.fromJson(json);
  }

  final Agent agent;
  final Ship ship;
  final RepairTransaction transaction;

  Map<String, dynamic> toJson() {
    return {
      'agent': agent.toJson(),
      'ship': ship.toJson(),
      'transaction': transaction.toJson(),
    };
  }

  @override
  int get hashCode => Object.hashAll([agent, ship, transaction]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RepairShip200ResponseDataProp &&
        agent == other.agent &&
        ship == other.ship &&
        transaction == other.transaction;
  }
}
