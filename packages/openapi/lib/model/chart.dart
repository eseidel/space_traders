import 'package:openapi/model/waypoint_symbol.dart';

class Chart {
  Chart({
    required this.waypointSymbol,
    required this.submittedBy,
    required this.submittedOn,
  });

  factory Chart.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return Chart(
      waypointSymbol: WaypointSymbol(json['waypointSymbol'] as String),
      submittedBy: json['submittedBy'] as String,
      submittedOn: DateTime.parse(json['submittedOn'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static Chart? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Chart.fromJson(json);
  }

  WaypointSymbol waypointSymbol;
  String submittedBy;
  DateTime submittedOn;

  Map<String, dynamic> toJson() {
    return {
      'waypointSymbol': waypointSymbol.toJson(),
      'submittedBy': submittedBy,
      'submittedOn': submittedOn.toIso8601String(),
    };
  }

  @override
  int get hashCode => Object.hash(waypointSymbol, submittedBy, submittedOn);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chart &&
        waypointSymbol == other.waypointSymbol &&
        submittedBy == other.submittedBy &&
        submittedOn == other.submittedOn;
  }
}
