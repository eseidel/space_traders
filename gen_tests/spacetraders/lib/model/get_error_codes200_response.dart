import 'package:meta/meta.dart';
import 'package:spacetraders/model/get_error_codes200_response_error_codes_prop_inner.dart';
import 'package:spacetraders/model_helpers.dart';

@immutable
class GetErrorCodes200Response {
  const GetErrorCodes200Response({
    List<GetErrorCodes200ResponseErrorCodesPropInner>? errorCodes,
  }) : errorCodes = errorCodes ?? const [];

  factory GetErrorCodes200Response.fromJson(Map<String, dynamic> json) {
    return GetErrorCodes200Response(
      errorCodes: (json['errorCodes'] as List)
          .map<GetErrorCodes200ResponseErrorCodesPropInner>(
            (e) => GetErrorCodes200ResponseErrorCodesPropInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetErrorCodes200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetErrorCodes200Response.fromJson(json);
  }

  final List<GetErrorCodes200ResponseErrorCodesPropInner> errorCodes;

  Map<String, dynamic> toJson() {
    return {'errorCodes': errorCodes.map((e) => e.toJson()).toList()};
  }

  @override
  int get hashCode => errorCodes.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetErrorCodes200Response &&
        listsEqual(errorCodes, other.errorCodes);
  }
}
