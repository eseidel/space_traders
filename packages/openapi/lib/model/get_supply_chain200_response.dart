import 'package:openapi/model/get_supply_chain200_response_data.dart';

class GetSupplyChain200Response {
  GetSupplyChain200Response({required this.data});

  factory GetSupplyChain200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetSupplyChain200Response(
      data: GetSupplyChain200ResponseData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetSupplyChain200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetSupplyChain200Response.fromJson(json);
  }

  GetSupplyChain200ResponseData data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetSupplyChain200Response && data == other.data;
  }
}
