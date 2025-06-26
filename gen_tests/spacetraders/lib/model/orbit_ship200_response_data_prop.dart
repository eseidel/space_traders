import 'package:meta/meta.dart';
import 'package:spacetraders/model/ship_nav.dart';

@immutable
class OrbitShip200ResponseDataProp {
  const OrbitShip200ResponseDataProp({required this.nav});

  factory OrbitShip200ResponseDataProp.fromJson(Map<String, dynamic> json) {
    return OrbitShip200ResponseDataProp(
      nav: ShipNav.fromJson(json['nav'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static OrbitShip200ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return OrbitShip200ResponseDataProp.fromJson(json);
  }

  final ShipNav nav;

  Map<String, dynamic> toJson() {
    return {'nav': nav.toJson()};
  }

  @override
  int get hashCode => nav.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrbitShip200ResponseDataProp && nav == other.nav;
  }
}
