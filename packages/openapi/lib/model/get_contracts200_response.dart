import 'package:openapi/model/contract.dart';
import 'package:openapi/model/meta.dart';
import 'package:openapi/model_helpers.dart';

class GetContracts200Response {
  GetContracts200Response({required this.meta, this.data = const []});

  factory GetContracts200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetContracts200Response(
      data: (json['data'] as List)
          .map<Contract>((e) => Contract.fromJson(e as Map<String, dynamic>))
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

  @override
  int get hashCode => Object.hash(data, meta);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetContracts200Response &&
        listsEqual(data, other.data) &&
        meta == other.meta;
  }
}
