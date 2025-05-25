import 'package:openapi/model/get_supply_chain200_response_data_export_to_import_map.dart';

class GetSupplyChain200ResponseData {
  GetSupplyChain200ResponseData({required this.exportToImportMap});

  factory GetSupplyChain200ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetSupplyChain200ResponseData(
      exportToImportMap:
          GetSupplyChain200ResponseDataExportToImportMap.fromJson(
            json['exportToImportMap'] as Map<String, dynamic>,
          ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetSupplyChain200ResponseData? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return GetSupplyChain200ResponseData.fromJson(json);
  }

  GetSupplyChain200ResponseDataExportToImportMap exportToImportMap;

  Map<String, dynamic> toJson() {
    return {'exportToImportMap': exportToImportMap.toJson()};
  }
}
