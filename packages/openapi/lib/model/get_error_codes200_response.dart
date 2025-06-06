import 'package:openapi/model/get_error_codes200_response_error_codes_inner.dart';
import 'package:openapi/model_helpers.dart';

class GetErrorCodes200Response {
  GetErrorCodes200Response({this.errorCodes = const []});

  factory GetErrorCodes200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetErrorCodes200Response(
      errorCodes: (json['errorCodes'] as List)
          .map<GetErrorCodes200ResponseErrorCodesInner>(
            (e) => GetErrorCodes200ResponseErrorCodesInner.fromJson(
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

  List<GetErrorCodes200ResponseErrorCodesInner> errorCodes;

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
