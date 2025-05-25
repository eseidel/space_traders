import 'package:openapi/model/contract.dart';
import 'package:openapi/model/meta.dart';

class GetContracts200Response {
  GetContracts200Response({required this.data, required this.meta});

  factory GetContracts200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetContracts200Response(
      data:
          (json['data'] as List<dynamic>)
              .map<Contract>(
                (e) => Contract.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      meta: Meta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetContracts200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetContracts200Response.fromJson(json);
  }

  List<Contract> data;
  Meta meta;

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((e) => e.toJson()).toList(),
      'meta': meta.toJson(),
    };
  }
}
