import 'package:openapi/model/agent.dart';
import 'package:openapi/model/ship_cargo.dart';
import 'package:openapi/model/ship_modification_transaction.dart';
import 'package:openapi/model/ship_mount.dart';

class RemoveMount201ResponseData {
  RemoveMount201ResponseData({
    required this.agent,
    required this.mounts,
    required this.cargo,
    required this.transaction,
  });

  factory RemoveMount201ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return RemoveMount201ResponseData(
      agent: Agent.fromJson(json['agent'] as Map<String, dynamic>),
      mounts:
          (json['mounts'] as List<dynamic>)
              .map<ShipMount>(
                (e) => ShipMount.fromJson(e as Map<String, dynamic>),
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
  static RemoveMount201ResponseData? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return RemoveMount201ResponseData.fromJson(json);
  }

  Agent agent;
  List<ShipMount> mounts;
  ShipCargo cargo;
  ShipModificationTransaction transaction;

  Map<String, dynamic> toJson() {
    return {
      'agent': agent.toJson(),
      'mounts': mounts.map((e) => e.toJson()).toList(),
      'cargo': cargo.toJson(),
      'transaction': transaction.toJson(),
    };
  }
}
