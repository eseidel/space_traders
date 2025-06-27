import 'package:meta/meta.dart';
import 'package:spacetraders/model/agent.dart';
import 'package:spacetraders/model/ship_cargo.dart';
import 'package:spacetraders/model/ship_modification_transaction.dart';
import 'package:spacetraders/model/ship_module.dart';
import 'package:spacetraders/model_helpers.dart';

@immutable
class InstallShipModule201ResponseDataProp {
  const InstallShipModule201ResponseDataProp({
    required this.agent,
    required this.cargo,
    required this.transaction,
    List<ShipModule>? modules,
  }) : modules = modules ?? const [];

  factory InstallShipModule201ResponseDataProp.fromJson(
    Map<String, dynamic> json,
  ) {
    return InstallShipModule201ResponseDataProp(
      agent: Agent.fromJson(json['agent'] as Map<String, dynamic>),
      modules: (json['modules'] as List)
          .map<ShipModule>(
            (e) => ShipModule.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      cargo: ShipCargo.fromJson(json['cargo'] as Map<String, dynamic>),
      transaction: ShipModificationTransaction.fromJson(
        json['transaction'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static InstallShipModule201ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return InstallShipModule201ResponseDataProp.fromJson(json);
  }

  final Agent agent;
  final List<ShipModule> modules;
  final ShipCargo cargo;
  final ShipModificationTransaction transaction;

  Map<String, dynamic> toJson() {
    return {
      'agent': agent.toJson(),
      'modules': modules.map((e) => e.toJson()).toList(),
      'cargo': cargo.toJson(),
      'transaction': transaction.toJson(),
    };
  }

  @override
  int get hashCode => Object.hashAll([agent, modules, cargo, transaction]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InstallShipModule201ResponseDataProp &&
        agent == other.agent &&
        listsEqual(modules, other.modules) &&
        cargo == other.cargo &&
        transaction == other.transaction;
  }
}
