import 'package:meta/meta.dart';
import 'package:spacetraders/model/agent.dart';
import 'package:spacetraders/model/market_transaction.dart';
import 'package:spacetraders/model/ship_cargo.dart';

@immutable
class PurchaseCargo201ResponseDataProp {
  const PurchaseCargo201ResponseDataProp({
    required this.cargo,
    required this.transaction,
    required this.agent,
  });

  factory PurchaseCargo201ResponseDataProp.fromJson(Map<String, dynamic> json) {
    return PurchaseCargo201ResponseDataProp(
      cargo: ShipCargo.fromJson(json['cargo'] as Map<String, dynamic>),
      transaction: MarketTransaction.fromJson(
        json['transaction'] as Map<String, dynamic>,
      ),
      agent: Agent.fromJson(json['agent'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static PurchaseCargo201ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return PurchaseCargo201ResponseDataProp.fromJson(json);
  }

  final ShipCargo cargo;
  final MarketTransaction transaction;
  final Agent agent;

  Map<String, dynamic> toJson() {
    return {
      'cargo': cargo.toJson(),
      'transaction': transaction.toJson(),
      'agent': agent.toJson(),
    };
  }

  @override
  int get hashCode => Object.hashAll([cargo, transaction, agent]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PurchaseCargo201ResponseDataProp &&
        cargo == other.cargo &&
        transaction == other.transaction &&
        agent == other.agent;
  }
}
