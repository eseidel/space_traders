import 'package:meta/meta.dart';

@immutable
class GetStatus200ResponseHealthProp {
  const GetStatus200ResponseHealthProp({this.lastMarketUpdate});

  factory GetStatus200ResponseHealthProp.fromJson(Map<String, dynamic> json) {
    return GetStatus200ResponseHealthProp(
      lastMarketUpdate: json['lastMarketUpdate'] as String?,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetStatus200ResponseHealthProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return GetStatus200ResponseHealthProp.fromJson(json);
  }

  final String? lastMarketUpdate;

  Map<String, dynamic> toJson() {
    return {'lastMarketUpdate': lastMarketUpdate};
  }

  @override
  int get hashCode => lastMarketUpdate.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetStatus200ResponseHealthProp &&
        lastMarketUpdate == other.lastMarketUpdate;
  }
}
