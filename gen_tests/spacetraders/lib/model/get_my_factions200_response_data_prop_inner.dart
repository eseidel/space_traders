import 'package:meta/meta.dart';

@immutable
class GetMyFactions200ResponseDataPropInner {
  const GetMyFactions200ResponseDataPropInner({
    required this.symbol,
    required this.reputation,
  });

  factory GetMyFactions200ResponseDataPropInner.fromJson(
    Map<String, dynamic> json,
  ) {
    return GetMyFactions200ResponseDataPropInner(
      symbol: json['symbol'] as String,
      reputation: json['reputation'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetMyFactions200ResponseDataPropInner? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return GetMyFactions200ResponseDataPropInner.fromJson(json);
  }

  final String symbol;
  final int reputation;

  Map<String, dynamic> toJson() {
    return {'symbol': symbol, 'reputation': reputation};
  }

  @override
  int get hashCode => Object.hashAll([symbol, reputation]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetMyFactions200ResponseDataPropInner &&
        symbol == other.symbol &&
        reputation == other.reputation;
  }
}
