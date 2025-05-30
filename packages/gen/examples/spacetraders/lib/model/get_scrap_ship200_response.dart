import 'package:meta/meta.dart';
import 'package:spacetraders/model/get_scrap_ship200_response_data.dart';

@immutable
class GetScrapShip200Response {
  const GetScrapShip200Response({required this.data});

  factory GetScrapShip200Response.fromJson(Map<String, dynamic> json) {
    return GetScrapShip200Response(
      data: GetScrapShip200ResponseData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetScrapShip200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetScrapShip200Response.fromJson(json);
  }

  final GetScrapShip200ResponseData data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetScrapShip200Response && data == other.data;
  }
}
