import 'package:openapi/model/agent.dart';
import 'package:openapi/model/repair_transaction.dart';
import 'package:openapi/model/ship.dart';

class RepairShip200ResponseData {
  RepairShip200ResponseData({
    required this.agent,
    required this.ship,
    required this.transaction,
  });

  factory RepairShip200ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return RepairShip200ResponseData(
      agent: Agent.fromJson(json['agent'] as Map<String, dynamic>),
      ship: Ship.fromJson(json['ship'] as Map<String, dynamic>),
      transaction: RepairTransaction.fromJson(
        json['transaction'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static RepairShip200ResponseData? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return RepairShip200ResponseData.fromJson(json);
  }

  Agent agent;
  Ship ship;
  RepairTransaction transaction;

  Map<String, dynamic> toJson() {
    return {
      'agent': agent.toJson(),
      'ship': ship.toJson(),
      'transaction': transaction.toJson(),
    };
  }

  @override
  int get hashCode => Object.hash(agent, ship, transaction);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RepairShip200ResponseData &&
        agent == other.agent &&
        ship == other.ship &&
        transaction == other.transaction;
  }
}
