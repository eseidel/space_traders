import 'package:openapi/model/sell_cargo201_response_data.dart';

class SellCargo201Response {
  SellCargo201Response({required this.data});

  factory SellCargo201Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return SellCargo201Response(
      data: SellCargo201ResponseData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static SellCargo201Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return SellCargo201Response.fromJson(json);
  }

  SellCargo201ResponseData data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SellCargo201Response && data == other.data;
  }
}
