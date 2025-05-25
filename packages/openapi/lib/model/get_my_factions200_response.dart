import 'package:openapi/model/get_my_factions200_response_data_inner.dart';
import 'package:openapi/model/meta.dart';

class GetMyFactions200Response {
  GetMyFactions200Response({required this.meta, this.data = const []});

  factory GetMyFactions200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetMyFactions200Response(
      data:
          (json['data'] as List<dynamic>)
              .map<GetMyFactions200ResponseDataInner>(
                (e) => GetMyFactions200ResponseDataInner.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
      meta: Meta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetMyFactions200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetMyFactions200Response.fromJson(json);
  }

  List<GetMyFactions200ResponseDataInner> data;
  Meta meta;

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((e) => e.toJson()).toList(),
      'meta': meta.toJson(),
    };
  }
}
