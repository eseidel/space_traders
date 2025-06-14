import 'package:openapi/model/scrap_transaction.dart';

class GetScrapShip200ResponseData {
  GetScrapShip200ResponseData({required this.transaction});

  factory GetScrapShip200ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetScrapShip200ResponseData(
      transaction: ScrapTransaction.fromJson(
        json['transaction'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetScrapShip200ResponseData? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return GetScrapShip200ResponseData.fromJson(json);
  }

  ScrapTransaction transaction;

  Map<String, dynamic> toJson() {
    return {'transaction': transaction.toJson()};
  }

  @override
  int get hashCode => transaction.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetScrapShip200ResponseData &&
        transaction == other.transaction;
  }
}
