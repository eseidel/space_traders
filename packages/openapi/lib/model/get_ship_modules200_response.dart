import 'package:openapi/model/ship_module.dart';
import 'package:openapi/model_helpers.dart';

class GetShipModules200Response {
  GetShipModules200Response({this.data = const []});

  factory GetShipModules200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetShipModules200Response(
      data: (json['data'] as List)
          .map<ShipModule>(
            (e) => ShipModule.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetShipModules200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetShipModules200Response.fromJson(json);
  }

  List<ShipModule> data;

  Map<String, dynamic> toJson() {
    return {'data': data.map((e) => e.toJson()).toList()};
  }

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetShipModules200Response && listsEqual(data, other.data);
  }
}
