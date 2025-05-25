import 'package:openapi/model/agent.dart';
import 'package:openapi/model/ship_cargo.dart';
import 'package:openapi/model/ship_modification_transaction.dart';
import 'package:openapi/model/ship_module.dart';

class RemoveShipModule201ResponseData {
  RemoveShipModule201ResponseData({
    required this.agent,
    required this.cargo,
    required this.transaction,
    this.modules = const [],
  });

  factory RemoveShipModule201ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return RemoveShipModule201ResponseData(
      agent: Agent.fromJson(json['agent'] as Map<String, dynamic>),
      modules:
          (json['modules'] as List<dynamic>)
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
  static RemoveShipModule201ResponseData? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return RemoveShipModule201ResponseData.fromJson(json);
  }

  Agent agent;
  List<ShipModule> modules;
  ShipCargo cargo;
  ShipModificationTransaction transaction;

  Map<String, dynamic> toJson() {
    return {
      'agent': agent.toJson(),
      'modules': modules.map((e) => e.toJson()).toList(),
      'cargo': cargo.toJson(),
      'transaction': transaction.toJson(),
    };
  }
}
