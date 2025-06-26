import 'package:meta/meta.dart';
import 'package:spacetraders/model/agent.dart';
import 'package:spacetraders/model/ship.dart';
import 'package:spacetraders/model/shipyard_transaction.dart';

@immutable
class PurchaseShip201ResponseDataProp {
  const PurchaseShip201ResponseDataProp({
    required this.ship,
    required this.agent,
    required this.transaction,
  });

  factory PurchaseShip201ResponseDataProp.fromJson(Map<String, dynamic> json) {
    return PurchaseShip201ResponseDataProp(
      ship: Ship.fromJson(json['ship'] as Map<String, dynamic>),
      agent: Agent.fromJson(json['agent'] as Map<String, dynamic>),
      transaction: ShipyardTransaction.fromJson(
        json['transaction'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static PurchaseShip201ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return PurchaseShip201ResponseDataProp.fromJson(json);
  }

  final Ship ship;
  final Agent agent;
  final ShipyardTransaction transaction;

  Map<String, dynamic> toJson() {
    return {
      'ship': ship.toJson(),
      'agent': agent.toJson(),
      'transaction': transaction.toJson(),
    };
  }

  @override
  int get hashCode => Object.hashAll([ship, agent, transaction]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PurchaseShip201ResponseDataProp &&
        ship == other.ship &&
        agent == other.agent &&
        transaction == other.transaction;
  }
}
