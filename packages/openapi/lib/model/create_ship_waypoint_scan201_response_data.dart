import 'package:openapi/api_helpers.dart';
import 'package:openapi/model/cooldown.dart';
import 'package:openapi/model/scanned_waypoint.dart';

class CreateShipWaypointScan201ResponseData {
  CreateShipWaypointScan201ResponseData({
    required this.cooldown,
    this.waypoints = const [],
  });

  factory CreateShipWaypointScan201ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return CreateShipWaypointScan201ResponseData(
      cooldown: Cooldown.fromJson(json['cooldown'] as Map<String, dynamic>),
      waypoints:
          (json['waypoints'] as List<dynamic>)
              .map<ScannedWaypoint>(
                (e) => ScannedWaypoint.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static CreateShipWaypointScan201ResponseData? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return CreateShipWaypointScan201ResponseData.fromJson(json);
  }

  Cooldown cooldown;
  List<ScannedWaypoint> waypoints;

  Map<String, dynamic> toJson() {
    return {
      'cooldown': cooldown.toJson(),
      'waypoints': waypoints.map((e) => e.toJson()).toList(),
    };
  }

  @override
  int get hashCode => Object.hash(cooldown, waypoints);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateShipWaypointScan201ResponseData &&
        cooldown == other.cooldown &&
        listsEqual(waypoints, other.waypoints);
  }
}
