import 'package:openapi/model/agent.dart';
import 'package:openapi/model/market_transaction.dart';
import 'package:openapi/model/ship_cargo.dart';

class PurchaseCargo201ResponseData {
  PurchaseCargo201ResponseData({
    required this.cargo,
    required this.transaction,
    required this.agent,
  });

  factory PurchaseCargo201ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return PurchaseCargo201ResponseData(
      cargo: ShipCargo.fromJson(json['cargo'] as Map<String, dynamic>),
      transaction: MarketTransaction.fromJson(
        json['transaction'] as Map<String, dynamic>,
      ),
      agent: Agent.fromJson(json['agent'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static PurchaseCargo201ResponseData? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return PurchaseCargo201ResponseData.fromJson(json);
  }

  ShipCargo cargo;
  MarketTransaction transaction;
  Agent agent;

  Map<String, dynamic> toJson() {
    return {
      'cargo': cargo.toJson(),
      'transaction': transaction.toJson(),
      'agent': agent.toJson(),
    };
  }

  @override
  int get hashCode => Object.hash(cargo, transaction, agent);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PurchaseCargo201ResponseData &&
        cargo == other.cargo &&
        transaction == other.transaction &&
        agent == other.agent;
  }
}
