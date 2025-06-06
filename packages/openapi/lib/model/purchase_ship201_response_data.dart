import 'package:openapi/model/agent.dart';
import 'package:openapi/model/ship.dart';
import 'package:openapi/model/shipyard_transaction.dart';

class PurchaseShip201ResponseData {
  PurchaseShip201ResponseData({
    required this.ship,
    required this.agent,
    required this.transaction,
  });

  factory PurchaseShip201ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return PurchaseShip201ResponseData(
      ship: Ship.fromJson(json['ship'] as Map<String, dynamic>),
      agent: Agent.fromJson(json['agent'] as Map<String, dynamic>),
      transaction: ShipyardTransaction.fromJson(
        json['transaction'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static PurchaseShip201ResponseData? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return PurchaseShip201ResponseData.fromJson(json);
  }

  Ship ship;
  Agent agent;
  ShipyardTransaction transaction;

  Map<String, dynamic> toJson() {
    return {
      'ship': ship.toJson(),
      'agent': agent.toJson(),
      'transaction': transaction.toJson(),
    };
  }

  @override
  int get hashCode => Object.hash(ship, agent, transaction);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PurchaseShip201ResponseData &&
        ship == other.ship &&
        agent == other.agent &&
        transaction == other.transaction;
  }
}
