import 'package:openapi/model/supply_construction201_response_data.dart';

class SupplyConstruction201Response {
  SupplyConstruction201Response({required this.data});

  factory SupplyConstruction201Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return SupplyConstruction201Response(
      data: SupplyConstruction201ResponseData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static SupplyConstruction201Response? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return SupplyConstruction201Response.fromJson(json);
  }

  SupplyConstruction201ResponseData data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }
}
