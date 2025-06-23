import 'package:meta/meta.dart';
import 'package:spacetraders/model_helpers.dart';

@immutable
class GetSupplyChain200ResponseData {
  const GetSupplyChain200ResponseData({required this.exportToImportMap});

  factory GetSupplyChain200ResponseData.fromJson(Map<String, dynamic> json) {
    return GetSupplyChain200ResponseData(
      exportToImportMap: {
        for (final entry
            in (json['exportToImportMap'] as Map<String, dynamic>).entries)
          entry.key: (entry.value as List).cast<String>(),
      },
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

  final Map<String, List<String>> exportToImportMap;

  Map<String, dynamic> toJson() {
    return {
      'exportToImportMap': {
        for (final entry in exportToImportMap.entries) entry.key: entry.value,
      },
    };
  }

  @override
  int get hashCode => exportToImportMap.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetSupplyChain200ResponseData &&
        mapsEqual(exportToImportMap, other.exportToImportMap);
  }
}
