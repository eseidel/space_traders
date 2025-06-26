import 'package:meta/meta.dart';
import 'package:spacetraders/model/ship_cargo.dart';

@immutable
class TransferCargo200ResponseDataProp {
  const TransferCargo200ResponseDataProp({
    required this.cargo,
    required this.targetCargo,
  });

  factory TransferCargo200ResponseDataProp.fromJson(Map<String, dynamic> json) {
    return TransferCargo200ResponseDataProp(
      cargo: ShipCargo.fromJson(json['cargo'] as Map<String, dynamic>),
      targetCargo: ShipCargo.fromJson(
        json['targetCargo'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static TransferCargo200ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return TransferCargo200ResponseDataProp.fromJson(json);
  }

  final ShipCargo cargo;
  final ShipCargo targetCargo;

  Map<String, dynamic> toJson() {
    return {'cargo': cargo.toJson(), 'targetCargo': targetCargo.toJson()};
  }

  @override
  int get hashCode => Object.hashAll([cargo, targetCargo]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransferCargo200ResponseDataProp &&
        cargo == other.cargo &&
        targetCargo == other.targetCargo;
  }
}
