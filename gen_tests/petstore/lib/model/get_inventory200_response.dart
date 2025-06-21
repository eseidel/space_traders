import 'package:meta/meta.dart';
import 'package:petstore/model_helpers.dart';

@immutable
class GetInventory200Response {
  const GetInventory200Response({required this.entries});

  factory GetInventory200Response.fromJson(Map<String, dynamic> json) {
    return GetInventory200Response(
      entries: json.map((key, value) => MapEntry(key, value as int)),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetInventory200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetInventory200Response.fromJson(json);
  }

  final Map<String, int> entries;

  int? operator [](String key) => entries[key];

  Map<String, dynamic> toJson() {
    return {...entries.map(MapEntry.new)};
  }

  @override
  int get hashCode => entries.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetInventory200Response &&
        mapsEqual(entries, other.entries);
  }
}
