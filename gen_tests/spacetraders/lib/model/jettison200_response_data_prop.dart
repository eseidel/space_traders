import 'package:meta/meta.dart';
import 'package:spacetraders/model/ship_cargo.dart';

@immutable
class Jettison200ResponseDataProp {
  const Jettison200ResponseDataProp({required this.cargo});

  factory Jettison200ResponseDataProp.fromJson(Map<String, dynamic> json) {
    return Jettison200ResponseDataProp(
      cargo: ShipCargo.fromJson(json['cargo'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static Jettison200ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return Jettison200ResponseDataProp.fromJson(json);
  }

  final ShipCargo cargo;

  Map<String, dynamic> toJson() {
    return {'cargo': cargo.toJson()};
  }

  @override
  int get hashCode => cargo.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Jettison200ResponseDataProp && cargo == other.cargo;
  }
}
