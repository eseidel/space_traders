import 'package:openapi/model/ship_refine_request_produce.dart';

class ShipRefineRequest {
  ShipRefineRequest({required this.produce});

  factory ShipRefineRequest.fromJson(Map<String, dynamic> json) {
    return ShipRefineRequest(
      produce: ShipRefineRequestProduce.fromJson(json['produce'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipRefineRequest? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ShipRefineRequest.fromJson(json);
  }

  final ShipRefineRequestProduce produce;

  Map<String, dynamic> toJson() {
    return {'produce': produce.toJson()};
  }
}
