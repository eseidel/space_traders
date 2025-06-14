import 'package:openapi/model/fulfill_contract200_response_data.dart';

class FulfillContract200Response {
  FulfillContract200Response({required this.data});

  factory FulfillContract200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return FulfillContract200Response(
      data: FulfillContract200ResponseData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static FulfillContract200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return FulfillContract200Response.fromJson(json);
  }

  FulfillContract200ResponseData data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FulfillContract200Response && data == other.data;
  }
}
