import 'package:meta/meta.dart';
import 'package:spacetraders/model/ship_nav.dart';

@immutable
class DockShip200ResponseDataProp {
  const DockShip200ResponseDataProp({required this.nav});

  factory DockShip200ResponseDataProp.fromJson(Map<String, dynamic> json) {
    return DockShip200ResponseDataProp(
      nav: ShipNav.fromJson(json['nav'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static DockShip200ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return DockShip200ResponseDataProp.fromJson(json);
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
    return other is DockShip200ResponseDataProp && nav == other.nav;
  }
}
