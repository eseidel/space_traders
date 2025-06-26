import 'package:meta/meta.dart';

@immutable
class GetErrorCodes200ResponseErrorCodesPropInner {
  const GetErrorCodes200ResponseErrorCodesPropInner({
    required this.code,
    required this.name,
  });

  factory GetErrorCodes200ResponseErrorCodesPropInner.fromJson(
    Map<String, dynamic> json,
  ) {
    return GetErrorCodes200ResponseErrorCodesPropInner(
      code: (json['code'] as num).toDouble(),
      name: json['name'] as String,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetErrorCodes200ResponseErrorCodesPropInner? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return GetErrorCodes200ResponseErrorCodesPropInner.fromJson(json);
  }

  final double code;
  final String name;

  Map<String, dynamic> toJson() {
    return {'code': code, 'name': name};
  }

  @override
  int get hashCode => Object.hashAll([code, name]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetErrorCodes200ResponseErrorCodesPropInner &&
        code == other.code &&
        name == other.name;
  }
}
