import 'package:openapi/model/repair_ship200_response_data.dart';

class RepairShip200Response {
  RepairShip200Response({required this.data});

  factory RepairShip200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return RepairShip200Response(
      data: RepairShip200ResponseData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static RepairShip200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return RepairShip200Response.fromJson(json);
  }

  RepairShip200ResponseData data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }
}
