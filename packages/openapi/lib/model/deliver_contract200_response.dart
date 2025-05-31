import 'package:openapi/model/deliver_contract200_response_data.dart';

class DeliverContract200Response {
  DeliverContract200Response({required this.data});

  factory DeliverContract200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return DeliverContract200Response(
      data: DeliverContract200ResponseData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static DeliverContract200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return DeliverContract200Response.fromJson(json);
  }

  DeliverContract200ResponseData data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliverContract200Response && data == other.data;
  }
}
