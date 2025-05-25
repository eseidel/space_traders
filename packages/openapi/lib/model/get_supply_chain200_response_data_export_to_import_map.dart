import 'package:openapi/api_helpers.dart';

class GetSupplyChain200ResponseDataExportToImportMap {
  GetSupplyChain200ResponseDataExportToImportMap({required this.entries});

  factory GetSupplyChain200ResponseDataExportToImportMap.fromJson(
    dynamic jsonArg,
  ) {
    final json = jsonArg as Map<String, dynamic>;
    return GetSupplyChain200ResponseDataExportToImportMap(
      entries: json.map(
        (key, value) => MapEntry(key, (value as List<dynamic>).cast<String>()),
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetSupplyChain200ResponseDataExportToImportMap? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return GetSupplyChain200ResponseDataExportToImportMap.fromJson(json);
  }

  final Map<String, List<String>> entries;

  List<String>? operator [](String key) => entries[key];

  Map<String, dynamic> toJson() {
    return {...entries.map(MapEntry.new)};
  }

  @override
  int get hashCode => entries.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetSupplyChain200ResponseDataExportToImportMap &&
        mapsEqual(entries, other.entries);
  }
}
