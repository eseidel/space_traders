import 'package:openapi/model/agent.dart';
import 'package:openapi/model/market_transaction.dart';
import 'package:openapi/model/ship_cargo.dart';
import 'package:openapi/model/ship_fuel.dart';

class RefuelShip200ResponseData {
  RefuelShip200ResponseData({
    required this.agent,
    required this.fuel,
    required this.cargo,
    required this.transaction,
  });

  factory RefuelShip200ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return RefuelShip200ResponseData(
      agent: Agent.fromJson(json['agent'] as Map<String, dynamic>),
      fuel: ShipFuel.fromJson(json['fuel'] as Map<String, dynamic>),
      cargo: ShipCargo.fromJson(json['cargo'] as Map<String, dynamic>),
      transaction: MarketTransaction.fromJson(
        json['transaction'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static RefuelShip200ResponseData? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return RefuelShip200ResponseData.fromJson(json);
  }

  Agent agent;
  ShipFuel fuel;
  ShipCargo cargo;
  MarketTransaction transaction;

  Map<String, dynamic> toJson() {
    return {
      'agent': agent.toJson(),
      'fuel': fuel.toJson(),
      'cargo': cargo.toJson(),
      'transaction': transaction.toJson(),
    };
  }
}
