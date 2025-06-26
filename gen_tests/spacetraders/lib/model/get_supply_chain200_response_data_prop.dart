import 'package:meta/meta.dart';
import 'package:spacetraders/model_helpers.dart';

@immutable
class GetSupplyChain200ResponseDataProp {
  const GetSupplyChain200ResponseDataProp({required this.exportToImportMap});

  factory GetSupplyChain200ResponseDataProp.fromJson(
    Map<String, dynamic> json,
  ) {
    return GetSupplyChain200ResponseDataProp(
      exportToImportMap: {
        for (final entry
            in (json['exportToImportMap'] as Map<String, dynamic>).entries)
          entry.key: (entry.value as List).cast<String>(),
      },
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetSupplyChain200ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return GetSupplyChain200ResponseDataProp.fromJson(json);
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
    return other is GetSupplyChain200ResponseDataProp &&
        mapsEqual(exportToImportMap, other.exportToImportMap);
  }
}
