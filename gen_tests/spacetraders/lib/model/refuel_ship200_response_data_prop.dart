import 'package:meta/meta.dart';
import 'package:spacetraders/model/agent.dart';
import 'package:spacetraders/model/market_transaction.dart';
import 'package:spacetraders/model/ship_cargo.dart';
import 'package:spacetraders/model/ship_fuel.dart';

@immutable
class RefuelShip200ResponseDataProp {
  const RefuelShip200ResponseDataProp({
    required this.agent,
    required this.fuel,
    required this.transaction,
    this.cargo,
  });

  factory RefuelShip200ResponseDataProp.fromJson(Map<String, dynamic> json) {
    return RefuelShip200ResponseDataProp(
      agent: Agent.fromJson(json['agent'] as Map<String, dynamic>),
      fuel: ShipFuel.fromJson(json['fuel'] as Map<String, dynamic>),
      cargo: ShipCargo.maybeFromJson(json['cargo'] as Map<String, dynamic>?),
      transaction: MarketTransaction.fromJson(
        json['transaction'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static RefuelShip200ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return RefuelShip200ResponseDataProp.fromJson(json);
  }

  final Agent agent;
  final ShipFuel fuel;
  final ShipCargo? cargo;
  final MarketTransaction transaction;

  Map<String, dynamic> toJson() {
    return {
      'agent': agent.toJson(),
      'fuel': fuel.toJson(),
      'cargo': cargo?.toJson(),
      'transaction': transaction.toJson(),
    };
  }

  @override
  int get hashCode => Object.hashAll([agent, fuel, cargo, transaction]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RefuelShip200ResponseDataProp &&
        agent == other.agent &&
        fuel == other.fuel &&
        cargo == other.cargo &&
        transaction == other.transaction;
  }
}
