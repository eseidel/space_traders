import 'package:meta/meta.dart';
import 'package:spacetraders/model/repair_transaction.dart';

@immutable
class GetRepairShip200ResponseDataProp {
  const GetRepairShip200ResponseDataProp({required this.transaction});

  factory GetRepairShip200ResponseDataProp.fromJson(Map<String, dynamic> json) {
    return GetRepairShip200ResponseDataProp(
      transaction: RepairTransaction.fromJson(
        json['transaction'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetRepairShip200ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return GetRepairShip200ResponseDataProp.fromJson(json);
  }

  final RepairTransaction transaction;

  Map<String, dynamic> toJson() {
    return {'transaction': transaction.toJson()};
  }

  @override
  int get hashCode => transaction.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetRepairShip200ResponseDataProp &&
        transaction == other.transaction;
  }
}
