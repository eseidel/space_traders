import 'package:openapi/model/ship_mount.dart';
import 'package:openapi/model_helpers.dart';

class GetMounts200Response {
  GetMounts200Response({this.data = const []});

  factory GetMounts200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetMounts200Response(
      data:
          (json['data'] as List)
              .map<ShipMount>(
                (e) => ShipMount.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetMounts200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetMounts200Response.fromJson(json);
  }

  List<ShipMount> data;

  Map<String, dynamic> toJson() {
    return {'data': data.map((e) => e.toJson()).toList()};
  }

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetMounts200Response && listsEqual(data, other.data);
  }
}
