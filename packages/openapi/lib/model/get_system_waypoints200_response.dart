import 'package:openapi/model/meta.dart';
import 'package:openapi/model/waypoint.dart';
import 'package:openapi/model_helpers.dart';

class GetSystemWaypoints200Response {
  GetSystemWaypoints200Response({required this.meta, this.data = const []});

  factory GetSystemWaypoints200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetSystemWaypoints200Response(
      data: (json['data'] as List)
          .map<Waypoint>((e) => Waypoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: Meta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetSystemWaypoints200Response? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return GetSystemWaypoints200Response.fromJson(json);
  }

  List<Waypoint> data;
  Meta meta;

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((e) => e.toJson()).toList(),
      'meta': meta.toJson(),
    };
  }

  @override
  int get hashCode => Object.hash(data, meta);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetSystemWaypoints200Response &&
        listsEqual(data, other.data) &&
        meta == other.meta;
  }
}
