import 'package:openapi/model/create_ship_ship_scan201_response_data.dart';

class CreateShipShipScan201Response {
  CreateShipShipScan201Response({required this.data});

  factory CreateShipShipScan201Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return CreateShipShipScan201Response(
      data: CreateShipShipScan201ResponseData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static CreateShipShipScan201Response? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return CreateShipShipScan201Response.fromJson(json);
  }

  CreateShipShipScan201ResponseData data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }
}
