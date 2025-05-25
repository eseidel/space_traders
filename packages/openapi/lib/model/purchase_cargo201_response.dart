import 'package:openapi/model/purchase_cargo201_response_data.dart';

class PurchaseCargo201Response {
  PurchaseCargo201Response({required this.data});

  factory PurchaseCargo201Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return PurchaseCargo201Response(
      data: PurchaseCargo201ResponseData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static PurchaseCargo201Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return PurchaseCargo201Response.fromJson(json);
  }

  PurchaseCargo201ResponseData data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PurchaseCargo201Response && data == other.data;
  }
}
